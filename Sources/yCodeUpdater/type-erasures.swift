/* *************************************************************************************************
 type-erasures.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

private func _mustBeOverridden(function: StaticString = #function,
                               file: StaticString = #file, line: UInt = #line) -> Never {
  fatalError("\(function) must be overridden.", file: file, line: line)
}

internal struct _AnyIntermediateDataContainer {
  private class _Box {
    var content: Any { _mustBeOverridden() }
    var sourceURL: URL {
      get { _mustBeOverridden() }
      set { _mustBeOverridden() }
    }
    var userInfo: Dictionary<String, Any>? { _mustBeOverridden() }
  }
  
  private class _Container<T>: _Box {
    private var _base: IntermediateDataContainer<T>
    fileprivate init(_ base: IntermediateDataContainer<T>) {
      self._base = base
    }
    
    override var content: Any { return self._base.content }
    override var sourceURL: URL {
      get { return self._base.sourceURL }
      set { self._base.sourceURL = newValue }
    }
    override var userInfo: Dictionary<String, Any>? { return self._base.userInfo }
  }
  
  private var _box: _Box
  internal var content: Any { return self._box.content }
  internal var sourceURL: URL {
    get { self._box.sourceURL }
    set { self._box.sourceURL = newValue }
  }
  internal var userInfo: Dictionary<String, Any>? { return self._box.userInfo }
  
  internal init<T>(_ container: IntermediateDataContainer<T>) {
    self._box = _Container<T>(container)
  }
}

internal struct _AnyCodeUpdaterDelegate {
  private class _Box {
    var identifier: String { _mustBeOverridden() }
    var sourceURLs: Array<URL> { _mustBeOverridden() }
    var destinationURL: URL { _mustBeOverridden() }
    func prepare(sourceURL: URL) throws -> _AnyIntermediateDataContainer { _mustBeOverridden() }
    func convert(_ container: _AnyIntermediateDataContainer) throws -> Data { _mustBeOverridden() }
  }
  
  private class _Delegate<D, T>: _Box
    where D: CodeUpdaterDelegate, D.IntermediateDataType == T
  {
    private var _base: D
    fileprivate init(_ base: D) {
      self._base = base
    }
    
    override var identifier: String { return self._base.identifier }
    override var sourceURLs: Array<URL> { return self._base.sourceURLs }
    override var destinationURL: URL { return self._base.destinationURL }
    override func prepare(sourceURL: URL) throws -> _AnyIntermediateDataContainer {
      return _AnyIntermediateDataContainer(try self._base.prepare(sourceURL: sourceURL))
    }
    override func convert(_ container: _AnyIntermediateDataContainer) throws -> Data {
      guard case let content as T = container.content else { fatalError("Unexpected Type.") }
      return try self._base.convert(.init(content: content,
                                          sourceURL: container.sourceURL,
                                          userInfo: container.userInfo))
    }
  }
  
  private var _box: _Box
  internal var identifier: String { return self._box.identifier }
  internal var sourceURLs: Array<URL> { return self._box.sourceURLs }
  internal var destinationURL: URL { return self._box.destinationURL }
  internal func prepare(sourceURL: URL) throws -> _AnyIntermediateDataContainer { return try self._box.prepare(sourceURL: sourceURL) }
  internal func convert(_ container: _AnyIntermediateDataContainer) throws -> Data { return try self._box.convert(container) }
  
  internal init<D>(_ delegate: D) where D: CodeUpdaterDelegate {
    self._box = _Delegate(delegate)
  }
}
