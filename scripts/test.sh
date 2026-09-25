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

python3 -m unittest discover -s Tests/Release

# 使用真实 Sparkle 驱动验证一键安装回调，不生成测试 App。
SPARKLE_FRAMEWORK_DIR="$PWD/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64"
if [ ! -d "$SPARKLE_FRAMEWORK_DIR/Sparkle.framework" ]; then
  swift package resolve
fi
UPDATE_TEST_BIN="$(mktemp -t markdown-update-tests)"
trap 'rm -f "$TEST_BIN" "$PREVIEW_TEST_BIN" "$SYNTAX_TEST_BIN" "$FOCUS_TEST_BIN" "$ICON_TEST_BIN" "$UPDATE_TEST_BIN"' EXIT
swiftc -F "$SPARKLE_FRAMEWORK_DIR" -framework Sparkle -Xlinker -rpath -Xlinker "$SPARKLE_FRAMEWORK_DIR" Sources/Markdown/UpdateRetryPolicy.swift Sources/Markdown/AppUpdater.swift Tests/Update/main.swift -o "$UPDATE_TEST_BIN"
"$UPDATE_TEST_BIN" "$PWD/Markdown.app"
