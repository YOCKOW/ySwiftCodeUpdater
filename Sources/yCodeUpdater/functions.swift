/* *************************************************************************************************
 functions.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import BonaFideCharacterSet
import Foundation
import HTTP
import NetworkGear
import TemporaryFile
import yExtensions

private var _indentLevel = 0
private func _indent() -> String { return String(repeating: " ", count: _indentLevel * 4) }

internal func _viewInfo(_ message: String) {
  print("\(_indent())ℹ️ \(message)")
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
  case unexpectedStatusCode(HTTP.StatusCode)
  case noContent
  case noETag
  case noLastModifiedDate
}

internal func _fetch(_ url: URL) -> Data {
  return _do("Fetching \(url.absoluteString)") {
    let response = try url.response(to: .init(method: .get, header: [], body: nil))
    guard response.statusCode.rawValue / 100 == 2 else {
      throw _FetchingError.unexpectedStatusCode(response.statusCode)
    }
    guard let content = response.content else { throw _FetchingError.noContent }
    return content
  }
}

internal func _fetch(_ url: URL, ifModifiedSince date: Date) -> Data? {
  let modified = _do("Checking whether the content at \(url.absoluteString) is modified since \(date.description).") { () throws -> Bool in
    guard let lastModified = url.lastModified else { throw _FetchingError.noLastModifiedDate }
    if lastModified <= date {
      _viewInfo("Up-to-date.")
      return false
    } else {
      return true
    }
  }
  
  if !modified { return nil }
  return _fetch(url)
}

internal func _fetch(_ url: URL, ifNoneMatch list: ETagList) -> Data? {
  let modified = _do("Checking ETag of \(url.absoluteString)") { () throws -> Bool in
    guard let eTag = url.eTag else { throw _FetchingError.noETag }
    if list.contains(eTag, weakComparison: true) {
      _viewInfo("Up-to-date.")
      return false
    } else {
      return true
    }
  }
  
  if !modified { return nil }
  return _fetch(url)
}

internal func _run(_ executableURL: URL, arguments: [String] = [],
                   currentDirectory: URL? = nil, environment: [String: String]? = nil,
                   standardInput: String? = nil) -> String?
{
  var command = executableURL.path
  if !arguments.isEmpty {
    command += " " + arguments.joined(separator: " ")
  }
  return _do("Run `\(command)`") {
    let process = Process()
    if #available(macOS 10.13, *) {
      process.executableURL = executableURL
      if let cd = currentDirectory {
        process.currentDirectoryURL = cd
      }
    } else {
      process.launchPath = executableURL.path
      if let cdPath = currentDirectory?.path {
        process.currentDirectoryPath = cdPath
      }
    }
    process.arguments = arguments
    if let env = environment {
      process.environment = env
    }
    if let stdin = standardInput?.data(using: .utf8) {
      process.standardInput = TemporaryFile(contents: stdin)
    }
    
    let stdout = Pipe()
    process.standardOutput = stdout
    
    if #available(macOS 10.13, *) {
      try process.run()
    } else {
      process.launch()
    }
    process.waitUntilExit()
    
    guard process.terminationStatus == 0 else {
      _viewInfo("`\(command)` failed.")
      return nil
    }
    return String(data: stdout.fileHandleForReading.availableData, encoding: .utf8)
  }
}

internal func _search(command: String) -> URL? {
  return _do("Searching `\(command)`") {
    let sh = URL(fileURLWithPath: "/bin/sh")
    guard let result = _run(sh, arguments: ["-c", "which \(command)"])?.trimmingUnicodeScalars(in: .whitespacesAndNewlines) else {
      return nil
    }
    if result.isEmpty || !result.hasPrefix("/") { return nil }
    _viewInfo("`\(command)` is at \"\(result)\".")
    return URL(fileURLWithPath: result)
  }
}
