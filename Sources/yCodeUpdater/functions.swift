/* *************************************************************************************************
 functions.swift
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

private actor _Cache {
  static let shared: _Cache = .init()

  private enum _Cached<Value> {
    typealias Continuation = CheckedContinuation<Value, any Error>

    case cached(Value)
    case fetching([Continuation])

    mutating func appendContinuation(_ continuation: Continuation) {
      guard case .fetching(var continuations) = self else {
        return
      }
      continuations.append(continuation)
      self = .fetching(continuations)
    }
  }
  private struct _MethodSpecificURL: Hashable, Sendable {
    let url: URL
    let method: HTTPMethod
  }

  private var _responses: [_MethodSpecificURL: _Cached<SimpleHTTPConnection.Response<Data>>] = [:]
  private var _headers: [URL: _Cached<HTTPHeader>] = [:]

  private var _indentLevels: [String: Int] = [:]
  private var _taskCounters: [String: Int] = [:]

  private func _addWaitingContinuation<Key, Value>(
    _ continuation: _Cached<Value>.Continuation,
    to dict: inout [Key: _Cached<Value>],
    for key: Key
  ) where Key: Hashable {
    dict[key, default: .fetching([])].appendContinuation(continuation)
  }

  private func _resumeContinuations<Key, Value>(
    of dict: inout [Key: _Cached<Value>],
    for key: Key,
    with result: Result<Value, any Error>
  ) where Key: Hashable, Value: Sendable {
    guard case .fetching(let continuations) = dict[key] else {
      return
    }
    for continuation in continuations {
      continuation.resume(with: result)
    }
  }

  func response(
    forURL url: URL,
    method: HTTPMethod
  ) async throws -> SimpleHTTPConnection.Response<Data> {
    let key = _MethodSpecificURL(url: url, method: method)
    if let cachedResponse = _responses[key] {
      func __viewMessage() async {
        #if DEBUG
        await _viewInfo(
          "Cache Hit: Method=\(method.rawValue); URL=\(url.absoluteString)",
          jobID: "Cache Check \(url.absoluteString)"
        )
        #endif
      }
      switch cachedResponse {
      case .cached(let response):
        await __viewMessage()
        return response
      case .fetching:
        let response = try await withCheckedThrowingContinuation { continuation in
          _addWaitingContinuation(continuation, to: &self._responses, for: key)
        }
        await __viewMessage()
        return response
      }
    }

    _responses[key] = .fetching([])
    let request = SimpleHTTPConnection.Request(
      url: url,
      method: method,
      redirectStrategy: .followRedirects
    )
    var newResponse: SimpleHTTPConnection.Response<Data>!
    do {
      newResponse = try await SimpleHTTPConnection(request: request).response()
      guard newResponse.statusCode.isOK else {
        throw _HTTPResponseError.unexpectedStatusCode(newResponse.statusCode)
      }
    } catch {
      _resumeContinuations(of: &self._responses, for: key, with: .failure(error))
      throw error
    }

    _resumeContinuations(of: &self._responses, for: key, with: .success(newResponse))
    _responses[key] = .cached(newResponse)
    return newResponse
  }

  func content(ofURL url: URL) async throws -> Data {
    let response = try await self.response(forURL: url, method: .get)
    guard response.statusCode.isOK else {
      throw _HTTPResponseError.unexpectedStatusCode(response.statusCode)
    }
    guard let content = response.content else {
      throw _HTTPResponseError.noContent
    }
    return content
  }

  private func _header(ofURL url: URL) async throws -> HTTPHeader {
    if let cachedHeader = _headers[url] {
      switch cachedHeader {
      case .cached(let header):
        return header
      case .fetching:
        return try await withCheckedThrowingContinuation { continuation in
          _addWaitingContinuation(continuation, to: &self._headers, for: url)
        }
      }
    }

    _headers[url] = .fetching([])

    var someResponse: SimpleHTTPConnection.Response<Data>!
    do {
      if _responses.keys.contains(_MethodSpecificURL(url: url, method: .get)) {
        someResponse = try await self.response(forURL: url, method: .get)
      } else {
        someResponse = try await self.response(forURL: url, method: .head)
      }
    } catch {
      _resumeContinuations(of: &self._headers, for: url, with: .failure(error))
      throw error
    }

    let header = someResponse.header
    _resumeContinuations(of: &self._headers, for: url, with: .success(header))
    _headers[url] = .cached(header)
    return header
  }

  func lastModifiedDate(forURL url: URL) async throws -> Date? {
    let header = try await _header(ofURL: url)
    return header[.lastModified].first?.source as? Date
  }

  func eTag(forURL url: URL) async throws -> HTTPETag? {
    let header = try await _header(ofURL: url)
    return header[.eTag].first?.source as? HTTPETag
  }

  func indentLevel(for id: String) -> Int {
    return _indentLevels[id, default: 0]
  }

  func indent(for id: String) -> String {
    String(repeating: "  ", count: indentLevel(for: id))
  }

  func incrementIndentLevel(for id: String) {
    _indentLevels[id, default: 0] += 1
  }

  func decrementIndentLevel(for id: String) {
    _indentLevels[id] = max(0, _indentLevels[id, default: 0] - 1)
  }

  func taskCount(for id: String) -> Int {
    let count = _taskCounters[id, default: 0] + 1
    _taskCounters[id] = count
    return count
  }
}

internal func _viewInfo(_ message: String, jobID: String) async {
  print("\(await _Cache.shared.indent(for: jobID))ℹ️ \(message)")
}

public func view(message: String, jobID: String = UUID().uuidString) async {
  await _viewInfo(message, jobID: jobID)
}

internal func _do<T>(_ message: String, jobID: String, closure: () async throws -> T) async throws -> T {
  let indent = await _Cache.shared.indent(for: jobID)
  let taskCount = await _Cache.shared.taskCount(for: jobID)
  print("\(indent)⏳ Starting task #\(taskCount) of Job '\(jobID)': \(message)")
  do {
    await _Cache.shared.incrementIndentLevel(for: jobID)
    let result = try await closure()
    await _Cache.shared.decrementIndentLevel(for: jobID)
    print("\(indent)✅ Task #\(taskCount) of Job '\(jobID)': Succeeded.")
    return result
  } catch {
    var stderr = FileHandle.standardError
    print("\(indent)❌ Task #\(taskCount) of Job '\(jobID)': Failed because of an error: \(error)", to: &stderr)
    throw error
  }
}


internal func _fetch(_ url: URL, jobID: String) async throws -> Data {
  return try await _do("Fetching \"\(url.absoluteString)\"...", jobID: jobID) {
    return try await _Cache.shared.content(ofURL: url)
  }
}

/// Returns the content of `url`.
/// Cached data may be used if available.
public func content(of url: URL, jobID: String? = nil) async throws -> Data {
  return try await _fetch(url, jobID: jobID ?? "Fetching \(url.absoluteString)")
}

// Attributes of URL...
// TODO: DRY

internal func _lastModified(of url: URL, jobID: String) async throws -> Date? {
  return try await _do("Fetching Last-Modified Date of \"\(url.absoluteString)\"...", jobID: jobID) {
    return try await _Cache.shared.lastModifiedDate(forURL: url)
  }
}

internal func _eTag(of url: URL, jobID: String) async throws -> HTTPETag? {
  return try await _do("Fetching ETag of \"\(url.absoluteString)\"...", jobID: jobID) {
    return try await _Cache.shared.eTag(forURL: url)
  }
}

internal func _run(
  _ executableURL: URL,
  arguments: [String] = [],
  currentDirectory: URL? = nil,
  environment: [String: String]? = nil,
  standardInput: String? = nil,
  jobID: String
) async throws -> String? {
  var command = executableURL.path
  if !arguments.isEmpty {
    command += " \(arguments.joined(separator: " "))"
  }
  var message = "Run `\(command)`"
  if standardInput?.isEmpty == true {
    message += "."
  } else {
    message += " with some inputs."
  }
  return try await _do(message, jobID: jobID) {
    let process = Process()
    process.executableURL = executableURL
    process.currentDirectoryURL = currentDirectory
    process.arguments = arguments
    if let env = environment {
      process.environment = env
    }
    if let stdinData = standardInput?.data(using: .utf8) {
      let stdin = try TemporaryFile(contents: stdinData)
      process[.standardInput] = stdin
    }
    
    let stdout = Pipe()
    process.standardOutput = stdout
    
    try process.run()
    process.waitUntilExit()
    
    guard process.terminationStatus == 0 else {
      await _viewInfo("`\(command)` failed.", jobID: jobID)
      return nil
    }
    return String(data: stdout.fileHandleForReading.availableData, encoding: .utf8)
  }
}

internal func _search(command: String, jobID: String) async throws -> URL? {
  return try await _do("Search `\(command)`.", jobID: jobID) { () async throws -> URL? in
    let sh = URL(fileURLWithPath: "/bin/sh")
    guard let result = try await _run(
      sh,
      arguments: ["-c", "which \(command)"],
      jobID: jobID
    )?.trimmingUnicodeScalars(where: {
        $0.latestProperties.isWhitespace || $0.latestProperties.isNewline
    }) else {
      return nil
    }
    if result.isEmpty || !result.hasPrefix("/") { return nil }
    await _viewInfo("`\(command)` is at \"\(result)\".", jobID: jobID)
    return URL(fileURLWithPath: result)
  }
}
