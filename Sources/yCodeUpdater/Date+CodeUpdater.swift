/* *************************************************************************************************
 Date+CodeUpdater.swift
   © 2019 YOCKOW.
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

private let _dateFormatter = ({ () -> _DateFormatterProtocol in
  if #available(macOS 10.12, *) {
    return ISO8601DateFormatter()
  } else {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }
})()

extension Date {
  internal init?(iso8601String: String) {
    guard let date = _dateFormatter.date(from: iso8601String) else { return nil }
    self = date
  }
  
  internal var iso8601String: String {
    return _dateFormatter.string(from: self)
  }
}
