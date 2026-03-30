/* *************************************************************************************************
 CodeUpdaterManagerTests.swift
   © 2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import yCodeUpdater
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
