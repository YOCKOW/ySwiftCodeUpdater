/* *************************************************************************************************
 UnicodeData.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import BonaFideCharacterSet
import Foundation
import yExtensions

private let _unicodeLicenseURL = URL(string: "https://www.unicode.org/license.html")!
private func _unicodeLicenseRawHTML() -> String {
  return String(data: _fetch(_unicodeLicenseURL), encoding: .utf8)!
}

private var _unicodeLicense: String! = nil

/// Returns Unicode License.
public func unicodeLicense() -> String {
  if _unicodeLicense == nil {
    enum _Error: Error { case unexpectedLine }
    _unicodeLicense = _do("Extract UNICODE LICENSE.") { () -> String in
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
  return _unicodeLicense
}


extension ClosedRange where Bound == Unicode.Scalar {
  fileprivate init(_ string: String) {
    let startAndEnd = string.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: true)
    switch startAndEnd.count {
    case 1:
      guard let startValue = UInt32(startAndEnd[0], radix: 0x10) else { preconditionFailure("Invalid Value for Unicode Scalar.") }
      self.init(uncheckedBounds: (lower: Unicode.Scalar(startValue)!, upper: Unicode.Scalar(startValue)!))
    case 2:
      guard let startValue = UInt32(startAndEnd[0], radix: 0x10),
            let endValue = UInt32(startAndEnd[1], radix:0x10)
      else {
        preconditionFailure("Invalid Value for Unicode Scalar.")
      }
      self.init(uncheckedBounds: (lower: Unicode.Scalar(startValue)!, upper: Unicode.Scalar(endValue)!))
    default:
      preconditionFailure("Unexpected Range Expression.")
    }
  }
}

open class UnicodeData {
  public struct Row {
    public private(set) var data: (range: ClosedRange<Unicode.Scalar>, columns: Array<String>)?
    public private(set) var comment: String?
    
    public init?<S>(_ line: S) where S: StringProtocol {
      if line.isEmpty || line.consists(of: .whitespacesAndNewlines) { return nil }
      
      self.data = nil
      self.comment = nil
      
      let (dataString, comment) = line.splitOnce(separator: "#")
      if !dataString.isEmpty {
        let columns = dataString.split(separator: ";", omittingEmptySubsequences: false).map{
          $0.trimmingUnicodeScalars(in: .whitespacesAndNewlines)
        }
        guard columns.count > 1 else { return nil }
        self.data = (range: .init(columns[0]), columns: Array<String>(columns[1...]))
      }
      if let comment = comment {
        self.comment = comment.trimmingUnicodeScalars(in: .whitespacesAndNewlines)
      }
      
      if self.data == nil && self.comment == nil { return nil }
    }
  }
  
  open var rows: Array<Row>
  
  public init<S>(_ string: S) where S: StringProtocol {
    self.rows = []
    
    var ii = string.startIndex
    var lineStartIndex = ii
    while ii < string.endIndex {
      let nextIndex = string.index(after: ii)
      if nextIndex >= string.endIndex || string[ii].isNewline {
        let line = string[lineStartIndex...ii]
        if let row = Row(line) {
          self.rows.append(row)
        }
        lineStartIndex = nextIndex
      }
      ii = nextIndex
    }
  }
  
  public init(_ fileHandle: FileHandle) {
    self.rows = []
    
    while true {
      let lineData = fileHandle.readData(toByte: 0x0A)
      if lineData.isEmpty { break }
      guard let line = String(data: lineData, encoding: .utf8) else { fatalError("Unexpected Data.") }
      if let row = Row(line) {
        self.rows.append(row)
      }
    }
  }
}
