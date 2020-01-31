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
  func test_license() {
    let license = unicodeLicense()
    let firstLine = license.split(whereSeparator: { $0.isNewline }).first
    XCTAssertEqual(firstLine, "UNICODE, INC. LICENSE AGREEMENT - DATA FILES AND SOFTWARE")
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
    XCTAssertNil(data.rows[0].data)
    XCTAssertEqual(data.rows[0].comment, "Bidi_Class=Left_To_Right")
    XCTAssertEqual(data.rows[1].data?.range, "\u{0041}"..."\u{005A}")
    XCTAssertEqual(data.rows[1].data?.columns, ["L"])
    XCTAssertEqual(data.rows[1].comment, "L&  [26] LATIN CAPITAL LETTER A..LATIN CAPITAL LETTER Z")
    XCTAssertEqual(data.rows[3].data?.range, "\u{00AA}"..."\u{00AA}")
    
    
    var temporaryFile = try TemporaryFile()
    try temporaryFile.write(string: string)
    try temporaryFile.seek(toOffset: 0)
    data = try UnicodeData(temporaryFile)
    XCTAssertNil(data.rows[0].data)
    XCTAssertEqual(data.rows[0].comment, "Bidi_Class=Left_To_Right")
    XCTAssertEqual(data.rows[2].data?.range, "\u{0061}"..."\u{007A}")
    XCTAssertEqual(data.rows[2].data?.columns, ["L"])
    XCTAssertEqual(data.rows[2].comment, "L&  [26] LATIN SMALL LETTER A..LATIN SMALL LETTER Z")
    XCTAssertEqual(data.rows[3].data?.range, "\u{00AA}"..."\u{00AA}")
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
                   ["\u{0000}"...."\u{002F}", "\u{0040}"...."\u{004F}"])
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
    XCTAssertEqual(dic["\u{0012}"], "A")
    XCTAssertEqual(dic["\u{0045}"], "B")
    XCTAssertEqual(dic["\u{0067}"], "B")
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
    XCTAssertEqual(dic["A"]?.ranges, ["\u{0000}"...."\u{002F}"])
    XCTAssertEqual(dic["B"]?.ranges, ["\u{0040}"...."\u{004F}", "\u{0060}"...."\u{006F}"])
  }
}


