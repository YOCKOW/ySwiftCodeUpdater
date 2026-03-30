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

  private var _responses: [URL: [HTTPMethod: SimpleHTTPConnection.Response<Data>]] = [:]
  private var _lastModifiedDates: [URL: Date?] = [:]
  private var _eTags: [URL: HTTPETag?] = [:]

  private var _indentLevels: [String: Int] = [:]
  private var _taskCounters: [String: Int] = [:]

  func response(
    forURL url: URL,
    method: HTTPMethod
  ) async throws -> SimpleHTTPConnection.Response<Data> {
    if let cachedResponse = _responses[url]?[method] {
      return cachedResponse
    }

    let request = SimpleHTTPConnection.Request(
      url: url,
      method: method,
      redirectStrategy: .followRedirects
    )
    let newResponse = try await SimpleHTTPConnection(request: request).response()
    guard newResponse.statusCode.isOK else {
      throw _HTTPResponseError.unexpectedStatusCode(newResponse.statusCode)
    }
    _responses[url, default: [:]][method] = newResponse
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

  func lastModifiedDate(forURL url: URL) async throws -> Date? {
    if let cachedDate = _lastModifiedDates[url] {
      return cachedDate
    }

    func __cacheLastModifiedDateFromResponse<T>(_ response: SimpleHTTPConnection.Response<T>) -> Date? {
      let theDate = response.header[.lastModified].first?.source as? Date
      _lastModifiedDates[url] = theDate
      return theDate
    }

    if let cachedResponse = _responses[url]?[.head] ?? _responses[url]?[.get] {
      return __cacheLastModifiedDateFromResponse(cachedResponse)
    }

    let headResponse = try await self.response(forURL: url, method: .head)
    return __cacheLastModifiedDateFromResponse(headResponse)
  }

  func eTag(forURL url: URL) async throws -> HTTPETag? {
    if let cachedETag = _eTags[url] {
      return cachedETag
    }

    func __cacheETagFromResponse<T>(_ response: SimpleHTTPConnection.Response<T>) -> HTTPETag? {
      let theTag = response.header[.eTag].first?.source as? HTTPETag
      _eTags[url] = theTag
      return theTag
    }

    if let cachedResponse = _responses[url]?[.head] ?? _responses[url]?[.get] {
      return __cacheETagFromResponse(cachedResponse)
    }

    let headResponse = try await self.response(forURL: url, method: .head)
    return __cacheETagFromResponse(headResponse)
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

/// Returns the content of `url`
public func content(of url: URL, jobID: String? = nil) async throws -> Data {
  return try await _fetch(url, jobID: jobID ?? "to fetch \(url.absoluteString)")
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
