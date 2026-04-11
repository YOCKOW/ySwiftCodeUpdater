/* *************************************************************************************************
 SwiftKeywords.swift
   © 2019,2022-2024,2026 YOCKOW.
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

private let _tokenKindsDefRemoteURL = URL(string: "https://raw.githubusercontent.com/swiftlang/swift/main/include/swift/AST/TokenKinds.def")!

private actor _Cache {
  static let shared: _Cache = .init()

  private var _swiftKeywords: _Cached<Set<String>>? = nil
  var swiftKeywords: Set<String> {
    get async throws {
      if let cachedKeywords = _swiftKeywords {
        switch cachedKeywords {
        case .cached(let keywords):
          return keywords
        case .processing:
          return try await withCheckedThrowingContinuation {
            _swiftKeywords!.appendContinuation($0)
          }
        }
      }

      _swiftKeywords = .processing([])
      var defContentString: String!
      do {
        let data = try await JobManager.default.do(
          "Fetch Source for Swift Keywords.",
          jobID: "Swift Keywords"
        ) { ctx in
          return try await ctx.content(of: _tokenKindsDefRemoteURL)
        }
        guard let string = String(data: data, encoding: .utf8) else {
          throw _SwiftKeywordsError.unexpectedRemoteContent
        }
        defContentString = string
      } catch {
        _swiftKeywords!.resumeContinuations(with: .failure(error))
        throw error
      }

      var result = Set<String>()
      for line in StringLines(defContentString) {
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
      _swiftKeywords!.resumeContinuations(with: .success(result))
      _swiftKeywords = .cached(result)
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
