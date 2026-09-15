import Foundation

protocol ResultOutput: AnyObject {
    func print(_ text: String)
    func printError(_ text: String)
}

class DefaultResultOutput: ResultOutput {
    func print(_ text: String) {
        Swift.print(text)
    }

    func printError(_ text: String) {
        var stdErr = StandardError()
        Swift.print(text, to: &stdErr)
    }
}
