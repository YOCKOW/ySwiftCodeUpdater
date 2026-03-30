/* *************************************************************************************************
 CodeUpdaterDelegate.swift
   © 2019,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@preconcurrency import CSV
import Foundation
import StringComposition

/// Intermediate Data
///
/// [Source] -`CodeUpdaterDelegate.prepare`-> [Intermediate Data] -`CodeUpdaterDelegate.convert`-> [Final Code]
public struct IntermediateDataContainer<T>: Sendable where T: Sendable {
  /// The intermediate data itself.
  public var content: T
  
  /// Source URL.
  /// This value will be set by `CodeUpdater`.
  public internal(set) var sourceURL: URL! = nil
  
  /// User Info.
  public var userInfo: Dictionary<String, any Sendable>?

  public init(content: T, userInfo: Dictionary<String, any Sendable>? = nil) {
    self.content = content
    self.userInfo = userInfo
  }
}

public protocol CodeUpdaterDelegate: Sendable {
  associatedtype IntermediateDataType: Sendable

  var identifier: String { get }
  var sourceURLs: Array<URL> { get }
  var destinationURL: URL { get }
  
  func prepare(sourceURL: URL) async throws -> IntermediateDataContainer<IntermediateDataType>
  func convert<S>(_: S) async throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<IntermediateDataType>
}

public protocol StringCodeUpdaterDelegate: CodeUpdaterDelegate {
  func convert<S>(_: S) async throws -> String where S: Sequence, S.Element == IntermediateDataContainer<IntermediateDataType>
}

public protocol StringLinesCodeUpdaterDelegate: CodeUpdaterDelegate {
  func convert<S>(_: S) async throws -> StringLines where S: Sequence, S.Element == IntermediateDataContainer<IntermediateDataType>
}

extension CodeUpdaterDelegate {
  public var identifier: String {
    let id = self.destinationURL.deletingPathExtension().lastPathComponent
    precondition(!id.isEmpty, "`var identifier: String { get }` must not be empty.")
    return id
  }
}

extension CodeUpdaterDelegate where Self.IntermediateDataType == Data {
  public func prepare(sourceURL: URL) async throws -> IntermediateDataContainer<Data> {
    return .init(content: try await _fetch(sourceURL, jobID: self.identifier))
  }
}

extension CodeUpdaterDelegate where Self.IntermediateDataType == String {
  public func prepare(sourceURL: URL) async throws -> IntermediateDataContainer<String> {
    guard let string = String(data: try await _fetch(sourceURL, jobID: self.identifier), encoding: .utf8) else {
      throw CodeUpdaterError.cannotConvertToString
    }
    return .init(content: string)
  }
}

extension CodeUpdaterDelegate where Self.IntermediateDataType == StringLines {
  public func prepare(sourceURL: URL) async throws -> IntermediateDataContainer<StringLines> {
    guard let string = String(data: try await _fetch(sourceURL, jobID: self.identifier), encoding: .utf8) else {
      throw CodeUpdaterError.cannotConvertToString
    }
    return .init(content: StringLines(string, detectIndent: true))
  }
}

extension CodeUpdaterDelegate where Self.IntermediateDataType == CSVReader {
  public func prepare(sourceURL: URL) async throws -> IntermediateDataContainer<CSVReader> {
    let reader = try await CSVReader(url: sourceURL)
    return .init(content: reader)
  }
}

extension CodeUpdaterDelegate where Self.IntermediateDataType: UnicodeData {
  public func prepare(sourceURL: URL) async throws -> IntermediateDataContainer<IntermediateDataType> {
    return .init(content: try await IntermediateDataType(url: sourceURL))
  }
}

extension StringCodeUpdaterDelegate {
  public func convert<S>(_ intermediates: S) async throws -> Data where S : Sequence, S.Element == IntermediateDataContainer<Self.IntermediateDataType> {
    guard let data = try await self.convert(intermediates).data(using: .utf8) else {
      throw CodeUpdaterError.cannotConvertToData
    }
    return data
  }
}

extension StringLinesCodeUpdaterDelegate {
  public func convert<S>(_ intermediates: S) async throws -> Data where S : Sequence, S.Element == IntermediateDataContainer<Self.IntermediateDataType> {
    guard let data = try await self.convert(intermediates).data(using: .utf8) else {
      throw CodeUpdaterError.cannotConvertToData
    }
    return data
  }
}
