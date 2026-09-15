import Foundation

// source: https://stackoverflow.com/a/59357395
class StandardError: TextOutputStream {
    func write(_ string: String) {
        try? FileHandle.standardError.write(contentsOf: Data(string.utf8))
    }
}
