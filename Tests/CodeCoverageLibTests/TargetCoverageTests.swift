import XCTest
@testable import CodeCoverageLib

final class TargetCoverageTests: XCTestCase {
    func testTargetCoverage() {
        let targetCoverage = TargetCoverage(target: "target1", coverage: 85, filesCoverage: [FileCoverage(file: "file1", coverage: 85)])
        XCTAssertEqual(targetCoverage.target, "target1")
        XCTAssertEqual(targetCoverage.coverage, 85)
        XCTAssertEqual(targetCoverage.filesCoverage[0].file, "file1")
        XCTAssertEqual(targetCoverage.filesCoverage[0].coverage, 85)
    }
}
