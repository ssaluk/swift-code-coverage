import XCTest
@testable import CodeCoverageLib

final class FileCoverageTests: XCTestCase {
    func testFileCoverage() {
        let fileCoverage = FileCoverage(file: "file1", coverage: 100)
        XCTAssertEqual(fileCoverage.file, "file1")
        XCTAssertEqual(fileCoverage.coverage, 100)
    }
}
