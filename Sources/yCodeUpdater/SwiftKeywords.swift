/* *************************************************************************************************
 SwiftKeywords.swift
   © 2019,2022-2024,2026 YOCKOW.
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

private actor _Cache {
  static let shared: _Cache = .init()

  var _tokenKindsDefContent: String? = nil
  var tokenKindsDefContent: String {
    get async throws {
      if let content = self._tokenKindsDefContent {
        return content
      }

      guard let string = String(
        data: try await _fetch(_tokenKindsDefRemoteURL, jobID: "SwiftKeywords"),
        encoding: .utf8
      ) else {
        throw _SwiftKeywordsError.unexpectedRemoteContent
      }
      _tokenKindsDefContent = string
      return string
    }
  }

  var _swiftKeywords: Set<String>?
  var swiftKeywords: Set<String> {
    get async throws {
      if let keywords = self._swiftKeywords {
        return keywords
      }

      var result = Set<String>()
      for line in StringLines(try await tokenKindsDefContent) {
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
    }
  }
}

extension String {
  public var isSwiftKeyword: Bool {
    get async throws {
      return try await _Cache.shared.swiftKeywords.contains(self)
    }
  }
  
  public var swiftIdentifier: String {
    get async throws {
      if try await self.isSwiftKeyword {
        return "`\(self)`"
      }
      return self
    }
  }
}
