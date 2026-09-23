#!/bin/bash
# 一键构建：生成资源 → 编译 → 组装 → 签名验证 → 更新仓库根目录 App。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="Markdown"
BIN="$ROOT/.build/release/$APP_NAME"
REPO_APP="$ROOT/$APP_NAME.app"

echo "==> 1/6 生成内嵌资源 (Assets.swift)"
swift scripts/gen_assets.swift

echo "==> 2/6 编译 (release, arm64)"
swift build -c release --arch arm64

echo "==> 3/6 生成图标与示例图片"
swift scripts/make_assets.swift
if command -v iconutil >/dev/null 2>&1; then
  iconutil -c icns "$ROOT/dist/Markdown.iconset" -o "$ROOT/dist/Markdown.icns"
else
  echo "  跳过 icns（无 iconutil）"
fi

echo "==> 4/6 组装 Markdown.app"
rm -rf "$REPO_APP"
mkdir -p "$REPO_APP/Contents/MacOS" "$REPO_APP/Contents/Resources"
cp "$BIN" "$REPO_APP/Contents/MacOS/$APP_NAME"

cat > "$REPO_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Markdown</string>
  <key>CFBundleDisplayName</key><string>Markdown</string>
  <key>CFBundleIdentifier</key><string>com.tony.markdown</string>
  <key>CFBundleExecutable</key><string>Markdown</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.1.0</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>LSMultipleInstancesProhibited</key><true/>
  <key>NSHumanReadableCopyright</key><string>仅供个人使用</string>
  <key>UTExportedTypeDeclarations</key>
  <array>
    <dict>
      <key>UTTypeIdentifier</key><string>net.daringfireball.markdown</string>
      <key>UTTypeDescription</key><string>Markdown</string>
      <key>UTTypeConformsTo</key><array><string>public.plain-text</string></array>
      <key>UTTypeTagSpecification</key>
      <dict>
        <key>public.filename-extension</key>
        <array><string>md</string><string>markdown</string><string>mkd</string><string>mdown</string></array>
      </dict>
    </dict>
  </array>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key><string>Markdown Document</string>
      <key>CFBundleTypeRole</key><string>Editor</string>
      <key>LSHandlerRank</key><string>Owner</string>
      <key>LSItemContentTypes</key><array><string>net.daringfireball.markdown</string></array>
    </dict>
  </array>
</dict>
</plist>
PLIST

printf 'APPL????' > "$REPO_APP/Contents/PkgInfo"

if [ -f "$ROOT/dist/Markdown.icns" ]; then
  cp "$ROOT/dist/Markdown.icns" "$REPO_APP/Contents/Resources/AppIcon.icns"
fi

echo "==> 5/6 ad-hoc 签名（无需开发者账号）"
codesign --force --deep -s - "$REPO_APP" 2>/dev/null || codesign --force -s - "$REPO_APP"

# 直接验证唯一的根目录产物，不在 dist、临时目录或桌面组装 App。
echo "==> 6/6 验证仓库根目录 App"
codesign --verify --deep --strict "$REPO_APP"

echo ""
echo "完成。"
echo "  仓库 App: $REPO_APP"
echo "  示例:     $ROOT/Markdown示例.md"
echo "  示例图片: $ROOT/dist/sample.png"
