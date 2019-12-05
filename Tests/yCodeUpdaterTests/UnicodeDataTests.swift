/* *************************************************************************************************
 UnicodeDataTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import yCodeUpdater

import TemporaryFile

final class UnicodeDataTests: XCTestCase {
  func test_license() {
    let license = unicodeLicense()
    let firstLine = license.split(whereSeparator: { $0.isNewline }).first
    XCTAssertEqual(firstLine, "UNICODE, INC. LICENSE AGREEMENT - DATA FILES AND SOFTWARE")
  }
  
  func test_data() {
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
    
    
    let temporaryFile = TemporaryFile()
    temporaryFile.write(string)
    temporaryFile.seek(toFileOffset: 0)
    data = UnicodeData(temporaryFile)
    XCTAssertNil(data.rows[0].data)
    XCTAssertEqual(data.rows[0].comment, "Bidi_Class=Left_To_Right")
    XCTAssertEqual(data.rows[2].data?.range, "\u{0061}"..."\u{007A}")
    XCTAssertEqual(data.rows[2].data?.columns, ["L"])
    XCTAssertEqual(data.rows[2].comment, "L&  [26] LATIN SMALL LETTER A..LATIN SMALL LETTER Z")
    XCTAssertEqual(data.rows[3].data?.range, "\u{00AA}"..."\u{00AA}")
  }
}


