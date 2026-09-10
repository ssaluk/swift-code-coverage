import Foundation

struct CoverageConfiguration: Codable, Equatable {
    struct Include: Codable, Equatable {
        var targets: [String]?
        var files: [String]?
    }

    struct Exclude: Codable, Equatable {
        var targets: [String]?
        var files: [String]?
    }

    var include: Include?
    var exclude: Exclude?
    var minCoverage: Int

    init(
        include: CoverageConfiguration.Include? = nil,
        exclude: CoverageConfiguration.Exclude? = nil,
        minCoverage: Int = Constants.defaultMinCoverage
    ) {
        self.include = include
        self.exclude = exclude
        self.minCoverage = minCoverage
    }
}

extension CoverageConfiguration {
    enum ValidationError: LocalizedError {
        case invalidMinimumCoverage(Int)

        var errorDescription: String? {
            switch self {
            case let .invalidMinimumCoverage(value):
                "minCoverage must be between 0 and 100 (received \(value))"
            }
        }
    }

    struct Filter {
        fileprivate var matchesIncludedTargets: any Matcher = MatchAlways()
        fileprivate var matchesExcludedTargets: any Matcher = MatchNever()
        fileprivate var matchesIncludedFiles: any Matcher = MatchAlways()
        fileprivate var matchesExcludedFiles: any Matcher = MatchNever()

        func isTargetIncluded(_ targetName: String) -> Bool {
            matchesIncludedTargets(targetName) && !matchesExcludedTargets(targetName)
        }

        func isFileIncluded(_ fileName: String) -> Bool {
            matchesIncludedFiles(fileName) && !matchesExcludedFiles(fileName)
        }
    }

    func getCoverageFilter() throws -> Filter {
        guard (0...100).contains(minCoverage) else {
            throw ValidationError.invalidMinimumCoverage(minCoverage)
        }

        var filter = Filter()
        if let include {
            if let includedTargets = include.targets, !includedTargets.isEmpty {
                filter.matchesIncludedTargets = try ElementsMatcher(elements: includedTargets)
            }
            if let includedFiles = include.files, !includedFiles.isEmpty {
                filter.matchesIncludedFiles = try ElementsMatcher(elements: includedFiles)
            }
        }

        if let exclude {
            if let excludedTargets = exclude.targets, !excludedTargets.isEmpty {
                filter.matchesExcludedTargets = try ElementsMatcher(elements: excludedTargets)
            }
            if let excludedFiles = exclude.files, !excludedFiles.isEmpty {
                filter.matchesExcludedFiles = try ElementsMatcher(elements: excludedFiles)
            }
        }
        return filter
    }
}
