/* *************************************************************************************************
 SwiftKeywordsTests.swift
   © 2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import yCodeUpdater
import Testing

@Suite final class SwiftKeywordsTests {
  @Test func test_keywords() async throws {
    #expect(try await "if".isSwiftKeyword)
    #expect(try await "as".isSwiftKeyword)
    #expect(try await !"hogefugapiyo".isSwiftKeyword)
  }

  @Test func test_identifier() async throws {
    #expect(try await "class".swiftIdentifier == "`class`")
    #expect(try await "my_favourite_things".swiftIdentifier == "my_favourite_things")
  }
}
