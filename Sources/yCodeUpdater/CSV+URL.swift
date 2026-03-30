/* *************************************************************************************************
CSV+URL.swift
  © 2019,2026 YOCKOW.
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
  ) async throws {
    let content = try await _fetch(url, jobID: "Remote CSV")
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
