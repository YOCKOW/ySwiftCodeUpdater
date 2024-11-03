/* *************************************************************************************************
 CSVRow.swift
   © 2019,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import CSV

fileprivate final class _NameTable: Sendable {
  private let _table: [String: Int]

  fileprivate init(names: [String]) {
    var table: [String: Int] = [:]
    for ii in 0..<names.count {
      table[names[ii]] = ii
    }
    self._table = table
  }
  
  fileprivate subscript(_ name: String) -> Int? {
    return self._table[name]
  }
}

/// Represents a row of CSV.
public struct CSVRow: Sendable {
  private var _fields: [String]
  private var _nameTable: _NameTable?
  
  /// Returns the field values.
  public var fields: [String] { return self._fields }
  
  fileprivate init(fields: [String], nameTable: _NameTable?) {
    self._fields = fields
    self._nameTable = nameTable
  }
  
  /// The number of fields in the row.
  public var count: Int { return self._fields.count }
  
  /// Returns the field value at the specified position.
  public subscript(_ index: Int) -> String? {
    guard index < self.count else { return nil }
    return self._fields[index]
  }
  
  /// Returns the field value with the specified name.
  public subscript(_ name: String) -> String? {
    return self._nameTable?[name].flatMap({ self[$0] })
  }
}

extension CSVRow: CustomDebugStringConvertible, CustomStringConvertible {
  public var description: String {
    return self._fields.joined(separator: ",")
  }
  
  public var debugDescription: String {
    return self._fields.joined(separator: ", ")
  }
}

extension CSVReader {
  /// Returns the rows of CSV.
  ///
  /// Note: This function consumes the data using `func next() -> [String]?`.
  public func rows() -> [CSVRow] {
    let nameTable = self.headerRow.flatMap(_NameTable.init(names:))
    var result: [CSVRow] = []
    for row in self {
      result.append(CSVRow(fields: row, nameTable: nameTable))
    }
    return result
  }
}
