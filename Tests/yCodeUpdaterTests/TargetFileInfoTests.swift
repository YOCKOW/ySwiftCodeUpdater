/* *************************************************************************************************
 TargetFileInfoTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import XCTest
@testable import yCodeUpdater
import NetworkGear

final class TargetFileInfoTests: XCTestCase {
  @available(macOS 10.12, *)
  func test_info() throws {
    let sampleFilePath = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/Sample.swift")
    let info = try _TargetFileInfo(fileAt: sampleFilePath)
    
    let firstURL = URL(string: "http://example.com/some_data.txt")!
    XCTAssertEqual(info.lastModifiedDate(for: firstURL),
                   ISO8601DateFormatter().date(from: "2001-01-01T00:00:00Z"))
    XCTAssertNil(info.eTag(for: firstURL))
    
    let secondURL = URL(string: "http://example.com/another_data.txt")!
    XCTAssertNil(info.lastModifiedDate(for: secondURL))
    XCTAssertEqual(info.eTag(for: secondURL), HTTPETag.strong("AnotherDataTxt"))
  }
}



