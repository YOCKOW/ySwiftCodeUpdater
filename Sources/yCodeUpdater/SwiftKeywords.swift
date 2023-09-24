/* *************************************************************************************************
 SwiftKeywords.swift
   © 2019,2022,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
import NetworkGear
import StringComposition
import TemporaryFile
import yExtensions


private enum _SwiftKeywordsError: Error {
  case unexpectedRemoteContent
}

private let _tokenKindsDefRemoteURL = URL(string: "https://raw.githubusercontent.com/apple/swift/main/include/swift/AST/TokenKinds.def")!

private func _tokenKindsDefContent() -> String {
  struct __Cache { static var cache: String? = nil }
  guard let cache = __Cache.cache else {
    guard let string = String(data: _fetch(_tokenKindsDefRemoteURL), encoding: .utf8) else {
      fatalError("Unexpected content at \(_tokenKindsDefRemoteURL.absoluteString).")
    }
    __Cache.cache = string
    return string
  }
  return cache
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
