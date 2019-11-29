/* *************************************************************************************************
 Unicode.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import BonaFideCharacterSet
import Foundation

private let _unicodeLicenseURL = URL(string: "https://www.unicode.org/license.html")!
private func _unicodeLicenseRawHTML() -> String {
  return String(data: _fetch(_unicodeLicenseURL), encoding: .utf8)!
}

public func unicodeLicense() -> String {
  enum _Error: Error { case unexpectedLine }
  return _do("Extract UNICODE LICENSE.") {
    var result = ""
    var pre: Bool = false
    for line in _unicodeLicenseRawHTML().split(whereSeparator: { $0.isNewline }).map({ $0.trimmingUnicodeScalars(in: .whitespaces) }) {
      if let startRange = line.range(of: #"<a name="License">"#) {
        guard let endRange = line.range(of: "</a>") else { throw _Error.unexpectedLine }
        result.append(contentsOf: line[startRange.upperBound..<endRange.lowerBound])
        result += "\n\n"
      } else if line == "<pre>" {
        pre = true
      } else if line == "</pre>" {
        pre = false
      } else if pre {
        result += "\(line)\n"
      }
    }
    return result
  }
}
