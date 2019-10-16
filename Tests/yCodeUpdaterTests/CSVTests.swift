/* *************************************************************************************************
 CSVTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import CSV
import XCTest
@testable import yCodeUpdater

final class CSVTests: XCTestCase {
  func test_rows() throws {
    func _url(for csvString: String) -> URL {
      let encoded = csvString.addingPercentEncoding(withAllowedUnicodeScalars: .urlPathAllowed)!
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

