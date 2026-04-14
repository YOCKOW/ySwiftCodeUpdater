/* *************************************************************************************************
 JobManager.swift
   © 2019-2020,2023-2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import NetworkGear
import TemporaryFile
import yExtensions

enum _HTTPResponseError: Error {
  case unexpectedStatusCode(HTTPStatusCode)
  case noContent
}

private actor _HTTPResponseCache {
  static let shared: _HTTPResponseCache = .init()
  private init() {}

  private struct _MethodSpecificURL: Hashable, Sendable {
    let url: URL
    let method: HTTPMethod
  }

  private var _responses: KeyedCacheStore<_MethodSpecificURL, SimpleHTTPConnection.Response<Data>> = .init()
  private var _headers: KeyedCacheStore<URL, HTTPHeader> = .init()

  func response(
    forURL url: URL,
    method: HTTPMethod
  ) async throws -> (response: SimpleHTTPConnection.Response<Data>, cacheHit: Bool) {
    let key = _MethodSpecificURL(url: url, method: method)
    var isCached = false
    let response = try await _responses.value(for: key, isCached: &isCached) {
      let request = SimpleHTTPConnection.Request(
        url: url,
        method: method,
        redirectStrategy: .followRedirects
      )
      let response = try await SimpleHTTPConnection(request: request).response()
      guard response.statusCode.isOK else {
        throw _HTTPResponseError.unexpectedStatusCode(response.statusCode)
      }
      return response
    }
    return (response, isCached)
  }

  func content(ofURL url: URL) async throws -> (content: Data, cacheHit: Bool) {
    let responseTuple = try await self.response(forURL: url, method: .get)
    guard let content = responseTuple.response.content else {
      throw _HTTPResponseError.noContent
    }
    return (content, responseTuple.cacheHit)
  }

  private func _header(ofURL url: URL) async throws -> (header: HTTPHeader, cacheHit: Bool) {
    if await _responses.keys.contains(_MethodSpecificURL(url: url, method: .get)) {
      if let responseResult = try? await self.response(forURL: url, method: .get) {
        return (responseResult.response.header, responseResult.cacheHit)
      }
    }

    var isCached = false
    let header = try await _headers.value(for: url, isCached: &isCached) {
      return try await self.response(forURL: url, method: .head).response.header
    }
    return (header, isCached)
  }

  func lastModifiedDate(forURL url: URL) async throws -> (date: Date?, cacheHit: Bool) {
    let headerResult = try await _header(ofURL: url)
    return (headerResult.header[.lastModified].first?.source as? Date, headerResult.cacheHit)
  }

  func eTag(forURL url: URL) async throws -> (eTag: HTTPETag?, cacheHit: Bool) {
    let headerResult = try await _header(ofURL: url)
    return (headerResult.header[.eTag].first?.source as? HTTPETag, headerResult.cacheHit)
  }
}

public actor JobManager {
  public static let `default`: JobManager = .init()

  private var _taskCounters: [String: Int]
  private init() {
    _taskCounters = [:]
  }

  private func _nextTaskNumber(for jobID: String) -> Int {
    let taskNumber = _taskCounters[jobID, default: 0] + 1
    _taskCounters[jobID] = taskNumber
    return taskNumber
  }

  private func _nextContext(of context: Context) -> Context {
    let nextTaskNumber = _nextTaskNumber(for: context.jobID)
    return Context(
      manager: self,
      parent: context,
      jobID: context.jobID,
      taskNumber: nextTaskNumber
    )
  }

  public final class Context: Sendable {
    private unowned let _manager: JobManager
    private let _parent: Context?
    public let jobID: String
    public let taskNumber: Int

    fileprivate init(manager: JobManager, parent: Context?, jobID: String, taskNumber: Int) {
      self._manager = manager
      self._parent = parent
      self.jobID = jobID
      self.taskNumber = taskNumber
    }

    fileprivate var _nestLevel: Int {
      return _parent.map({ $0._nestLevel + 1 }) ?? 0
    }

    fileprivate var _baseIndent: String {
      return String(repeating: "  ", count: _nestLevel)
    }

    fileprivate var _messageIndent: String {
      return String(repeating: "  ", count: _nestLevel + 1)
    }

    fileprivate var _description: String {
      var result = "Task #\(taskNumber) "
      if let parent = _parent {
        result += "(child of #\(parent.taskNumber)) "
      }
      result += "of Job '\(jobID)'"
      return result
    }

    fileprivate func _do<T>(
      message: String?,
      closure: (JobManager.Context) async throws -> T
    ) async rethrows -> T {
      let indent = self._baseIndent
      let contextDescription = self._description

      if let message = message {
        print("\(indent)⏳ Starting \(contextDescription): \(message)")
      }
      do {
        let result = try await closure(self)
        if message != nil {
          print("\(indent)✅ \(contextDescription): Succeeded.")
        }
        return result
      } catch {
        var stderr = FileHandle.standardError
        print("\(indent)❌ \(contextDescription): Failed because of an error \(error)", to: &stderr)
        throw error
      }

    }

    /// Execute the given `closure` under the nested context.
    public func `do`<T>(
      _ message: String,
      closure: (JobManager.Context) async throws -> T
    ) async rethrows -> T {
      let nextContext = await _manager._nextContext(of: self)
      return try await nextContext._do(message: message, closure: closure)
    }



    /// View the given `message` to standard output.
    public func view(message: String) {
      let prefix = "\(_messageIndent)ℹ️ \(_description): "

      let splittedLines = message.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline })
      guard let lastIndex = splittedLines.lastIndex(where: {
        $0.contains(where: { !$0.isWhitespace })
      }) else {
        print("\(prefix)<empty message>")
        return
      }

      let significantLines = splittedLines[...lastIndex]
      switch significantLines.count {
      case 1:
        print("\(prefix)\(significantLines.first!)")
      default:
        var output = "\(prefix)"
        for line in significantLines {
          output += "\n\(_messageIndent)  \(line)"
        }
        print(output)
      }
    }


    /// Returns the content of `url`.
    /// Cached data may be used if available.
    public func content(of url: URL) async throws -> Data {
      return try await self.do("Fetching content of '\(url)'...") { ctx in
        let responseResult = try await _HTTPResponseCache.shared.content(ofURL: url)
        if responseResult.cacheHit {
          ctx.view(message: "Cache hit for \(url.absoluteString)")
        }
        return responseResult.content
      }
    }

    /// Returns the value of `Last-Modified` header field for the given `url`.
    /// Cached value may be used if available.
    public func lastModifiedDate(of url: URL) async throws -> Date? {
      return try await self.do("Fetching Last-Modified date of '\(url)'...") { ctx in
        let dateResult = try await _HTTPResponseCache.shared.lastModifiedDate(forURL: url)
        if dateResult.cacheHit {
          ctx.view(message: "Cache hit for Last-Modified date of \(url.absoluteString)")
        }
        return dateResult.date
      }
    }

    /// Returns the value of `ETag` header field for the given `url`.
    /// Cached value may be used if available.
    public func eTag(of url: URL) async throws -> HTTPETag? {
      return try await self.do("Fetching ETag of '\(url)'...") { ctx in
        let eTagResult = try await _HTTPResponseCache.shared.eTag(forURL: url)
        if eTagResult.cacheHit {
          ctx.view(message: "Cache hit for ETag of \(url.absoluteString)")
        }
        return eTagResult.eTag
      }
    }
  }

  fileprivate func _do<T>(
    message: String?,
    jobID: String,
    closure: @Sendable (JobManager.Context) async throws -> T
  ) async rethrows -> T {
    let taskNumber = _nextTaskNumber(for: jobID)
    let newContext = Context(manager: self, parent: nil, jobID: jobID, taskNumber: taskNumber)
    return try await newContext._do(message: message, closure: closure)
  }


  /// Execute the given `closure` under a new context.
  public func `do`<T>(
    _ message: String,
    jobID: String,
    closure: @Sendable (JobManager.Context) async throws -> T
  ) async rethrows -> T {
    return try await self._do(message: message, jobID: jobID, closure: closure)
  }
}

@available(*, deprecated, message: "Use `JobManager.Context`'s `view(message:)` instead.")
public func view(message: String, jobID: String = UUID().uuidString) async {
  await JobManager.default._do(message: nil, jobID: jobID) { $0.view(message: message) }
}


/// Returns the content of `url`.
/// Cached data may be used if available.
@available(*, deprecated, message: "Use `JobManager.Context`'s `content(of:)` instead.")
public func content(of url: URL, jobID: String? = nil) async throws -> Data {
  return try await JobManager.default._do(
    message: nil,
    jobID: jobID ?? "Fetching \(url.absoluteString)"
  ) { ctx in
    return try await ctx.content(of: url)
  }
}
