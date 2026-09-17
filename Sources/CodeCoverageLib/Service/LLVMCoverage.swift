import Foundation

/// Coverage exported by `llvm-cov export` / `swift test --enable-code-coverage`.
/// LLVM reports branch *outcomes*, which are the conditions used by Sonar's
/// combined coverage formula.
struct LLVMCoverage {
    struct Metrics {
        let coveredLines: Int
        let executableLines: Int
        let coveredBranchOutcomes: Int
        let branchOutcomes: Int
    }

    private let metricsByPath: [String: Metrics]

    init(data: Data) throws {
        let report = try JSONDecoder().decode(Report.self, from: data)
        var metricsByPath: [String: Metrics] = [:]

        for file in report.data.flatMap(\.files) {
            metricsByPath[Self.normalizedPath(file.filename)] = Metrics(
                coveredLines: file.summary.lines.covered,
                executableLines: file.summary.lines.count,
                coveredBranchOutcomes: file.summary.branches.covered,
                branchOutcomes: file.summary.branches.count
            )
        }

        self.metricsByPath = metricsByPath
    }

    func metrics(for path: String) -> Metrics? {
        metricsByPath[Self.normalizedPath(path)]
    }

    private static func normalizedPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }
}

private extension LLVMCoverage {
    struct Report: Decodable {
        let data: [Export]
    }

    struct Export: Decodable {
        let files: [File]
    }

    struct File: Decodable {
        let filename: String
        let summary: Summary
    }

    struct Summary: Decodable {
        let lines: Count
        let branches: Count
    }

    struct Count: Decodable {
        let count: Int
        let covered: Int
    }
}
