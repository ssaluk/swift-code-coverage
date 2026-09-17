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

    func testLLVMEnrichmentUsesSonarStyleLineAndBranchCoverage() throws {
        let coverageData = CoverageData(targets: [
            CodeCoverageTarget(name: "target1", buildProductPath: "path1", files: [
                makeFile(path: "/project/Sources/Feature.swift", name: "Feature.swift")
            ]),
            CodeCoverageTarget(name: "target2", buildProductPath: "path2", files: [
                makeFile(path: "/project/Sources/Complete.swift", name: "Complete.swift")
            ])
        ])
        let llvmCoverage = try LLVMCoverage(data: Data("""
        {"data":[{"files":[
          {"filename":"/project/Sources/Feature.swift","summary":{"lines":{"count":100,"covered":80},"branches":{"count":2,"covered":1}}},
          {"filename":"/project/Sources/Complete.swift","summary":{"lines":{"count":1,"covered":1},"branches":{"count":0,"covered":0}}}
        ]}]}
        """.utf8))

        let targetsCoverage = TargetsCoverage(
            codeCoverage: coverageData,
            coverageFilter: try CoverageConfiguration().getCoverageFilter(),
            llvmCoverage: llvmCoverage
        )

        XCTAssertEqual(targetsCoverage.targets[0].coverage, 100 * 81.0 / 102.0, accuracy: 0.0001)
        XCTAssertEqual(targetsCoverage.targets[1].coverage, 100, accuracy: 0.0001)
        XCTAssertEqual(targetsCoverage.coverage, 100 * 82.0 / 103.0, accuracy: 0.0001)
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

    func makeFile(path: String, name: String) -> CodeCoverageFile {
        CodeCoverageFile(
            coveredLines: 0,
            lineCoverage: 0,
            path: path,
            name: name,
            executableLines: 1,
            functions: []
        )
    }
}
