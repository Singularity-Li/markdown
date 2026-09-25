#!/usr/bin/env python3
"""检查实际交付包的自动更新配置，无需启动或复制 App。"""
import base64
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def verify(app):
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == 'com.tony.markdown'
    assert info['CFBundleShortVersionString'] == (ROOT / 'VERSION').read_text().strip()
    assert info['SUFeedURL'] == 'https://github.com/Singularity-Li/markdown/releases/latest/download/appcast.xml'
    key = (ROOT / 'Resources/UpdatePublicKey.txt').read_text().strip()
    assert info['SUPublicEDKey'] == key and len(base64.b64decode(key, validate=True)) == 32
    for name in ('SUEnableAutomaticChecks', 'SUVerifyUpdateBeforeExtraction', 'SURequireSignedFeed'):
        assert info[name] is True, name
    assert info['SUAllowsAutomaticUpdates'] is False
    assert info['SUAutomaticallyUpdate'] is False
    framework = app / 'Contents/Frameworks/Sparkle.framework'
    assert (framework / 'Sparkle').is_file()
    assert (framework / 'Versions/Current').is_symlink()
    assert (framework / 'Versions/B/Updater.app/Contents/MacOS/Updater').is_file()
    linkage = subprocess.check_output(['otool', '-L', str(app / 'Contents/MacOS/Markdown')], text=True)
    assert '@rpath/Sparkle.framework/Versions/B/Sparkle' in linkage
    print('PASS: 自动更新配置、公钥、框架与安装辅助程序完整')

if __name__ == '__main__':
    verify(Path(sys.argv[1]))
