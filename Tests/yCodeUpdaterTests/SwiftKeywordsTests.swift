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
}


