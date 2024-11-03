/* *************************************************************************************************
 SwiftKeywords.swift
   © 2019,2022-2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import NetworkGear
import StringComposition
import TemporaryFile
import yExtensions


private enum _SwiftKeywordsError: Error {
  case unexpectedRemoteContent
}

private let _tokenKindsDefRemoteURL = URL(string: "https://raw.githubusercontent.com/swiftlang/swift/main/include/swift/AST/TokenKinds.def")!

private func _tokenKindsDefContent() -> String {
  struct __Cache {
    private static let _queue: DispatchQueue = .init(
      label: "jp.YOCKOW.ySwiftCodeUpdater.SwiftKeywords.__Cache",
      attributes: .concurrent
    )
    nonisolated(unsafe) private static var _cache: String? = nil
    static var cache: String {
      return _queue.sync(flags: .barrier) {
        guard let cache = _cache else {
          guard let string = String(data: _fetch(_tokenKindsDefRemoteURL), encoding: .utf8) else {
            fatalError("Unexpected content at \(_tokenKindsDefRemoteURL.absoluteString).")
          }
          _cache = string
          return string
        }
        return cache
      }
    }
  }
  return __Cache.cache
}

private let _swiftKeywords: Set<String> = ({ () -> Set<String> in
  var result = Set<String>()
  let tokenKindsDef = _tokenKindsDefContent()
  for line in StringLines(tokenKindsDef) {
    let payload = line.payload
    guard (
      payload.hasPrefix("DECL_KEYWORD") ||
      payload.hasPrefix("STMT_KEYWORD") ||
      payload.hasPrefix("EXPR_KEYWORD")
    ) else {
      continue
    }
    guard let lParenIndex = payload.firstIndex(of: "("),
          let rParenIndex = payload.firstIndex(of: ")"),
          lParenIndex < rParenIndex
    else {
      continue
    }
    result.insert(String(payload[payload.index(after: lParenIndex)..<rParenIndex]))
  }
  return result
})()

extension String {
  public var isSwiftKeyword: Bool {
    return _swiftKeywords.contains(self)
  }
  
  public var swiftIdentifier: String {
    if self.isSwiftKeyword {
      return "`\(self)`"
    }
    return self
  }
}
