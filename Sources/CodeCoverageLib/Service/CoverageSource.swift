import Foundation
import XCResultKit

typealias CoverageData = XCResultKit.CodeCoverage
protocol CoverageSource {
    func getCodeCoverage() -> CoverageData?
}

protocol CoverageSourceFactory {
    func create(url: URL) -> any CoverageSource
}

struct DefaultCoverageSourceFactory: CoverageSourceFactory {
    func create(url: URL) -> any CoverageSource {
        XCResultCoverageSource(xcResultURL: url)
    }
}

struct XCResultCoverageSource: CoverageSource {
    private var xcResultFile: XCResultFile

    init(xcResultURL: URL) {
        xcResultFile = XCResultFile(url: xcResultURL)
    }

    func getCodeCoverage() -> CoverageData? {
        xcResultFile.getCodeCoverage()
    }
}
