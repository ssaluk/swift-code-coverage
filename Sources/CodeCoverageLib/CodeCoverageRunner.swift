import Foundation
import ArgumentParser
import XCResultKit
import Yams

public struct CodeCoverageRunner {
    private let coverageSourceFactory: any CoverageSourceFactory
    private let localData: any LocalData
    private let output: any ResultOutput
    private let coverageFormatterFactory: (Bool) -> any CoverageFormatter

    public init() {
        coverageSourceFactory = DefaultCoverageSourceFactory()
        localData = DefaultLocalData()
        output = DefaultResultOutput()
        coverageFormatterFactory = { DefaultCoverageFormatter(useAnsiColors: $0) }
    }

    init(
        coverageSourceFactory: any CoverageSourceFactory,
        localData: any LocalData,
        output: any ResultOutput,
        coverageFormatterFactory: @escaping (Bool) -> any CoverageFormatter = { DefaultCoverageFormatter(useAnsiColors: $0) }
    ) {
        self.coverageSourceFactory = coverageSourceFactory
        self.localData = localData
        self.output = output
        self.coverageFormatterFactory = coverageFormatterFactory
    }

    public func run(xcresultFile: String, configYamlFile: String?, useAnsiColors: Bool) throws {
        var configYamlFile: String? = configYamlFile
        let xcresultURL = URL(fileURLWithPath: xcresultFile)
        let resultFile = coverageSourceFactory.create(url: xcresultURL)

        let localConfigYamlFile = "./.swiftcoverage.yml"
        if configYamlFile == nil && localData.fileExists(atPath: localConfigYamlFile) {
            configYamlFile = localConfigYamlFile
        }

        let config = if let configYamlFile {
            try YAMLDecoder().decode(
                CoverageConfiguration.self,
                from: localData.loadFileData(from: configYamlFile)
            )
        } else {
            CoverageConfiguration()
        }

        let coverageFilter: CoverageConfiguration.Filter
        do {
            coverageFilter = try config.getCoverageFilter()
        } catch {
            throw ValidationError("Invalid coverage configuration: \(error.localizedDescription)")
        }

        guard let codeCoverage = resultFile.getCodeCoverage() else {
            throw ValidationError("No coverage information found in xcresult")
        }

        let targetsCoverage = TargetsCoverage(codeCoverage: codeCoverage, coverageFilter: coverageFilter)

        let coverageFormatter = coverageFormatterFactory(useAnsiColors)
        output.print(coverageFormatter.format(targetsCoverage, minCoverage: config.minCoverage))

        let targetsWithLowCoverage = targetsCoverage.targetsWithLowCoverage(minCoverage: config.minCoverage)
        if targetsWithLowCoverage.isEmpty {
            return
        }

        let lowCoverageMessage = String(format: "\nLOW COVERAGE: \(targetsWithLowCoverage.count) of \(targetsCoverage.targets.count) targets have coverage lower than min coverage %d%%.\nTotal coverage is %.1f%%\n", config.minCoverage, targetsCoverage.coverage)
        output.print(useAnsiColors ? lowCoverageMessage.color(.yellowText) : lowCoverageMessage)

        throw ExitCode(1)
    }
}
