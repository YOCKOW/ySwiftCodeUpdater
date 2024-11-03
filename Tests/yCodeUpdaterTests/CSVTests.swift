/* *************************************************************************************************
 CSVTests.swift
   © 2019,2023-2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import CSV
import Foundation
@testable import yCodeUpdater

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class CSVTests {
  @Test func test_rows() throws {
    func _url(for csvString: String) throws -> URL {
      let encoded = try #require(csvString.addingPercentEncoding(whereAllowedUnicodeScalars: { $0.isAllowedInURLPath }))
      return URL(string: "https://Bot.YOCKOW.jp/-/stringContent/\(encoded)")!
    }

    let noHeader = "foo,bar,baz\nhoge,fuga,piyo"
    var reader = try CSVReader(url: _url(for: noHeader))
    var rows = reader.rows()
    #expect(rows.count == 2)
    #expect(rows[0].fields == ["foo", "bar", "baz"])
    #expect(rows[1].fields == ["hoge", "fuga", "piyo"])

    let withHeader = "First Name,Last Name\nJohn,Doe\n権兵衛,名無"
    reader = try CSVReader(url: _url(for: withHeader), hasHeaderRow: true)
    rows = reader.rows()
    #expect(rows.count == 2)
    #expect(rows[0]["Last Name"] == "Doe")
    #expect(rows[1]["First Name"] == "権兵衛")
  }
}
#else
import XCTest

final class CSVTests: XCTestCase {
  func test_rows() throws {
    func _url(for csvString: String) throws -> URL {
      let encoded = try XCTUnwrap(csvString.addingPercentEncoding(whereAllowedUnicodeScalars: { $0.isAllowedInURLPath }))
      return URL(string: "https://Bot.YOCKOW.jp/-/stringContent/\(encoded)")!
    }
    
    let noHeader = "foo,bar,baz\nhoge,fuga,piyo"
    var reader = try CSVReader(url: _url(for: noHeader))
    var rows = reader.rows()
    XCTAssertEqual(rows.count, 2)
    XCTAssertEqual(rows[0].fields, ["foo", "bar", "baz"])
    XCTAssertEqual(rows[1].fields, ["hoge", "fuga", "piyo"])
    
    let withHeader = "First Name,Last Name\nJohn,Doe\n権兵衛,名無"
    reader = try CSVReader(url: _url(for: withHeader), hasHeaderRow: true)
    rows = reader.rows()
    XCTAssertEqual(rows.count, 2)
    XCTAssertEqual(rows[0]["Last Name"], "Doe")
    XCTAssertEqual(rows[1]["First Name"], "権兵衛")
  }
}
#endif
