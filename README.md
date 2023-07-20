# swift-code-coverage
Simple code coverage tool to filter and dump the code coverage collected from Xcode xcresult file

## Usage
    USAGE: code-coverage --xcresult-file <xcresult-file> [--config-yaml-file <config-yaml-file>]

    OPTIONS:
      --xcresult-file <xcresult-file>
                              The path to the .xcresult file.
      --config-yaml-file <config-yaml-file>
                              The path to optional configuration YAML file.
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
