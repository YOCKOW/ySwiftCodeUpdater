/* *************************************************************************************************
 UnicodeData.swift
   © 2019-2020,2023-2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import NetworkGear
import Ranges
import yExtensions
import yProtocols

private let _unicodeLicenseURL = URL(string: "https://www.unicode.org/license.txt")!

/// Returns Unicode License.
public func unicodeLicense() -> String {
  struct __Cache {
    static nonisolated(unsafe) private var _unicodeLicense: String? = nil
    static private let _unicodeLicenseQueue: DispatchQueue = .init(
      label: "jp.YOCKOW.ySwiftCodeUpdater.UnicodeLicense",
      attributes: .concurrent
    )
    static var cache: String {
      return _unicodeLicenseQueue.sync(flags: .barrier) {
        guard let license = _unicodeLicense else {
          let license = String(data: _fetch(_unicodeLicenseURL), encoding: .utf8)!
          _unicodeLicense = license
          return license
        }
        return license
      }
    }
  }
  return __Cache.cache
}

extension Unicode.Scalar {
  /// Represents the Unicode scalar value.
  public typealias Value = UInt32
}

extension ClosedRange where Bound == Unicode.Scalar.Value {
  fileprivate init(_ string: String) {
    let startAndEnd = string.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: true)
    switch startAndEnd.count {
    case 1:
      guard let startValue = UInt32(startAndEnd[0], radix: 0x10) else { preconditionFailure("Invalid Value for Unicode Scalar.") }
      self.init(uncheckedBounds: (lower: startValue, upper: startValue))
    case 2:
      guard let startValue = UInt32(startAndEnd[0], radix: 0x10),
            let endValue = UInt32(startAndEnd[1], radix:0x10)
      else {
        preconditionFailure("Invalid Value for Unicode Scalar.")
      }
      self.init(uncheckedBounds: (lower: startValue, upper: endValue))
    default:
      preconditionFailure("Unexpected Range Expression.")
    }
  }
}

open class UnicodeData {
  public enum Error: LocalizedError, Sendable {
    case noData
    case nonUTF8
    case outOfRange
    
    public var errorDescription: String? {
      switch self {
      case .noData:
        return "No data."
      case .nonUTF8:
        return "The encoding of given string is not UTF-8."
      case .outOfRange:
        return "Out of range."
      }
    }
  }
  
  public struct Row: Sendable {
    public typealias Payload = (range: ClosedRange<Unicode.Scalar.Value>, columns: [String])
    public private(set) var payload: Payload?
    public private(set) var comment: String?
    
    public init?<S>(_ line: S) where S: StringProtocol {
      if line.isEmpty || line.allSatisfy({ $0.isWhitespace || $0.isNewline }) { return nil }
      
      self.payload = nil
      self.comment = nil
      
      let (payloadString, comment) = line.splitOnce(separator: "#")
      if !payloadString.isEmpty {
        let columns = payloadString.split(separator: ";", omittingEmptySubsequences: false).map {
          $0.trimmingUnicodeScalars(where: { $0.latestProperties.isWhitespace || $0.latestProperties.isNewline })
        }
        guard columns.count > 1 else { return nil }
        self.payload = (range: .init(columns[0]), columns: .init(columns.dropFirst()))
      }
      if let comment = comment {
        self.comment = comment.trimmingUnicodeScalars(where: { $0.latestProperties.isWhitespace || $0.latestProperties.isNewline })
      }
      
      if self.payload == nil && self.comment == nil { return nil }
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
  
  public init<FH>(_ fileHandle: FH) throws where FH: FileHandleProtocol {
    self.rows = []
    
    while true {
      guard let lineData = try fileHandle.read(toByte: 0x0A), !lineData.isEmpty else {
        break
      }
      guard let line = String(data: lineData, encoding: .utf8) else { throw Error.nonUTF8 }
      if let row = Row(line) {
        self.rows.append(row)
      }
    }
    if rows.isEmpty { throw Error.noData }
  }
  
  public convenience init(_ fileHandle: FileHandle) throws {
    try self.init(AnyFileHandle(fileHandle))
  }
  
  public convenience required init(url: URL) throws {
    let response = try url.response(to: URL.Request())
    guard let data = response.content else {throw Error.noData }
    guard let string = String(data: data, encoding: .utf8) else { throw Error.nonUTF8 }
    self.init(string)
  }
  
  /// Returns simple ranges of `Unicode.Scalar`.
  open var multipleRanges: MultipleRanges<Unicode.Scalar.Value> {
    return .init(self.rows.compactMap({ ($0.payload?.range).flatMap({ AnyRange($0) }) }))
  }
  
  /// Returns a range-dictionary converting columns.
  ///
  /// `T` must conform to `Equatable` for practical uses.
  open func rangeDictionary<T>(converter: ([String]) throws -> T) rethrows -> RangeDictionary<Unicode.Scalar.Value, T> where T: Equatable {
    func _converted(row: Row) throws -> (AnyRange<Unicode.Scalar.Value>, T)? {
      guard let payload = row.payload else { return nil }
      return (AnyRange(payload.range), try converter(payload.columns))
    }
    return .init(try self.rows.compactMap({ try _converted(row: $0) }))
  }
  
  /// Returns a dictionary whose key is a string at `keyColumn` and whose value is its ranges.
  open func split(keyColumn: Int = 0) throws -> [String: MultipleRanges<Unicode.Scalar.Value>] {
    var result: [String: MultipleRanges<Unicode.Scalar.Value>] = [:]
    for row in self.rows {
      guard let payload = row.payload else { continue }
      if payload.columns.count <= keyColumn { throw Error.outOfRange }
      let key = payload.columns[keyColumn]
      if !result.keys.contains(key) {
        result[key] = .init()
      }
      result[key]!.insert(payload.range)
    }
    return result
  }
}
