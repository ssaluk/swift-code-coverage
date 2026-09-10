import Foundation
import SwiftyTextTable

protocol CoverageFormatter {
    func format(_ targetsCoverage: TargetsCoverage, minCoverage: Int) -> String
}

struct DefaultCoverageFormatter: CoverageFormatter {
    var useAnsiColors: Bool

    init(useAnsiColors: Bool = true) {
        self.useAnsiColors = useAnsiColors
    }

    func format(_ targetsCoverage: TargetsCoverage, minCoverage: Int) -> String {
        var result = ""

        let fileNameColumn = TextTableColumn(header: "File")
        let fileCoverageColumn = TextTableColumn(header: "Coverage, %")

        for targetCoverage in targetsCoverage.targets {
            var targetTable = TextTable(columns: [fileNameColumn, fileCoverageColumn])
            targetTable.header = targetCoverage.target
            let sortedFilesCoverage = targetCoverage.filesCoverage.sorted(by: { $0.file < $1.file })
            let coverageRows = sortedFilesCoverage.map {
                createRow($0.file, coverage: $0.coverage, minCoverage: minCoverage)
            }
            
            targetTable.addRows(values: coverageRows)
            targetTable.addRow(values: emptyRow)
            targetTable.addRow(values: createRow("TOTAL:", coverage: targetCoverage.coverage, minCoverage: minCoverage))
            result += targetTable.render()
            result += "\n\n"
        }

        let targetColumn = TextTableColumn(header: "Target")
        var totalCoverageTable = TextTable(columns: [targetColumn, fileCoverageColumn])
        totalCoverageTable.header = "Coverage by targets"
        let coverageRows = targetsCoverage.targets.map {
            createRow($0.target, coverage: $0.coverage, minCoverage: minCoverage)
        }

        totalCoverageTable.addRows(values: coverageRows)
        totalCoverageTable.addRow(values: emptyRow)
        totalCoverageTable.addRow(values: createRow("TOTAL:", coverage: targetsCoverage.coverage, minCoverage: minCoverage))
        result += totalCoverageTable.render()

        return result
    }
}

private extension DefaultCoverageFormatter {
    var emptyRow: [String] {
        ["", ""]
    }

    func createRow(_ title: String, coverage: Double, minCoverage: Int) -> [String] {
        let coverageText = [
            title,
            coverage.isZero
                ?  "-"
                : String(format: "%.1f", coverage)
        ]

        let color = if coverage.isZero {
            Constants.Colors.noCoverage
        } else if coverage < Double(minCoverage) {
            Constants.Colors.lowCoverage
        } else {
            Constants.Colors.goodCoverage
        }

        return useAnsiColors
            ? coverageText.map { $0.color(color) }
            : coverageText
    }
}
