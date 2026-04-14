/* *************************************************************************************************
 JobManagerTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import Testing
import yCodeUpdater

@Suite final class JobManagerTests {
  @Test func test_cache() async throws {
    let url = try #require(URL(string: "https://example.com/"))
    let jobID = "Test \(#function)"
    let N = 10

    let results = try await JobManager.default.do(jobID, jobID: jobID) { context in
      try await withThrowingTaskGroup(returning: [Data].self) { group in
        for _ in 0..<N {
          group.addTask {
            try await context.content(of: url)
          }
        }
        var results: [Data] = []
        while let data = try await group.next() {
          results.append(data)
        }
        return results
      }
    }
    #expect(results.count == N)
    #expect(results.allSatisfy({ $0.count != 0 && $0 == results.first }))
  }

  @Test func test_multipleLines() async {
    await JobManager.default.do("Multiple Lines", jobID: "\(#function)") { context in
      context.view(
        message: """
        Line 1
        Line 2
        Line 3
        Line 4
        """
      )
    }
  }
}
