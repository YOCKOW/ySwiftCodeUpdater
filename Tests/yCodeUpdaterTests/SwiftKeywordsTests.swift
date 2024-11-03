/* *************************************************************************************************
 SwiftKeywordsTests.swift
   © 2019,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import yCodeUpdater

#if swift(>=6) && canImport(Testing)
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
#else
import XCTest

final class SwiftKeywordsTests: XCTestCase {
  func test_keywords() {
    XCTAssertTrue("if".isSwiftKeyword)
    XCTAssertTrue("as".isSwiftKeyword)
    XCTAssertFalse("hogefugapiyo".isSwiftKeyword)
  }
  
  func test_identifier() {
    XCTAssertEqual("class".swiftIdentifier, "`class`")
    XCTAssertEqual("my_favourite_things".swiftIdentifier, "my_favourite_things")
  }
}
#endif
