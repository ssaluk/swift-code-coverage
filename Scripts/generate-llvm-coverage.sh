#!/usr/bin/env bash

# Generates LLVM coverage JSON, including branch records when the active Swift
# toolchain emits them. The output is a sibling artifact to an .xcresult; it
# does not modify Xcode's result bundle.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
output_path="${1:-$project_dir/coverage/llvm-coverage.json}"

cd "$project_dir"

swift test --enable-code-coverage
coverage_json_path="$(swift test --enable-code-coverage --show-codecov-path)"

if [[ ! -f "$coverage_json_path" ]]; then
    echo "LLVM coverage JSON was not generated at: $coverage_json_path" >&2
    exit 1
fi

mkdir -p "$(dirname "$output_path")"
cp "$coverage_json_path" "$output_path"

echo "LLVM coverage JSON written to: $output_path"
