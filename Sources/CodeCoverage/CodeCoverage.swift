import ArgumentParser
import XCResultKit
import Foundation
import Yams
import SwiftyTextTable

struct CoverageConfiguration: Codable {
    struct Include: Codable {
        var targets: [String]?
        var files: [String]?
    }

    struct Exclude: Codable {
        var targets: [String]?
        var files: [String]?
    }

    var include: Include?
    var exclude: Exclude?

    var minCoverage: Int = 85
}

protocol Matcher {
    func callAsFunction(_ text: String) -> Bool
}

struct MatchAlways: Matcher {
    func callAsFunction(_ text: String) -> Bool {
        return true
    }
}

struct MatchNever: Matcher {
    func callAsFunction(_ text: String) -> Bool {
        return false
    }
}

struct ElementsMatcher: Matcher {
    var expressions: [NSRegularExpression]

    init(elements: [String]) throws {
        self.expressions = try elements
            .map { try NSRegularExpression(pattern: $0) }
    }

    func callAsFunction(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expressions.first(where: {
            $0.rangeOfFirstMatch(in: text, range: range).location != NSNotFound
        }) != nil
    }
}

struct CoverageState {
    var count = Double(0)
    var percentage = Double(0)

    var coverage: Double {
        count > 0 ? Double(percentage) / Double(count) : 0
    }
}

struct TargetCoverage {
    var target: String
    var coverage: Double
    var files: [FileCoverage]
}

struct FileCoverage {
    var file: String
    var coverage: Double

    init(file: String, coverage: Double) {
        self.file = file
        self.coverage = coverage
    }
}

@main
struct CodeCoverage: ParsableCommand {
    @Option(help: "The path to the .xcresult file.")
    var xcresultFile: String

    @Option(help: "The path to optional configuration YAML file.")
    var configYamlFile: String?

    mutating func run() throws {
        let xcresultURL = URL(fileURLWithPath: xcresultFile)
        let resultFile = XCResultFile(url: xcresultURL)

        var config = CoverageConfiguration()

        var includeTargets: Matcher = MatchAlways()
        var excludeTargets: Matcher = MatchNever()
        var includeFiles: Matcher = MatchAlways()
        var excludeFiles: Matcher = MatchNever()

        let localConfigYamlFile = "./.swiftcoverage.yml"
        if configYamlFile == nil && FileManager.default.fileExists(atPath: localConfigYamlFile) {
            configYamlFile = localConfigYamlFile
        }

        if let configYamlFile {
            let configYamlData = try Data(contentsOf: URL(fileURLWithPath: configYamlFile))
            config = try YAMLDecoder().decode(CoverageConfiguration.self, from: configYamlData)

            if let include = config.include {
                if let includedTargets = include.targets, !includedTargets.isEmpty {
                    includeTargets = try ElementsMatcher(elements: includedTargets)
                }
                if let includedFiles = include.files, !includedFiles.isEmpty {
                    includeFiles = try ElementsMatcher(elements: includedFiles)
                }
            }

            if let exclude = config.exclude {
                if let excludedTargets = exclude.targets, !excludedTargets.isEmpty {
                    excludeTargets = try ElementsMatcher(elements: excludedTargets)
                }
                if let excludedFiles = exclude.files, !excludedFiles.isEmpty {
                    excludeFiles = try ElementsMatcher(elements: excludedFiles)
                }
            }
        }

        guard let codeCoverage = resultFile.getCodeCoverage() else {
            throw ValidationError("No coverage information found in xcresult")
        }

        var targetsCoverage: [TargetCoverage] = []
        var targetsTotal: Double = 0
        var targetsCount = 0

        for target in codeCoverage.targets {
            if !includeTargets(target.name) || excludeTargets(target.name) {
                continue
            }

            var fileCoverage: [FileCoverage] = []
            var filesTotal: Double = 0
            var filesCount = 0

            for file in target.files {
                if !includeFiles(file.path) || excludeFiles(file.path) {
                    continue
                }

                let lineCoverage = 100 * file.lineCoverage
                fileCoverage.append(.init(file: file.name, coverage: lineCoverage))
                filesTotal += lineCoverage
                filesCount += 1
            }

            let coverage = filesCount > 0 ? filesTotal / Double(filesCount) : 0
            targetsCoverage.append(.init(target: target.name, coverage: coverage, files: fileCoverage))
            targetsTotal += coverage
            targetsCount += 1
        }

        let totalCoverage = targetsCount > 0 ? targetsTotal / Double(targetsCount) : 0

        let fileNameColumn = TextTableColumn(header: "File")
        let fileCoverageColumn = TextTableColumn(header: "Coverage, %")

        for targetCoverage in targetsCoverage {
            var targetTable = TextTable(columns: [fileNameColumn, fileCoverageColumn])
            targetTable.header = targetCoverage.target
            let sortedFiles = targetCoverage.files.sorted(by: { $0.file < $1.file })
            let coverageRows = sortedFiles.map {
                coverageRow($0.file, coverage: $0.coverage, minCoverage: config.minCoverage)
            }
            targetTable.addRows(values: coverageRows)
            targetTable.addRow(values: ["", ""])
            targetTable.addRow(values: coverageRow("TOTAL:", coverage: targetCoverage.coverage,
                                                   minCoverage: config.minCoverage))
            print(targetTable.render())
        }

        let targetColumn = TextTableColumn(header: "Target")
        var totalCoverageTable = TextTable(columns: [targetColumn, fileCoverageColumn])
        totalCoverageTable.header = "Coverage by targets"
        let coverageRows = targetsCoverage.map {
            coverageRow($0.target, coverage: $0.coverage, minCoverage: config.minCoverage)
        }
        totalCoverageTable.addRows(values: coverageRows)
        totalCoverageTable.addRow(values: ["", ""])
        totalCoverageTable.addRow(values: coverageRow("TOTAL:", coverage: totalCoverage,
                                                      minCoverage: config.minCoverage))
        print(totalCoverageTable.render())

        if  totalCoverage < Double(config.minCoverage) {
            print(String(format: "\nFAIL: Current coverage %.1f%% is less than min %d%%", totalCoverage, config.minCoverage).color(.redText))
            throw ExitCode(1)
        }
    }
}

private extension CodeCoverage {
    func coverageRow(_ title: String, coverage: Double, minCoverage: Int) -> [String] {
        let coverageText = [
            title,
            coverage.isZero ?  "-" : String(format: "%.1f", coverage)
        ]

        if coverage.isZero {
            return coverageText.map { $0.color(.redText) }
        } else if coverage < Double(minCoverage) {
            return coverageText.map { $0.color(.yellowText) }
        } else {
            return coverageText.map { $0.color(.greenText) }
        }
    }
}
