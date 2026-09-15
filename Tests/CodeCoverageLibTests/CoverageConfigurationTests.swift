import XCTest
@testable import CodeCoverageLib

final class CodeCoverageTests: XCTestCase {
    func testCoverageConfiguration() throws {
        let coverageConfiguration = makeTestCoverageConfiguration()
        let coverageFilter = try coverageConfiguration.getCoverageFilter()
        XCTAssertFalse(coverageFilter.isTargetIncluded("MyLibrary"))
        XCTAssertFalse(coverageFilter.isTargetIncluded("Pods"))
        XCTAssertFalse(coverageFilter.isTargetIncluded("Tests"))

        XCTAssertFalse(coverageFilter.isTargetIncluded("AnotherMyFrameworkTarget1"))
        XCTAssertTrue(coverageFilter.isTargetIncluded("MyFrameworkTarget1"))

        XCTAssertTrue(coverageFilter.isTargetIncluded("AnotherTarget2"))
        XCTAssertTrue(coverageFilter.isTargetIncluded("YetAnotherTarget"))
        XCTAssertFalse(coverageFilter.isTargetIncluded("AnotherTarget3"))

        XCTAssertFalse(coverageFilter.isTargetIncluded("Tests"))
        XCTAssertFalse(coverageFilter.isTargetIncluded("AllTests"))

        XCTAssertFalse(coverageFilter.isFileIncluded("MyFrameworkTarget1/config.yaml"))
        XCTAssertTrue(coverageFilter.isFileIncluded("MyFrameworkTarget1/ViewModel.swift"))
        XCTAssertFalse(coverageFilter.isFileIncluded("MyFrameworkTarget1/MockViewModel.swift"))
        XCTAssertFalse(coverageFilter.isFileIncluded("MyFrameworkTarget1/UITableViewCustom.swift"))

        XCTAssertFalse(coverageFilter.isFileIncluded("Some/long path/to/MyFramework/Services/some folder/Data+Comparable.swift"))
    }

    func testDefaultCoverageConfiguration() throws {
        let coverageConfiguration = makeTestDefaultCoverageConfiguration()
        let coverageFilter = try coverageConfiguration.getCoverageFilter()
        XCTAssertTrue(coverageFilter.isTargetIncluded("Alpha"))
        XCTAssertTrue(coverageFilter.isTargetIncluded("Bravo"))
        XCTAssertTrue(coverageFilter.isTargetIncluded("Charlie"))
        XCTAssertTrue(coverageFilter.isTargetIncluded("Test"))
        XCTAssertTrue(coverageFilter.isTargetIncluded("Mock"))
        XCTAssertTrue(coverageFilter.isFileIncluded("Alpha/Bravo/Charlie/Delta.swift"))
        XCTAssertTrue(coverageFilter.isFileIncluded("Delta.swift"))
        XCTAssertTrue(coverageFilter.isFileIncluded("DeltaMock.swift"))
    }

    func testMinimumCoverageMustBeAValidPercentage() {
        let coverageConfiguration = CoverageConfiguration(minCoverage: 101)

        XCTAssertThrowsError(try coverageConfiguration.getCoverageFilter()) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "minCoverage must be between 0 and 100 (received 101)"
            )
        }
    }

    func testInvalidRegularExpressionReportsTheExpression() {
        let coverageConfiguration = CoverageConfiguration(
            include: .init(targets: ["["])
        )

        XCTAssertThrowsError(try coverageConfiguration.getCoverageFilter()) { error in
            XCTAssertTrue(error.localizedDescription.contains("Invalid regular expression '['"))
        }
    }
}

private extension CodeCoverageTests {
    func makeTestDefaultCoverageConfiguration() -> CoverageConfiguration {
        CoverageConfiguration()
    }

    func makeTestCoverageConfiguration() -> CoverageConfiguration {
        CoverageConfiguration(
            include: CoverageConfiguration.Include(
                targets: [
                    "^MyFramework(.*)+",
                    "AnotherTarget(.*)+"
                ],
                files: [
                    "(.*).swift"
                ]
            ),
            exclude: CoverageConfiguration.Exclude(
                targets: [
                    "Pods_(.*)+",
                    "Tests",
                    "AnotherTarget3"
                ],
                files: [
                    "UI(.*).swift",
                    "Mock",
                    "(.*)MyFramework/Services/*/(.*)\\+Comparable.swift"
                ]
            ),
            minCoverage: 85
        )
    }
}
