/* *************************************************************************************************
 functions.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
import HTTP
import NetworkGear

private var _indentLevel = 0
private func _indent() -> String { return String(repeating: " ", count: _indentLevel * 2) }

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
    fatalError("\(_indent())❌ Failed due to an error: \(error)")
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
