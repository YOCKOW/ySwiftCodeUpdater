/* *************************************************************************************************
 Date+CodeUpdater.swift
   © 2019,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

private protocol _DateFormatterProtocol {
  func date(from string: String) -> Date?
  func string(from date: Date) -> String
}

@available(macOS 10.12, *)
extension ISO8601DateFormatter: _DateFormatterProtocol {}

extension DateFormatter: _DateFormatterProtocol {}

private struct _DateFormatter: @unchecked Sendable {
  private let _dateFormatter: any _DateFormatterProtocol

  init () {
    if #available(macOS 10.12, *) {
      self._dateFormatter = ISO8601DateFormatter()
    } else {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
      self._dateFormatter = formatter
    }
  }

  func date(from string: String) -> Date? {
    return _dateFormatter.date(from: string)
  }

  func string(from date: Date) -> String {
    return _dateFormatter.string(from: date)
  }

  static let shared: _DateFormatter = .init()
}


extension Date {
  internal init?(iso8601String: String) {
    guard let date = _DateFormatter.shared.date(from: iso8601String) else { return nil }
    self = date
  }
  
  internal var iso8601String: String {
    return _DateFormatter.shared.string(from: self)
  }
}
