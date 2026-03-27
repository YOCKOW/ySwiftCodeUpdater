/* *************************************************************************************************
 SwiftKeywordsTests.swift
   © 2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import yCodeUpdater
import Testing

@Suite final class SwiftKeywordsTests {
  @Test func test_keywords() {
    #expect("if".isSwiftKeyword)
    #expect("as".isSwiftKeyword)
    #expect(!"hogefugapiyo".isSwiftKeyword)
  }

  @Test func test_identifier() {
    #expect("class".swiftIdentifier == "`class`")
    #expect("my_favourite_things".swiftIdentifier == "my_favourite_things")
  }
}
