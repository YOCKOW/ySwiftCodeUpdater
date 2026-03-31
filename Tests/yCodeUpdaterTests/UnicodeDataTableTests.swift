/* *************************************************************************************************
 UnicodeDataTableTests.swift
   © 2019-2020,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import yCodeUpdater
import Foundation
import TemporaryFile
import Ranges
import Testing

@Suite final class UnicodeDataTableTests {
  @Test func test_license() async throws {
    let license = try await unicodeLicense()
    let firstLine = try #require(license.split(whereSeparator: { $0.isNewline }).first)
    #expect(firstLine.contains("UNICODE LICENSE"))
  }

  @Test func test_data() throws {
    let string = """
    # Bidi_Class=Left_To_Right

    0041..005A    ; L # L&  [26] LATIN CAPITAL LETTER A..LATIN CAPITAL LETTER Z
    0061..007A    ; L # L&  [26] LATIN SMALL LETTER A..LATIN SMALL LETTER Z
    00AA          ; L # Lo       FEMININE ORDINAL INDICATOR
    """

    var data = UnicodeDataTable(string)
    guard data.rows.count == 4 else { Issue.record(); return }
    #expect(data.rows[0].payload == nil)
    #expect(data.rows[0].comment == "Bidi_Class=Left_To_Right")
    #expect(data.rows[1].payload?.range == 0x0041...0x005A)
    #expect(data.rows[1].payload?.columns == ["L"])
    #expect(data.rows[1].comment == "L&  [26] LATIN CAPITAL LETTER A..LATIN CAPITAL LETTER Z")
    #expect(data.rows[3].payload?.range == 0x00AA...0x00AA)


    let temporaryFile = try TemporaryFile()
    try temporaryFile.write(string: string)
    try temporaryFile.seek(toOffset: 0)
    data = try UnicodeDataTable(temporaryFile)
    guard data.rows.count == 4 else { Issue.record(); return }
    #expect(data.rows[0].payload == nil)
    #expect(data.rows[0].comment == "Bidi_Class=Left_To_Right")
    #expect(data.rows[2].payload?.range == 0x0061...0x007A)
    #expect(data.rows[2].payload?.columns == ["L"])
    #expect(data.rows[2].comment == "L&  [26] LATIN SMALL LETTER A..LATIN SMALL LETTER Z")
    #expect(data.rows[3].payload?.range == 0x00AA...0x00AA)
  }

  @Test func test_url() async {
    let url = URL(string: "https://unicode.org/Public/UNIDATA/NormalizationCorrections.txt")!
    await #expect(throws: Never.self) { try await UnicodeDataTable(url: url) }
  }

  @Test func test_rangeSet() {
    let string = """
    0000..001F;
    0020..002F;
    0040..004F;
    """
    let rangeSet = UnicodeDataTable(string).rangeSet
    #expect(rangeSet == [0x0000...0x002F, 0x0040...0x004F])
  }

  @Test func test_rangeDictionary() {
    let string = """
    0000..001F; A
    0020..002F; A
    0040..004F; B
    0060..006F; B
    """
    let dic = UnicodeDataTable(string).rangeDictionary { $0.first! }
    #expect(dic.count == 3)
    #expect(dic[0x0012] == "A")
    #expect(dic[0x0045] == "B")
    #expect(dic[0x0067] == "B")
  }

  @Test func test_split() throws {
    let string = """
    0000..001F; A
    0020..002F; A
    0040..004F; B
    0060..006F; B
    """
    let dic = try UnicodeDataTable(string).dictionary(withKeyColumAt: 0)
    #expect(dic.keys.count == 2)
    #expect(dic["A"] == [0x0000...0x002F])
    #expect(dic["B"] == [0x0040...0x004F, 0x0060...0x006F])
  }
}
