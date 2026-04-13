/* *************************************************************************************************
 Cached.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */


private enum _Cache<Value> where Value: Sendable {
  typealias Continuation = CheckedContinuation<Value, any Error>

  /// Already cached.
  case cached(Value)

  /// Caching in progress.
  case processing(continuations: [Continuation])

  mutating func appendContinuation(_ continuation: Continuation) {
    guard case .processing(var continuatinos) = self else {
      return
    }
    continuatinos.append(continuation)
    self = .processing(continuations: continuatinos)
  }

  func resumuContinuations(with result: Result<Value, any Error>) {
    guard case .processing(let continuations) = self else {
      return
    }
    continuations.forEach({ $0.resume(with: result) })
  }
}

/// Store a cached value.
public actor Cached<Value> where Value: Sendable {
  private var _cache: _Cache<Value>?

  public init() {
    _cache = nil
  }

  public func getValue(
    isCached: inout Bool,
    ifAbsent initializer: @Sendable () async throws -> Value
  ) async throws -> Value {
    if let status = _cache {
      switch status {
      case .cached(let value):
        isCached = true
        return value
      case .processing:
        let value = try await withCheckedThrowingContinuation {
          _cache!.appendContinuation($0)
        }
        isCached = true
        return value
      }
    }

    isCached = false
    _cache = .processing(continuations: [])
    var value: Value!
    do {
      value = try await initializer()
    } catch {
      _cache!.resumuContinuations(with: .failure(error))
      throw error
    }
    _cache!.resumuContinuations(with: .success(value))
    _cache = .cached(value)
    return value
  }

  public func getValue(
    ifAbsent initializer: @Sendable () async throws -> Value
  ) async throws -> Value {
    var isCached = false
    return try await self.getValue(isCached: &isCached, ifAbsent: initializer)
  }
}

/// Store cached values with associated keys.
public actor KeyedCacheStore<Key, Value> where Key: Hashable, Key: Sendable, Value: Sendable {
  private var _caches: [Key: Cached<Value>]

  public init() {
    _caches = [:]
  }

  public var keys: some Collection<Key> & Sendable {
    return _caches.keys
  }

  public func value(
    for key: Key,
    isCached: inout Bool,
    ifAbsent initializer: @Sendable () async throws -> Value
  ) async throws -> Value {
    if let store = _caches[key] {
      return try await store.getValue(isCached: &isCached, ifAbsent: initializer)
    }

    let store = Cached<Value>()
    _caches[key] = store
    return try await store.getValue(isCached: &isCached, ifAbsent: initializer)
  }

  public func value(
    for key: Key,
    ifAbsent initializer: @Sendable () async throws -> Value
  ) async throws -> Value {
    var isCached = false
    return try await self.value(for: key, isCached: &isCached, ifAbsent: initializer)
  }
}
