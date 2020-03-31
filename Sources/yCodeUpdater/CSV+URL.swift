/* *************************************************************************************************
CSV+URL.swift
  © 2019 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CSV
import Foundation
import NetworkGear

extension CSVReader {
  public convenience init(
    url: URL,
    encoding: String.Encoding = .utf8,
    hasHeaderRow: Bool = defaultHasHeaderRow,
    trimFields: Bool = defaultTrimFields,
    delimiter: UnicodeScalar = defaultDelimiter,
    whitespaces: CharacterSet = defaultWhitespaces
  ) throws {
    guard let content = url.content else { throw CSVError.cannotOpenFile }
    guard let string = String(data: content, encoding: encoding) else { throw CSVError.cannotReadFile }
    try self.init(
      string: string,
      hasHeaderRow: hasHeaderRow,
      trimFields: trimFields,
      delimiter: delimiter,
      whitespaces: whitespaces
    )
  }
}
