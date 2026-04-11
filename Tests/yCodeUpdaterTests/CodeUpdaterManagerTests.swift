/* *************************************************************************************************
 CodeUpdaterManagerTests.swift
   © 2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import yCodeUpdater
import Testing

@Suite final class CodeUpdaterManagerTests {
  @Test func test_arguments() async {
    var manager = CodeUpdaterManager(arguments: ["-f", "Forced", "-s", "Skipped"])
    #expect(await manager._forcesToUpdate(fileOf: "Forced"))
    #expect(await manager._skips(fileOf: "Skipped"))

    manager = CodeUpdaterManager(arguments: ["--only", "Only"])
    #expect(await manager._forcesToUpdate(fileOf: "Only"))
    #expect(await !manager._skips(fileOf: "Only"))

    manager = CodeUpdaterManager(arguments: ["--force-all"])
    #expect(await manager._forcesToUpdate(fileOf: "AnyFile"))

    manager = CodeUpdaterManager(arguments: ["--show-updaters"])
    #expect(await manager._shouldShowUpdaters)

    manager = CodeUpdaterManager(arguments: [])
    #expect(await !manager._forcesToUpdate(fileOf: "AnyFile"))
  }
}
