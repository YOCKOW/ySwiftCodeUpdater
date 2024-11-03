/* *************************************************************************************************
 CodeUpdaterTests.swift
  © 2019,2024 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
************************************************************************************************ */


@testable import yCodeUpdater
import Foundation
import TemporaryFile
import yExtensions

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class CodeUpdaterTests {
  @Test func test_update() throws {
    class Delegate: CodeUpdaterDelegate {
      typealias IntermediateDataType = Data
      var identifier: String { return "test" }
      var sourceURLs: Array<URL> {
        return [
          URL(string: "http://Bot.YOCKOW.jp/-/lastModified/20191128000000")!,
          URL(string: "https://bot.yockow.jp/-/eTag/strong:test")!,
        ]
      }
      let destinationURL: URL = URL.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-test.swift")
      func convert<S>(_: S) throws -> Data where S : Sequence, S.Element == IntermediateDataContainer<IntermediateDataType> {
        return """
          struct MyTest {
            var number: Int = 0
          }

          """.data(using: .utf8)!
      }
    }

    let delegate = Delegate()
    let updater = CodeUpdater(delegate: delegate)
    updater.forcesToUpdate = true
    updater.update()

    let expectedFilePath = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/Expected.swift")
    let actual = FileManager.default.contents(atPath: delegate.destinationURL.path).flatMap({ String(data: $0, encoding: .utf8) })
    let expected = FileManager.default.contents(atPath: expectedFilePath.path).flatMap({ String(data: $0, encoding: .utf8) })
    #expect(actual != nil)

    // Check difference
    func _splitLines(_ maybeString: String?, sourceLocation: SourceLocation = #_sourceLocation) throws -> Array<Substring> {
      return try #require(maybeString, sourceLocation: sourceLocation).split(
        omittingEmptySubsequences: false,
        whereSeparator: { $0.isNewline }
      )
    }
    func _diff<S>(_ strings1: Array<S>, _ strings2: Array<S>) -> [(Int, (S, S))] where S: StringProtocol {
      let nn = max(strings1.count, strings2.count)
      return zip(0..<nn, zip(strings1, strings2)).filter({ $1.0 != $1.1 })
    }
    func _diffString<S>(_ diffs: [(Int, (S, S))]) -> String where S: StringProtocol {
      if diffs.isEmpty { return "No difference." }
      var result = ""
      for item in diffs {
        result += "#\(item.0 + 1): \"\(item.1.0)\" IS NOT \"\(item.1.1)\"\n"
      }
      return result
    }
    let difference = "Difference:\n" + _diffString(
      _diff(
        try _splitLines(actual),
        try _splitLines(expected)
      )
    )
    #expect(actual == expected, Comment(rawValue: difference))
  }
}
#else
import XCTest

final class CodeUpdaterTests: XCTestCase {
  func test_update() throws {
    class Delegate: CodeUpdaterDelegate {
      typealias IntermediateDataType = Data
      var identifier: String { return "test" }
      var sourceURLs: Array<URL> {
        return [
          URL(string: "http://Bot.YOCKOW.jp/-/lastModified/20191128000000")!,
          URL(string: "https://bot.yockow.jp/-/eTag/strong:test")!,
        ]
      }
      let destinationURL: URL = URL.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-test.swift")
      func convert<S>(_: S) throws -> Data where S : Sequence, S.Element == IntermediateDataContainer<IntermediateDataType> {
        return """
          struct MyTest {
            var number: Int = 0
          }

          """.data(using: .utf8)!
      }
    }
    
    let delegate = Delegate()
    let updater = CodeUpdater(delegate: delegate)
    updater.forcesToUpdate = true
    updater.update()
    
    let expectedFilePath = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/Expected.swift")
    let actual = FileManager.default.contents(atPath: delegate.destinationURL.path).flatMap({ String(data: $0, encoding: .utf8) })
    let expected = FileManager.default.contents(atPath: expectedFilePath.path).flatMap({ String(data: $0, encoding: .utf8) })
    XCTAssertNotNil(actual)
    
    // Check difference
    func _splitLines(_ maybeString: String?, file: StaticString = #filePath, line: UInt = #line) throws -> Array<Substring> {
      return try XCTUnwrap(maybeString, file: file, line: line).split(
        omittingEmptySubsequences: false,
        whereSeparator: { $0.isNewline }
      )
    }
    func _diff<S>(_ strings1: Array<S>, _ strings2: Array<S>) -> [(Int, (S, S))] where S: StringProtocol {
      let nn = max(strings1.count, strings2.count)
      return zip(0..<nn, zip(strings1, strings2)).filter({ $1.0 != $1.1 })
    }
    func _diffString<S>(_ diffs: [(Int, (S, S))]) -> String where S: StringProtocol {
      if diffs.isEmpty { return "No difference." }
      var result = ""
      for item in diffs {
        result += "#\(item.0 + 1): \"\(item.1.0)\" IS NOT \"\(item.1.1)\"\n"
      }
      return result
    }
    let difference = "Difference:\n" + _diffString(
      _diff(
        try _splitLines(actual),
        try _splitLines(expected)
      )
    )
    XCTAssertEqual(actual, expected, difference)
  }
}
#endif
