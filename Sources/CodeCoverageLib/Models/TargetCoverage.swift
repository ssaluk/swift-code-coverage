import Foundation

struct TargetCoverage {
    var target: String
    var coverage: Double
    var filesCoverage: [FileCoverage]

    init(target: String, coverage: Double, filesCoverage: [FileCoverage]) {
        self.target = target
        self.coverage = coverage
        self.filesCoverage = filesCoverage
    }
}
