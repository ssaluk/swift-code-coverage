enum Constants {
    static let defaultMinCoverage = 85

    enum Colors {
        static let noCoverage = AnsiColor.redText
        static let lowCoverage = AnsiColor.yellowText
        static let goodCoverage = AnsiColor.greenText
    }
}
