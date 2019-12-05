/* *************************************************************************************************
 SwiftKeywordsTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import yCodeUpdater

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


