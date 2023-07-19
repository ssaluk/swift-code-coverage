// The Swift Programming Language
// https://docs.swift.org/swift-book

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

    var minCoverage: Double = 85
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
        let totalCoverageMessage = String(format: "Total coverage: %.1f%%", totalCoverage)
        print(totalCoverageMessage)

        let fileNameColumn = TextTableColumn(header: "File")
        let fileCoverageColumn = TextTableColumn(header: "Coverage, %")

        for targetCoverage in targetsCoverage {
            var targetTable = TextTable(columns: [fileNameColumn, fileCoverageColumn])
            targetTable.header = targetCoverage.target
            let sortedFiles = targetCoverage.files.sorted(by: { $0.file < $1.file })
            for fileCoverage in sortedFiles {
                targetTable.addRow(values: [
                    fileCoverage.file,
                    fileCoverage.coverage > 0 ? String(format: "%.1f", fileCoverage.coverage) : "-"
                ])
            }
            targetTable.addRow(values: ["", ""])
            targetTable.addRow(values: [
                "TOTAL:",
                String(format: "%.1f", targetCoverage.coverage)
            ])
            print(targetTable.render())
        }

        if totalCoverage < config.minCoverage {
            print(String(format: "FAIL: Current coverage %.1f%% is less than min %.1f%%", totalCoverage, config.minCoverage))
            throw ExitCode(1)
        }
    }
}