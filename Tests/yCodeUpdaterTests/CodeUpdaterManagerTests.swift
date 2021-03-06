/* *************************************************************************************************
 CodeUpdaterManagerTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import yCodeUpdater

final class CodeUpdaterManagerTests: XCTestCase {
  func test_arguments() {
    var manager = CodeUpdaterManager(arguments: ["-f", "Forced", "-s", "Skipped"])
    XCTAssertTrue(manager._forcesToUpdate(fileOf: "Forced"))
    XCTAssertTrue(manager._skips(fileOf: "Skipped"))
    
    manager = CodeUpdaterManager(arguments: ["--only", "Only"])
    XCTAssertTrue(manager._forcesToUpdate(fileOf: "Only"))
    XCTAssertFalse(manager._skips(fileOf: "Only"))
    
    manager = CodeUpdaterManager(arguments: ["--force-all"])
    XCTAssertTrue(manager._forcesToUpdate(fileOf: "AnyFile"))
    
    manager = CodeUpdaterManager(arguments: ["--show-updaters"])
    XCTAssertTrue(manager._shouldShowUpdaters)
    
    manager = CodeUpdaterManager(arguments: [])
    XCTAssertFalse(manager._forcesToUpdate(fileOf: "AnyFile"))
  }
}
