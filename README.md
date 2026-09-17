# swift-code-coverage
Simple code coverage tool to filter and dump the code coverage collected from Xcode xcresult file.
You can use coverage rules file to control which targets or individual files are included or excluded.

## Usage
    USAGE: codecoverage --xcresult-file <xcresult-file> [--config-yaml-file <config-yaml-file>] [--no-color]

    OPTIONS:
      --xcresult-file <xcresult-file>
                              The path to the .xcresult file.
      --config-yaml-file <config-yaml-file>
                              The path to optional configuration YAML file.
      --no-color              Disable ANSI-coloured output.
      -h, --help              Show help information.

## Sample

Sample `.swiftcoverage.yml`

        include:
          targets: 
            - SomeProduct(.*)+

        exclude:
          targets: 
            - Pods_(.*)+
            - xctest
            - Tests

          files:
            - ViewController
            - Coordinator
            - Container
            - Mock
            - mock
            - UI(.*).swift
            - Cell\.swift
            - View\.swift
            - Field\.swift
            - Label\.swift
            - Picker\.swift


        minCoverage: 85

To calculate Sonar-style combined line and branch coverage, provide the LLVM
coverage JSON along with the `.xcresult` target mapping:

```sh
codecoverage --xcresult-file Tests.xcresult \
  --llvm-coverage-file coverage/llvm-coverage.json
```

For matching files, coverage is calculated as `(covered lines + covered branch
outcomes) / (executable lines + branch outcomes)`. Files absent from the LLVM
report retain their `.xcresult` line coverage.

## LLVM branch coverage artifact

For Swift Package Manager builds, generate LLVM coverage JSON with branch data:

```sh
./Scripts/generate-llvm-coverage.sh
```

The script runs the tests with code coverage enabled and writes
`coverage/llvm-coverage.json`. Pass an output path as its first argument to
choose another location. This artifact is separate from an Xcode `.xcresult`:
it cannot be added to or used to enrich the result bundle.
