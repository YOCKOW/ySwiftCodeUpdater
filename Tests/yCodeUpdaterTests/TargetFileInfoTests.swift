/* *************************************************************************************************
 TargetFileInfoTests.swift
   © 2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
@testable import yCodeUpdater
import NetworkGear
import Testing

@Suite final class TargetFileInfoTests {
  @available(macOS 10.12, *)
  @Test func test_info() throws {
    let sampleFilePath = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/Sample.swift")
    let info = try _TargetFileInfo(fileAt: sampleFilePath)

    let firstURL = URL(string: "http://example.com/some_data.txt")!
    #expect(info.lastModifiedDate(for: firstURL) == ISO8601DateFormatter().date(from: "2001-01-01T00:00:00Z"))
    #expect(info.eTag(for: firstURL) == nil)

    let secondURL = URL(string: "http://example.com/another_data.txt")!
    #expect(info.lastModifiedDate(for: secondURL) == nil)
    #expect(info.eTag(for: secondURL) == HTTPETag.strong("AnotherDataTxt"))
  }
}
