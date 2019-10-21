/* *************************************************************************************************
 SwiftKeywords.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
import NetworkGear
import TemporaryFile

private let _remote_gyb_syntax_support_directory = URL(string: "https://raw.githubusercontent.com/apple/swift/master/utils/gyb_syntax_support")!
private let _python_files: [String] = [
  "AttributeNodes.py",
  "AvailabilityNodes.py",
  "Child.py",
  "Classification.py",
  "CommonNodes.py",
  "DeclNodes.py",
  "ExprNodes.py",
  "GenericNodes.py",
  "Node.py",
  "NodeSerializationCodes.py",
  "PatternNodes.py",
  "StmtNodes.py",
  "Token.py",
  "Traits.py",
  "Trivia.py",
  "TypeNodes.py",
  "__init__.py",
  "kinds.py",
]
private let _swiftPackageRoot = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
private let _buildDirectory = _swiftPackageRoot.appendingPathComponent(".build", isDirectory: true)
private let _gybSyntaxSupportDirectory = _buildDirectory.appendingPathComponent("python_modules", isDirectory: true).appendingPathComponent("gyb_syntax_support", isDirectory: true)

private func _downloadPythonFiles() {
  _do("Downloding python files to determine Swift keywords.") {
    let manager = FileManager.default
    
    if !manager.fileExists(atPath: _gybSyntaxSupportDirectory.path) {
      _do("Creating directory at \(_gybSyntaxSupportDirectory.path)") {
        try manager.createDirectory(at: _gybSyntaxSupportDirectory, withIntermediateDirectories: true)
      }
    }
    
    for file in _python_files {
      let target = _gybSyntaxSupportDirectory.appendingPathComponent(file, isDirectory: false)
      if manager.fileExists(atPath: target.path) { continue }
      
      let remoteURL = _remote_gyb_syntax_support_directory.appendingPathComponent(file)
      let data = _fetch(remoteURL)
      
      _do("Writing data to \(target.path)") {
        try data.write(to: target)
      }
    }
  }
}

@available(macOS 10.13, *)
private let _swiftKeywords: Set<String> = ({ () -> Set<String> in
  _downloadPythonFiles()
  return _do("Getting Swift keywords") {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    process.currentDirectoryURL = _gybSyntaxSupportDirectory
    process.standardInput = TemporaryFile(contents: """
      from Token import SYNTAX_TOKEN_MAP
      from Token import DeclKeyword, ExprKeyword, StmtKeyword, Keyword
      for token in SYNTAX_TOKEN_MAP.values():
        if type(token) == DeclKeyword or type(token) == ExprKeyword or type(token) == StmtKeyword or type(token) == Keyword:
          print(token.text)
      """.data(using: .utf8)!)
    let resultPipe = Pipe()
    process.standardOutput = resultPipe
    try process.run()
    
    let resultFileHandle = resultPipe.fileHandleForReading
    let resultData = resultFileHandle.availableData
    let resultString = String(data: resultData, encoding: .utf8)!
    var result: Set<String> = []
    for keyword in resultString.split(whereSeparator: { $0.isWhitespace || $0.isNewline }) {
      result.insert(String(keyword))
    }
    return result
  }
})()

extension String {
  public var isSwiftKeyword: Bool {
    if #available(macOS 10.13, *) {
      return _swiftKeywords.contains(self)
    } else {
      fatalError("macOS < 10.13 is not supported.")
    }
  }
}
