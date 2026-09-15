import Foundation
import XCTest
import XCResultKit
@testable import CodeCoverageLib

final class CodeCoverageRunnerTests: XCTestCase {
    func testRunnerUsesInjectedDependencies() throws {
        let output = MockResultOutput()
        let runner = CodeCoverageRunner(
            coverageSourceFactory: StubCoverageSourceFactory(coverageData: makeCoverageData()),
            localData: StubLocalData(),
            output: output
        )

        try runner.run(xcresultFile: "result.xcresult", configYamlFile: nil, useAnsiColors: false)

        XCTAssertEqual(output.results.count, 1)
        XCTAssertTrue(output.results[0].contains("Example"))
        XCTAssertFalse(output.results[0].contains("\u{001B}["))
    }

    func testRunnerReportsInvalidConfiguration() {
        let output = MockResultOutput()
        let runner = CodeCoverageRunner(
            coverageSourceFactory: StubCoverageSourceFactory(coverageData: makeCoverageData()),
            localData: StubLocalData(files: ["config.yml": Data("minCoverage: 101".utf8)]),
            output: output
        )

        XCTAssertThrowsError(
            try runner.run(xcresultFile: "result.xcresult", configYamlFile: "config.yml", useAnsiColors: false)
        )
        XCTAssertTrue(output.results.isEmpty)
    }
}

private extension CodeCoverageRunnerTests {
    func makeCoverageData() -> CoverageData {
        CoverageData(targets: [
            CodeCoverageTarget(name: "Example", buildProductPath: "", files: [
                CodeCoverageFile(
                    coveredLines: 10,
                    lineCoverage: 1,
                    path: "Sources/Example.swift",
                    name: "Example.swift",
                    executableLines: 10,
                    functions: []
                )
            ])
        ])
    }
}

private struct StubCoverageSourceFactory: CoverageSourceFactory {
    let coverageData: CoverageData?

    func create(url: URL) -> any CoverageSource {
        StubCoverageSource(coverageData: coverageData)
    }
}

private struct StubCoverageSource: CoverageSource {
    let coverageData: CoverageData?

    func getCodeCoverage() -> CoverageData? {
        coverageData
    }
}

private struct StubLocalData: LocalData {
    let files: [String: Data]

    init(files: [String: Data] = [:]) {
        self.files = files
    }

    func fileExists(atPath path: String) -> Bool {
        files[path] != nil
    }

    func loadFileData(from path: String) throws -> Data {
        guard let file = files[path] else {
            throw CocoaError(.fileNoSuchFile)
        }
        return file
    }
}
