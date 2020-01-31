/* *************************************************************************************************
 CodeUpdaterManager.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
import yExtensions

open class CodeUpdaterManager {
  private var _updaters: Dictionary<String, CodeUpdater> = [:]
  
  open var updaters: Array<CodeUpdater> {
    get {
      return self._updaters.values.sorted(by: { $0.identifier < $1.identifier })
    }
    set(newUpdaters) {
      self._updaters = newUpdaters.reduce(into: [:]) { $0[$1.identifier] = $1 }
    }
  }
  
  /// Add an updater
  open func add(_ updater: CodeUpdater) {
    self._updaters[updater.identifier] = updater
  }
  
  /// Add an updater's delegate
  open func add<D>(_ delegate: D) where D: CodeUpdaterDelegate {
    self.add(CodeUpdater(delegate: delegate))
  }
  
  private enum _Arguments {
    enum _Identifiers {
      case all
      case identifiers(Set<String>)
      
      mutating func insert(_ string: String) {
        guard case .identifiers(var identifiers) = self else { return }
        identifiers.insert(string)
        self = .identifiers(identifiers)
      }
    }
    
    case help
    case options(force: _Identifiers?, skip: _Identifiers?)
    
    mutating func add(force id: String) {
      guard case .options(force: let nilableF, skip: let nilableS) = self else { fatalError("Unexpected") }
      if var force = nilableF {
        force.insert(id)
        self = .options(force: force, skip: nilableS)
      } else {
        self = .options(force: .identifiers([id]), skip: nilableS)
      }
    }
    
    mutating func add(skip id: String) {
      guard case .options(force: let nilableF, skip: let nilableS) = self else { fatalError("Unexpected") }
      if var skip = nilableS {
        skip.insert(id)
        self = .options(force: nilableF, skip: skip)
      } else {
        self = .options(force: nilableF, skip: .identifiers([id]))
      }
    }
    
    mutating func forceAll() {
      guard case .options(force: _, skip: let nilableS) = self else { fatalError("Unexpected") }
      self = .options(force: .all, skip: nilableS)
    }
    
    /// - parameter arguments: Expected to be the same with `ARGV`.
    init(_ arguments: Array<String>) {
      // Is it better to use some other argument-parser?
      
      let nn = arguments.count
      if nn > 0 && (arguments[0] == "-h" || arguments[0] == "--help") {
        self = .help
      } else {
        self = .options(force: nil, skip: nil)
        
        let requireValue: Set<String> = ["-f", "--force", "-s", "--skip"]
        var ii = 0
        while true {
          if ii >= nn { break }
    
          let arg = arguments[ii]
          if requireValue.contains(arg) {
            guard nn > ii + 1 else { fatalError("`\(arg)` must have a value.") }
            defer { ii += 2 }
            
            let value = arguments[ii + 1]
            switch arg {
            case "-f", "--force":
              self.add(force: value)
            case "-s", "--skip":
              self.add(skip: value)
            default:
              fatalError("Unexpected option: \(arg)")
            }
          } else {
            defer { ii += 1 }
            switch arg {
            case "--force-all":
              self.forceAll()
            default:
              if arg.hasPrefix("--force=") {
                guard let value = arg.splitOnce(separator: "=").1 else { fatalError("`--force` must have a value.") }
                self.add(force: String(value))
              } else if arg.hasPrefix("--skip=") {
                guard let value = arg.splitOnce(separator: "=").1 else { fatalError("`--skip` must have a value.") }
                self.add(skip: String(value))
              } else {
                fatalError("Unexpected option: \(arg)")
              }
            }
          }
        }
      }
    }
  }
  
  private var _arguments: _Arguments
  
  internal func _forcesToUpdate(fileOf identifier: String) -> Bool {
    guard case .options(force: let force?, skip: _) = self._arguments else { return false }
    switch force {
    case .all:
      return true
    case .identifiers(let set):
      return set.contains(identifier)
    }
  }
  
  internal func _skips(fileOf identifier: String) -> Bool {
    guard case .options(force: _, skip: let skip?) = self._arguments else { return false }
    switch skip {
    case .all:
      return true
    case .identifiers(let set):
      return set.contains(identifier)
    }
  }
  
  /// - parameter arguments: Expected to be the same with `ARGV`.
  public init(arguments: Array<String> = ProcessInfo.processInfo.arguments) {
    self._arguments = _Arguments(arguments)
  }
  
  open func viewHelp() {
    print("""
    options:
      -f, --foce "identifier"  Forces to update a file specified by the identifier.
      -s, --skip "identifier"  Skips a file specified by the identifier.
      --force-all              Forces to update all files.
      
    """)
  }
  
  open func run() {
    if case .help = self._arguments {
      self.viewHelp()
      return
    }
    
    for updater in self.updaters {
      if self._skips(fileOf: updater.identifier) {
        _viewInfo("Skip `\(updater.identifier)`.")
        continue
      }
      
      if self._forcesToUpdate(fileOf: updater.identifier) {
        updater.forcesToUpdate = true
      }
      updater.update()
    }
  }
}
