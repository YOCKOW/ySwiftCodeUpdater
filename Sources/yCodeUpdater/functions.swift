/* *************************************************************************************************
 functions.swift
   © 2019-2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import BonaFideCharacterSet
import Foundation
import NetworkGear
import TemporaryFile
import yExtensions
import yNewAPI

private var _indentLevel = 0
private func _indent() -> String { return String(repeating: " ", count: _indentLevel * 4) }

internal func _viewInfo(_ message: String) {
  print("\(_indent())ℹ️ \(message)")
}

public func view(message: String) {
  _viewInfo(message)
}

internal func _do<T>(_ message: String, closure: () throws -> T) -> T {
  print("\(_indent())⏳ \(message)")
  do {
    _indentLevel += 1
    let result = try closure()
    _indentLevel -= 1
    print("\(_indent())✅ Succeeded.")
    return result
  } catch {
    var stderr = FileHandle.standardError
    print("\(_indent())❌ Failed due to an error: \(error)", to: &stderr)
    fatalError(error.localizedDescription)
  }
}

enum _FetchingError: Error {
  case unexpectedStatusCode(HTTPStatusCode)
  case noContent
}

internal func _fetch(_ url: URL) -> Data {
  return _do("Fetch \"\(url.absoluteString)\".") {
    let response = try url.response(to: .init(method: .get, header: [], body: nil))
    guard response.statusCode.rawValue / 100 == 2 else {
      throw _FetchingError.unexpectedStatusCode(response.statusCode)
    }
    guard let content = response.content else { throw _FetchingError.noContent }
    return content
  }
}

/// Returns the content of `url`
public func content(of url: URL) -> Data {
  return _fetch(url)
}

// Attributes of URL...
// TODO: DRY

private var __lastModified: Dictionary<URL, Date?> = [:]
internal func _lastModified(of url: URL) -> Date? {
  if __lastModified[url] == Optional<Optional<Date>>.none {
    let lastModified: Date? = _do("Fetch Last-Modified Date of \(url.absoluteString).") {
      return url.lastModified
    }
    __lastModified[url] = lastModified
  }
  return __lastModified[url].unsafelyUnwrapped
}

private var __eTags: Dictionary<URL, HTTPETag?> = [:]
internal func _eTag(of url: URL) -> HTTPETag? {
  if __eTags[url] == Optional<Optional<HTTPETag>>.none {
    let eTag: HTTPETag? = _do("Fetch ETag of \(url.absoluteString).") {
      return url.eTag
    }
    __eTags[url] = eTag
  }
  return __eTags[url].unsafelyUnwrapped
}

internal func _run(_ executableURL: URL, arguments: [String] = [],
                   currentDirectory: URL? = nil, environment: [String: String]? = nil,
                   standardInput: String? = nil) -> String?
{
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
  return _do(message) {
    let process = Process()
    process.newAPI.executableURL = executableURL
    process.newAPI.currentDirectoryURL = currentDirectory
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
    
    try process.newAPI.run()
    process.waitUntilExit()
    
    guard process.terminationStatus == 0 else {
      _viewInfo("`\(command)` failed.")
      return nil
    }
    return String(data: stdout.fileHandleForReading.availableData, encoding: .utf8)
  }
}

internal func _search(command: String) -> URL? {
  return _do("Search `\(command)`.") {
    let sh = URL(fileURLWithPath: "/bin/sh")
    guard let result = _run(sh, arguments: ["-c", "which \(command)"])?.trimmingUnicodeScalars(in: .whitespacesAndNewlines) else {
      return nil
    }
    if result.isEmpty || !result.hasPrefix("/") { return nil }
    _viewInfo("`\(command)` is at \"\(result)\".")
    return URL(fileURLWithPath: result)
  }
}
