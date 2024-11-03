/* *************************************************************************************************
 CodeUpdaterManagerTests.swift
   © 2019,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import yCodeUpdater

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class CodeUpdaterManagerTests {
  @Test func test_arguments() {
    var manager = CodeUpdaterManager(arguments: ["-f", "Forced", "-s", "Skipped"])
    #expect(manager._forcesToUpdate(fileOf: "Forced"))
    #expect(manager._skips(fileOf: "Skipped"))

    manager = CodeUpdaterManager(arguments: ["--only", "Only"])
    #expect(manager._forcesToUpdate(fileOf: "Only"))
    #expect(!manager._skips(fileOf: "Only"))

    manager = CodeUpdaterManager(arguments: ["--force-all"])
    #expect(manager._forcesToUpdate(fileOf: "AnyFile"))

    manager = CodeUpdaterManager(arguments: ["--show-updaters"])
    #expect(manager._shouldShowUpdaters)

    manager = CodeUpdaterManager(arguments: [])
    #expect(!manager._forcesToUpdate(fileOf: "AnyFile"))
  }
}
#else
import XCTest

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
#endif
