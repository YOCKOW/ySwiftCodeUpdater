/* *************************************************************************************************
 UnicodeDataTests.swift
   © 2019-2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import yCodeUpdater

import TemporaryFile
import Ranges

final class UnicodeDataTests: XCTestCase {
  func test_license() throws {
    let license = unicodeLicense()
    let firstLine = try XCTUnwrap(license.split(whereSeparator: { $0.isNewline }).first)
    XCTAssertTrue(firstLine.contains("UNICODE LICENSE"))
  }
  
  func test_data() throws {
    let string = """
    # Bidi_Class=Left_To_Right

    0041..005A    ; L # L&  [26] LATIN CAPITAL LETTER A..LATIN CAPITAL LETTER Z
    0061..007A    ; L # L&  [26] LATIN SMALL LETTER A..LATIN SMALL LETTER Z
    00AA          ; L # Lo       FEMININE ORDINAL INDICATOR
    """
    
    var data = UnicodeData(string)
    guard data.rows.count == 4 else { XCTFail(); return }
    XCTAssertNil(data.rows[0].payload)
    XCTAssertEqual(data.rows[0].comment, "Bidi_Class=Left_To_Right")
    XCTAssertEqual(data.rows[1].payload?.range, 0x0041...0x005A)
    XCTAssertEqual(data.rows[1].payload?.columns, ["L"])
    XCTAssertEqual(data.rows[1].comment, "L&  [26] LATIN CAPITAL LETTER A..LATIN CAPITAL LETTER Z")
    XCTAssertEqual(data.rows[3].payload?.range, 0x00AA...0x00AA)
    
    
    let temporaryFile = try TemporaryFile()
    try temporaryFile.write(string: string)
    try temporaryFile.seek(toOffset: 0)
    data = try UnicodeData(temporaryFile)
    XCTAssertNil(data.rows[0].payload)
    XCTAssertEqual(data.rows[0].comment, "Bidi_Class=Left_To_Right")
    XCTAssertEqual(data.rows[2].payload?.range, 0x0061...0x007A)
    XCTAssertEqual(data.rows[2].payload?.columns, ["L"])
    XCTAssertEqual(data.rows[2].comment, "L&  [26] LATIN SMALL LETTER A..LATIN SMALL LETTER Z")
    XCTAssertEqual(data.rows[3].payload?.range, 0x00AA...0x00AA)
  }
  
  func test_url() {
    let url = URL(string: "https://unicode.org/Public/UNIDATA/NormalizationCorrections.txt")!
    XCTAssertNoThrow(try UnicodeData(url: url))
  }
  
  func test_multipleRanges() {
    let string = """
    0000..001F;
    0020..002F;
    0040..004F;
    """
    let multipleRanges = UnicodeData(string).multipleRanges
    XCTAssertEqual(multipleRanges.ranges,
                   [0x0000....0x002F, 0x0040....0x004F])
  }
  
  func test_rangeDictionary() {
    let string = """
    0000..001F; A
    0020..002F; A
    0040..004F; B
    0060..006F; B
    """
    let dic = UnicodeData(string).rangeDictionary { $0.first! }
    XCTAssertEqual(dic.count, 3)
    XCTAssertEqual(dic[0x0012], "A")
    XCTAssertEqual(dic[0x0045], "B")
    XCTAssertEqual(dic[0x0067], "B")
  }
  
  func test_split() throws {
    let string = """
    0000..001F; A
    0020..002F; A
    0040..004F; B
    0060..006F; B
    """
    let dic = try UnicodeData(string).split(keyColumn: 0)
    XCTAssertEqual(dic.keys.count, 2)
    XCTAssertEqual(dic["A"]?.ranges, [0x0000....0x002F])
    XCTAssertEqual(dic["B"]?.ranges, [0x0040....0x004F, 0x0060....0x006F])
  }
}


