/* *************************************************************************************************
 CodeUpdaterDelegate.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import CSV
import Foundation

/// Intermediate Data
///
/// [Source] -`CodeUpdaterDelegate.prepare`-> [Intermediate Data] -`CodeUpdaterDelegate.convert`-> [Final Code]
public struct IntermediateDataContainer<T> {
  /// The intermediate data itself.
  public var content: T
  
  /// Source URL.
  /// This value will be set by `CodeUpdater`.
  public internal(set) var sourceURL: URL! = nil
  
  /// User Info.
  public var userInfo: Dictionary<String, Any>?
  
  public init(content: T, userInfo: Dictionary<String, Any>? = nil) {
    self.content = content
    self.userInfo = userInfo
  }
  
  internal init(content: T, sourceURL: URL, userInfo: Dictionary<String, Any>?) {
    self.content = content
    self.sourceURL = sourceURL
    self.userInfo = userInfo
  }
}

public protocol CodeUpdaterDelegate {
  associatedtype IntermediateDataType
  
  var identifier: String { get }
  var sourceURLs: Array<URL> { get }
  var destinationURL: URL { get }
  
  func prepare(sourceURL: URL) throws -> IntermediateDataContainer<IntermediateDataType>
  func convert(_: IntermediateDataContainer<IntermediateDataType>) throws -> Data
}

extension CodeUpdaterDelegate where Self.IntermediateDataType == Data {
  public func prepare(sourceURL: URL) throws -> IntermediateDataContainer<Data> {
    return .init(content: _fetch(sourceURL))
  }
}

extension CodeUpdaterDelegate where Self.IntermediateDataType == String {
  public func prepare(sourceURL: URL) throws -> IntermediateDataContainer<String> {
    guard let string = String(data: _fetch(sourceURL), encoding: .utf8) else {
      throw CodeUpdaterError.cannotConvertToString
    }
    return .init(content: string)
  }
}

extension CodeUpdaterDelegate where Self.IntermediateDataType == CSVReader {
  public func prepare(sourceURL: URL) throws -> IntermediateDataContainer<CSVReader> {
    let reader = try CSVReader(url: sourceURL)
    return .init(content: reader)
  }
}
