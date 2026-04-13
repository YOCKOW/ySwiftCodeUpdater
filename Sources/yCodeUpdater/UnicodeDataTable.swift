/* *************************************************************************************************
 UnicodeDataTable.swift
   © 2019-2020,2023-2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import NetworkGear
import Ranges
import yExtensions
import yProtocols

private enum _UnicodeLicenseError: Error {
  case unexpectedRemoteContent
}

private let _unicodeLicenseURL = URL(string: "https://www.unicode.org/license.txt")!

private actor _UnicodeLicense {
  static let shared: _UnicodeLicense = .init()

  private let _unicodeLicense: CacheStore<String> = .init()
  var unicodeLicense: String {
    get async throws {
      try await _unicodeLicense.getValue { () async throws -> String in
        try await JobManager.default.do(
          "Fetch Unicode License.",
          jobID: "Unicode License"
        ) { context in
          let licenseData = try await context.content(of: _unicodeLicenseURL)
          guard let licenseString = String(data: licenseData, encoding: .utf8) else {
            throw _UnicodeLicenseError.unexpectedRemoteContent
          }
          return licenseString
        }
      }
    }
  }
}

/// Returns Unicode License.
public func unicodeLicense() async throws -> String {
  return try await _UnicodeLicense.shared.unicodeLicense
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

/// Representation of "Unicode Character Database".
public struct UnicodeDataTable: Sendable {
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

  public fileprivate(set) var rows: [Row]

  /// Returns simple ranges of `Unicode.Scalar`.
  public var rangeSet: GeneralizedRangeSet<Unicode.Scalar.Value> {
    return .init(self.rows.compactMap({ $0.payload?.range }))
  }

  public init(rows: [Row]) {
    self.rows = rows
  }

  public init<S>(_ string: S) where S: StringProtocol {
    var rows: [Row] = []

    var ii = string.startIndex
    var lineStartIndex = ii
    while ii < string.endIndex {
      let nextIndex = string.index(after: ii)
      if nextIndex >= string.endIndex || string[ii].isNewline {
        let line = string[lineStartIndex...ii]
        if let row = Row(line) {
          rows.append(row)
        }
        lineStartIndex = nextIndex
      }
      ii = nextIndex
    }

    self.init(rows: rows)
  }

  public init<FH>(_ fileHandle: FH) throws where FH: FileHandleProtocol {
    var rows: [Row] = []
    while true {
      guard let lineData = try fileHandle.read(toByte: 0x0A), !lineData.isEmpty else {
        break
      }
      guard let line = String(data: lineData, encoding: .utf8) else { throw Error.nonUTF8 }
      if let row = Row(line) {
        rows.append(row)
      }
    }
    if rows.isEmpty {
      throw Error.noData
    }
    self.init(rows: rows)
  }

  public init(url: URL) async throws {
    self = try await JobManager.default.do(
      "Fetch Unicode Data at \(url.absoluteString)",
      jobID: "Remote Unicode Data"
    ) { ctx in
      let data = try await ctx.content(of: url)
      guard let string = String(data: data, encoding: .utf8) else { throw Error.nonUTF8 }
      return UnicodeDataTable(string)
    }
  }

  /// Returns a range-dictionary converting columns.
  ///
  /// `T` must conform to `Equatable` for practical uses.
  public func rangeDictionary<T>(
    converter: ([String]) throws -> T
  ) rethrows -> RangeDictionary<Unicode.Scalar.Value, T> where T: Equatable {
    func _converted(row: Row) throws -> (any GeneralizedRange<Unicode.Scalar.Value>, T)? {
      guard let payload = row.payload else { return nil }
      return (payload.range, try converter(payload.columns))
    }
    return .init(try self.rows.compactMap({ try _converted(row: $0) }))
  }

  /// Returns a dictionary whose key is a string at `keyColumnIndex` and whose value is its ranges.
  public func dictionary(
    withKeyColumAt keyColumnIndex: Int = 0
  ) throws -> [String: GeneralizedRangeSet<Unicode.Scalar.Value>] {
    var result: [String: GeneralizedRangeSet<Unicode.Scalar.Value>] = [:]
    for row in self.rows {
      guard let payload = row.payload else { continue }
      if payload.columns.count <= keyColumnIndex { throw Error.outOfRange }
      let key = payload.columns[keyColumnIndex]
      if var rangeSet = result[key] {
        rangeSet.insert(payload.range)
        result[key] = rangeSet
      } else {
        result[key] = [payload.range]
      }
    }
    return result
  }
}


@available(*, deprecated, renamed: "UnicodeDataTable")
open class UnicodeData {
  public typealias Error = UnicodeDataTable.Error
  public typealias Row = UnicodeDataTable.Row

  private var _table: UnicodeDataTable
  private init(_table table: UnicodeDataTable) {
    self._table = table
  }


  open var rows: Array<Row> {
    get {
      self._table.rows
    }
    set {
      self._table.rows = newValue
    }
  }

  public convenience init<S>(_ string: S) where S: StringProtocol {
    self.init(_table: UnicodeDataTable(string))
  }
  
  public convenience init<FH>(_ fileHandle: FH) throws where FH: FileHandleProtocol {
    self.init(_table: try UnicodeDataTable(fileHandle))
  }
  
  public convenience init(_ fileHandle: FileHandle) throws {
    try self.init(AnyFileHandle(fileHandle))
  }
  
  public convenience required init(url: URL) async throws {
    self.init(_table: try await UnicodeDataTable(url: url))
  }

  /// Returns simple ranges of `Unicode.Scalar`.
  open var rangeSet: GeneralizedRangeSet<Unicode.Scalar.Value> {
    return self._table.rangeSet
  }

  /// Returns simple ranges of `Unicode.Scalar`.
  @available(*, deprecated, renamed: "rangeSet")
  open var multipleRanges: MultipleRanges<Unicode.Scalar.Value> {
    return self.rangeSet
  }
  
  /// Returns a range-dictionary converting columns.
  ///
  /// `T` must conform to `Equatable` for practical uses.
  open func rangeDictionary<T>(converter: ([String]) throws -> T) rethrows -> RangeDictionary<Unicode.Scalar.Value, T> where T: Equatable {
    return try self._table.rangeDictionary(converter: converter)
  }
  
  /// Returns a dictionary whose key is a string at `keyColumn` and whose value is its ranges.
  open func split(keyColumn: Int = 0) throws -> [String: GeneralizedRangeSet<Unicode.Scalar.Value>] {
    return try self._table.dictionary(withKeyColumAt: keyColumn)
  }
}
