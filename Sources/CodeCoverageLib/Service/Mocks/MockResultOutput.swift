import Foundation

class MockResultOutput: ResultOutput {
    var results: [String] = []
    var errors: [String] = []

    func print(_ text: String) {
        results.append(text)
    }

    func printError(_ text: String) {
        errors.append(text)
    }
}
