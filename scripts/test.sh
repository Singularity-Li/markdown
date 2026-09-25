#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_BIN="$(mktemp -t markdown-tests)"
PREVIEW_TEST_BIN="$(mktemp -t markdown-preview-tests)"
trap 'rm -f "$TEST_BIN" "$PREVIEW_TEST_BIN"' EXIT
swiftc Sources/Markdown/AppearanceSettings.swift Sources/Markdown/DocumentStore.swift Sources/Markdown/FileNode.swift Tests/main.swift -o "$TEST_BIN"
"$TEST_BIN"

swiftc Sources/Markdown/Assets.swift Sources/Markdown/MarkdownHTML.swift Tests/Preview/main.swift -o "$PREVIEW_TEST_BIN"
"$PREVIEW_TEST_BIN"

SYNTAX_TEST_BIN="$(mktemp -t markdown-syntax-tests)"
trap 'rm -f "$TEST_BIN" "$PREVIEW_TEST_BIN" "$SYNTAX_TEST_BIN"' EXIT
swiftc Sources/Markdown/MarkdownSyntax.swift Tests/Syntax/main.swift -o "$SYNTAX_TEST_BIN"
"$SYNTAX_TEST_BIN"

FOCUS_TEST_BIN="$(mktemp -t markdown-focus-tests)"
trap 'rm -f "$TEST_BIN" "$PREVIEW_TEST_BIN" "$SYNTAX_TEST_BIN" "$FOCUS_TEST_BIN"' EXIT
swiftc Sources/Markdown/FocusedMarkdownWebView.swift Tests/Focus/main.swift -o "$FOCUS_TEST_BIN"
"$FOCUS_TEST_BIN"

ICON_TEST_BIN="$(mktemp -t markdown-icon-tests)"
trap 'rm -f "$TEST_BIN" "$PREVIEW_TEST_BIN" "$SYNTAX_TEST_BIN" "$FOCUS_TEST_BIN" "$ICON_TEST_BIN"' EXIT
swiftc Sources/Markdown/AppIconRefresh.swift Tests/Icon/main.swift -o "$ICON_TEST_BIN"
"$ICON_TEST_BIN"
