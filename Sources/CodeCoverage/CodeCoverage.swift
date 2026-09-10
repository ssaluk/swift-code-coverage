import Foundation
import ArgumentParser
import CodeCoverageLib

@main
struct CodeCoverage: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "codecoverage")

    @Option(help: "The path to the .xcresult file.")
    var xcresultFile: String

    @Option(help: "The path to optional configuration YAML file.")
    var configYamlFile: String?

    @Flag(name: .customLong("no-color"), help: "Disable ANSI-coloured output")
    var noColor = false

    mutating func run() throws {
        try CodeCoverageRunner().run(
            xcresultFile: xcresultFile,
            configYamlFile: configYamlFile,
            useAnsiColors: !noColor
        )
    }
}
