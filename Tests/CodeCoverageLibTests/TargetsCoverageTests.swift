import XCTest
import XCResultKit
@testable import CodeCoverageLib

final class TargetsCoverageTests: XCTestCase {
    func testTargetsCoverage() throws {
        let targetsCoverage = TargetsCoverage(
            codeCoverage: makeTestCoverageData(),
            coverageFilter: try CoverageConfiguration().getCoverageFilter()
        )

        XCTAssertEqual(targetsCoverage.targets.map(\.target), ["target1", "target2"])
        XCTAssertEqual(targetsCoverage.targets[0].coverage, 1, accuracy: 0.0001)
        XCTAssertEqual(targetsCoverage.targets[1].coverage, 100, accuracy: 0.0001)
        XCTAssertEqual(targetsCoverage.coverage, 10, accuracy: 0.0001)
        XCTAssertEqual(targetsCoverage.targetsWithLowCoverage(minCoverage: 85).map(\.target), ["target1"])
    }

    func testTargetsWithNoIncludedFilesAreExcluded() throws {
        let configuration = CoverageConfiguration(
            exclude: .init(files: ["Included\\.swift", "Excluded\\.swift"])
        )
        let targetsCoverage = TargetsCoverage(
            codeCoverage: makeTestCoverageData(),
            coverageFilter: try configuration.getCoverageFilter()
        )

        XCTAssertEqual(targetsCoverage.targets.map(\.target), ["target2"])
        XCTAssertEqual(targetsCoverage.coverage, 100, accuracy: 0.0001)
    }
}

private extension TargetsCoverageTests {
    func makeTestCoverageData() -> CoverageData {
        CoverageData(targets: [
            CodeCoverageTarget(name: "target1", buildProductPath: "path1", files: [
                CodeCoverageFile(
                    coveredLines: 1,
                    lineCoverage: 1,
                    path: "Sources/Included.swift",
                    name: "Included.swift",
                    executableLines: 1,
                    functions: []
                ),
                CodeCoverageFile(
                    coveredLines: 0,
                    lineCoverage: 0,
                    path: "Sources/Excluded.swift",
                    name: "Excluded.swift",
                    executableLines: 99,
                    functions: []
                )
            ]),
            CodeCoverageTarget(name: "target2", buildProductPath: "path2", files: [
                CodeCoverageFile(
                    coveredLines: 10,
                    lineCoverage: 1,
                    path: "Sources/Complete.swift",
                    name: "Complete.swift",
                    executableLines: 10,
                    functions: []
                )
            ])
        ])
    }
}
