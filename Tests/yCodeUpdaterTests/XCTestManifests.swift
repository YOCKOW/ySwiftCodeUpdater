#if !canImport(ObjectiveC)
import XCTest

extension CSVTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CSVTests = [
        ("test_rows", test_rows),
    ]
}

extension CodeUpdaterManagerTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CodeUpdaterManagerTests = [
        ("test_arguments", test_arguments),
    ]
}

extension CodeUpdaterTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CodeUpdaterTests = [
        ("test_update", test_update),
    ]
}

extension SwiftKeywordsTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SwiftKeywordsTests = [
        ("test_identifier", test_identifier),
        ("test_keywords", test_keywords),
    ]
}

extension TargetFileInfoTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__TargetFileInfoTests = [
        ("test_info", test_info),
    ]
}

extension UnicodeDataTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__UnicodeDataTests = [
        ("test_data", test_data),
        ("test_license", test_license),
        ("test_multipleRanges", test_multipleRanges),
        ("test_rangeDictionary", test_rangeDictionary),
        ("test_split", test_split),
        ("test_url", test_url),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CSVTests.__allTests__CSVTests),
        testCase(CodeUpdaterManagerTests.__allTests__CodeUpdaterManagerTests),
        testCase(CodeUpdaterTests.__allTests__CodeUpdaterTests),
        testCase(SwiftKeywordsTests.__allTests__SwiftKeywordsTests),
        testCase(TargetFileInfoTests.__allTests__TargetFileInfoTests),
        testCase(UnicodeDataTests.__allTests__UnicodeDataTests),
    ]
}
#endif
