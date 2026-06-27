import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(mysql_backup_swiftTests.allTests),
    ]
}
#endif
