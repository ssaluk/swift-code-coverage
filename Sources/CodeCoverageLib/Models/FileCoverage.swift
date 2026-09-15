import Foundation

struct FileCoverage {
    var file: String
    var coverage: Double

    init(file: String, coverage: Double) {
        self.file = file
        self.coverage = coverage
    }
}
