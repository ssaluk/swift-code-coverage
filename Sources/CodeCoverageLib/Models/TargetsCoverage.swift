import Foundation
import XCResultKit

struct TargetsCoverage {
    var targets: [TargetCoverage]
    var coverage: Double
}

private struct CoverageMetrics {
    var coveredLines = 0
    var executableLines = 0
    var coveredBranchOutcomes = 0
    var branchOutcomes = 0

    mutating func include(_ file: CodeCoverageFile, llvmMetrics: LLVMCoverage.Metrics?) {
        if let llvmMetrics {
            coveredLines += llvmMetrics.coveredLines
            executableLines += llvmMetrics.executableLines
            coveredBranchOutcomes += llvmMetrics.coveredBranchOutcomes
            branchOutcomes += llvmMetrics.branchOutcomes
        } else {
            coveredLines += file.coveredLines
            executableLines += file.executableLines
        }
    }

    var percentage: Double {
        let totalOutcomes = executableLines + branchOutcomes
        return totalOutcomes > 0
            ? 100 * Double(coveredLines + coveredBranchOutcomes) / Double(totalOutcomes)
            : 0
    }
}

extension TargetsCoverage {
    func checkCoverage(_ minCoverage: Int) -> Bool {
        targets.allSatisfy({ $0.coverage >= Double(minCoverage) })
    }

    init(
        codeCoverage: CoverageData,
        coverageFilter: CoverageConfiguration.Filter,
        llvmCoverage: LLVMCoverage? = nil
    ) {
        var targetCoverages: [TargetCoverage] = []
        var totalMetrics = CoverageMetrics()

        for target in codeCoverage.targets where coverageFilter.isTargetIncluded(target.name) {
            var fileCoverages: [FileCoverage] = []
            var targetMetrics = CoverageMetrics()

            for file in target.files where coverageFilter.isFileIncluded(file.path) {
                let llvmMetrics = llvmCoverage?.metrics(for: file.path)
                var fileMetrics = CoverageMetrics()
                fileMetrics.include(file, llvmMetrics: llvmMetrics)
                let fileCoverage = fileMetrics.percentage
                fileCoverages.append(FileCoverage(file: file.name, coverage: fileCoverage))
                targetMetrics.include(file, llvmMetrics: llvmMetrics)
            }

            // A target with no remaining files has been fully filtered out and
            // must not affect the displayed total or the threshold result.
            guard !fileCoverages.isEmpty else {
                continue
            }

            let targetCoverage = targetMetrics.percentage
            targetCoverages.append(TargetCoverage(target: target.name, coverage: targetCoverage, filesCoverage: fileCoverages))
            totalMetrics.coveredLines += targetMetrics.coveredLines
            totalMetrics.executableLines += targetMetrics.executableLines
            totalMetrics.coveredBranchOutcomes += targetMetrics.coveredBranchOutcomes
            totalMetrics.branchOutcomes += targetMetrics.branchOutcomes
        }

        let totalCoverage = totalMetrics.percentage

        self.targets = targetCoverages
        self.coverage = totalCoverage
    }

    func targetsWithLowCoverage(minCoverage: Int) -> [TargetCoverage] {
        targets.filter({ $0.coverage < Double(minCoverage) })
    }
}
