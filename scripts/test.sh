#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_BIN="$(mktemp -t markdown-tests)"
trap 'rm -f "$TEST_BIN"' EXIT
swiftc Sources/Markdown/DocumentStore.swift Sources/Markdown/FileNode.swift Tests/main.swift -o "$TEST_BIN"
"$TEST_BIN"
