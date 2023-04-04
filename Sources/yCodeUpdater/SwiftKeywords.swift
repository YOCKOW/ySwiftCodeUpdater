/* *************************************************************************************************
 SwiftKeywords.swift
   © 2019, 2022 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
import NetworkGear
import TemporaryFile
import yExtensions

private let _remote_gyb_syntax_support_directory = URL(string: "https://raw.githubusercontent.com/apple/swift/main/utils/gyb_syntax_support")!
private let _python_files: [String] = [
  "AttributeKinds.py",
  "Token.py",
]
private let _tmpDir = URL.temporaryDirectory
private let _codeUpdaterDir = _tmpDir.appendingPathComponent("ySwiftCodeUpdater")
private let _pythonModulesDirectory = _codeUpdaterDir.appendingPathComponent("python_modules", isDirectory: true)
private let _gybSyntaxSupportDirectory = _pythonModulesDirectory.appendingPathComponent("gyb_syntax_support", isDirectory: true)

private func _downloadPythonFiles() {
  _do("Downlod python files to determine Swift keywords.") {
    let manager = FileManager.default
    
    if !manager.fileExists(atPath: _gybSyntaxSupportDirectory.path) {
      _do("Create directory at \"\(_gybSyntaxSupportDirectory.path)\".") {
        try manager.createDirectoryWithIntermediateDirectories(at: _gybSyntaxSupportDirectory)
      }
    }
    
    for file in _python_files {
      let target = _gybSyntaxSupportDirectory.appendingPathComponent(file, isDirectory: false)
      if manager.fileExists(atPath: target.path) { continue }
      
      let remoteURL = _remote_gyb_syntax_support_directory.appendingPathComponent(file)
      let data = _fetch(remoteURL)
      
      _do("Write data to \"\(target.path)\".") {
        try data.write(to: target)
      }
    }
  }
}

private enum _SwiftKeywordsError: Error {
  case pythonNotFound
  case pythonFailed
}

private let _swiftKeywords: Set<String> = ({ () -> Set<String> in
  _downloadPythonFiles()
  return _do("Get Swift's keywords.") {
    var python: URL! = _search(command: "python3")
    if python == nil {
      python = _search(command: "python")
      if python == nil {
        throw _SwiftKeywordsError.pythonNotFound
      }
    }
    
    guard let keywords = _run(python, currentDirectory: _pythonModulesDirectory, standardInput: """
      from gyb_syntax_support.Token import (SYNTAX_TOKEN_MAP,
                                            DeclKeyword, ExprKeyword, StmtKeyword, Keyword)
      __classes = [DeclKeyword, ExprKeyword, StmtKeyword, Keyword]
      for token in SYNTAX_TOKEN_MAP.values():
        if type(token) in __classes:
          print(token.text)
      """)
      else {
        throw _SwiftKeywordsError.pythonFailed
    }
    
    var result: Set<String> = []
    for keyword in keywords.split(whereSeparator: { $0.isWhitespace || $0.isNewline }) {
      result.insert(String(keyword))
    }
    return result
  }
})()

extension String {
  public var isSwiftKeyword: Bool {
    return _swiftKeywords.contains(self)
  }
  
  public var swiftIdentifier: String {
    if self.isSwiftKeyword {
      return "`\(self)`"
    }
    return self
  }
}
