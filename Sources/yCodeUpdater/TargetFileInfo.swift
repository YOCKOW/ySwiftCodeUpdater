/* *************************************************************************************************
 TargetFileInfo.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import BonaFideCharacterSet
import Foundation
import HTTP
import yExtensions


internal enum _FormatError: LocalizedError {
  case unexpectedLine(line: UInt)
  case notCommentLine(line: UInt)
  case notKeyValuePair(line: UInt)
  case invalidURL(line: UInt)
  case invalidDate(line: UInt)
  case infoBeforeURL(line: UInt)
  case duplicatedInfo(line: UInt)
  case invalidETag(line: UInt)
  case noData
  
  public var errorDescription: String? {
    switch self {
    case .unexpectedLine(let line):
      return "Unexpected Line at #\(line)."
    case .notCommentLine(let line):
      return "#\(line) is not a comment line."
    case .notKeyValuePair(let line):
      return "#\(line) must be a key-value pair."
    case .invalidURL(let line):
      return "Invalid URL at #\(line)."
    case .invalidDate(let line):
      return "Invalid Date at #\(line)."
    case .infoBeforeURL(let line):
      return "Some URL must be found before #\(line)."
    case .duplicatedInfo(let line):
      return "Duplicated at #\(line)."
    case .invalidETag(let line):
      return "Invalid ETag at #\(line)."
    case .noData:
      return "No data was found."
    }
  }
}
 
internal struct _TargetFileInfo {
  private struct Info {
    var lastModified: Date? = nil
    var eTag: ETag? = nil
  }
  
  private var _info: [URL: Info]
  
  private init(_ info: [URL: Info]) {
    self._info = info
  }
  
  internal init(fileAt url: URL) throws {
    let fileHandle = try FileHandle(forReadingFrom: url)
    defer {
      func _close() throws {
        if #available(macOS 10.15, *) {
          #if swift(>=5.0) || os(macOS)
          try fileHandle.close()
          return
          #endif
        }
        fileHandle.closeFile()
      }
      try! _close()
    }
    
    var info: [URL: Info] = [:]

    var lineData: Data
    var lineNumber: UInt = 0
    var lastURL: URL! = nil
    while true {
      guard let data = try fileHandle.read(toByte: 0x0A), !data.isEmpty else { break }
      lineData = data

      lineNumber += 1
      guard var line = String(data: lineData, encoding: .utf8)?.trimmingUnicodeScalars(in: .whitespacesAndNewlines) else {
        throw _FormatError.unexpectedLine(line: lineNumber)
      }
      if line.isEmpty { break }

      // `line` must start with "// "
      guard line.hasPrefix("//") else {
        throw _FormatError.notCommentLine(line: lineNumber)
      }
      line = line[line.index(line.startIndex, offsetBy: 2)..<line.endIndex].trimmingUnicodeScalars(in: .whitespaces)
      if line.isEmpty || line.hasPrefix("#") { continue }

      // `line` is "// KEY: VALUE"
      let keyValue = line.split(separator: ":", maxSplits: 1).map{ $0.trimmingUnicodeScalars(in: .whitespaces) }
      guard keyValue.count == 2 else {
        throw _FormatError.notKeyValuePair(line: lineNumber)
      }
      let (key, value) = (keyValue[0].uppercased(), keyValue[1])
      if key == "URL" {
        guard let url = URL(string: value) else { throw _FormatError.invalidURL(line: lineNumber) }
        info[url] = Info()
        lastURL = url
      } else if key == "LAST-MODIFIED" {
        guard let date = Date(iso8601String: value) else { throw _FormatError.invalidDate(line: lineNumber) }
        guard info.keys.contains(lastURL) else { throw _FormatError.infoBeforeURL(line: lineNumber) }
        guard info[lastURL]?.lastModified == nil else { throw _FormatError.duplicatedInfo(line: lineNumber) }
        info[lastURL]!.lastModified = date
      } else if key == "ETAG" {
        guard let eTag = ETag(value) else { throw _FormatError.invalidETag(line: lineNumber) }
        guard info.keys.contains(lastURL) else { throw _FormatError.infoBeforeURL(line: lineNumber) }
        guard info[lastURL]?.eTag == nil else { throw _FormatError.duplicatedInfo(line: lineNumber) }
        info[lastURL]!.eTag = eTag
      } else {
        throw _FormatError.unexpectedLine(line: lineNumber)
      }
    }

    if info.isEmpty {
      throw _FormatError.noData
    }

    self.init(info)
  }
  
  internal func containsInfo(for url: URL) -> Bool {
    return self._info[url] != nil
  }
  
  internal func lastModifiedDate(for url: URL) -> Date? {
    return self._info[url]?.lastModified
  }
  
  internal func eTag(for url: URL) -> ETag? {
    return self._info[url]?.eTag
  }
}
