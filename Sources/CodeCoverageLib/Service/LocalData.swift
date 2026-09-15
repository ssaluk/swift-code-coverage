import Foundation

protocol LocalData {
    func fileExists(atPath path: String) -> Bool
    func loadFileData(from path: String) throws -> Data
}

struct DefaultLocalData: LocalData {
    func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func loadFileData(from path: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: path))
    }
}
