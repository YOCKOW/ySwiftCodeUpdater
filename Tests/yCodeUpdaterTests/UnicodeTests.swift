/* *************************************************************************************************
 UnicodeTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import yCodeUpdater

final class UnicodeTests: XCTestCase {
  func test_license() {
    let license = unicodeLicense()
    let firstLine = license.split(whereSeparator: { $0.isNewline }).first
    XCTAssertEqual(firstLine, "UNICODE, INC. LICENSE AGREEMENT - DATA FILES AND SOFTWARE")
  }
}


