#!/bin/bash
# 一键构建：生成资源 → 编译 → 组装 → 签名验证 → 更新仓库根目录及桌面 App。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="Markdown"
BIN="$ROOT/.build/release/$APP_NAME"
DIST="$ROOT/dist/$APP_NAME.app"
REPO_APP="$ROOT/$APP_NAME.app"
DEPLOY_DESKTOP="${DEPLOY_DESKTOP:-1}"

echo "==> 1/7 生成内嵌资源 (Assets.swift)"
swift scripts/gen_assets.swift

echo "==> 2/7 编译 (release, arm64)"
swift build -c release --arch arm64

echo "==> 3/7 生成图标与示例图片"
swift scripts/make_assets.swift
if command -v iconutil >/dev/null 2>&1; then
  iconutil -c icns "$ROOT/dist/Markdown.iconset" -o "$ROOT/dist/Markdown.icns"
else
  echo "  跳过 icns（无 iconutil）"
fi

echo "==> 4/7 组装 Markdown.app"
rm -rf "$DIST"
mkdir -p "$DIST/Contents/MacOS" "$DIST/Contents/Resources"
cp "$BIN" "$DIST/Contents/MacOS/$APP_NAME"

cat > "$DIST/Contents/Info.plist" <<'PLIST'
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

printf 'APPL????' > "$DIST/Contents/PkgInfo"

if [ -f "$ROOT/dist/Markdown.icns" ]; then
  cp "$ROOT/dist/Markdown.icns" "$DIST/Contents/Resources/AppIcon.icns"
fi

echo "==> 5/7 ad-hoc 签名（无需开发者账号）"
codesign --force --deep -s - "$DIST" 2>/dev/null || codesign --force -s - "$DIST"

# 验证新产物成功后才替换现有版本，避免残留旧 bundle 文件。
codesign --verify --deep --strict "$DIST"
echo "==> 6/7 更新仓库根目录 App"
rm -rf "$REPO_APP"
ditto "$DIST" "$REPO_APP"

if [ "$DEPLOY_DESKTOP" = "1" ]; then
  rm -rf "$HOME/Desktop/$APP_NAME.app"
  ditto "$DIST" "$HOME/Desktop/$APP_NAME.app"
  # 示例文件可能已被用户编辑，不覆盖已有文件。
  [ -e "$HOME/Desktop/sample.png" ] || cp "$ROOT/dist/sample.png" "$HOME/Desktop/sample.png"
  [ -e "$HOME/Desktop/Markdown示例.md" ] || cp "$ROOT/Markdown示例.md" "$HOME/Desktop/Markdown示例.md"

  codesign --verify --deep --strict "$HOME/Desktop/$APP_NAME.app"
fi

echo "==> 7/7 验证仓库根目录 App"
codesign --verify --deep --strict "$REPO_APP"

echo ""
echo "完成。"
echo "  仓库 App: $REPO_APP"
if [ "$DEPLOY_DESKTOP" = "1" ]; then
  echo "  桌面 App: $HOME/Desktop/$APP_NAME.app"
fi
echo "  示例:     $HOME/Desktop/Markdown示例.md"
echo "  示例图片: $HOME/Desktop/sample.png"