#!/usr/bin/env python3
"""发布 GitHub 正式版本；--prepare-only 只准备，--resume vX.Y.Z 恢复同一次发布。"""
import argparse
import base64
import fcntl
import hashlib
import json
import os
import plistlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = 'Singularity-Li/markdown'
BASE = 'https://github.com/' + REPO
SPARKLE_NS = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
ACCOUNT = 'com.tony.markdown'
TOOLS = ROOT / '.build/artifacts/sparkle/Sparkle/bin'
ET.register_namespace('sparkle', SPARKLE_NS)


def run(*args, capture=False, env=None):
    result = subprocess.run([str(a) for a in args], cwd=ROOT, check=True,
                            text=True, stdout=subprocess.PIPE if capture else None, env=env)
    return result.stdout.strip() if capture else None


def gh_json(*args):
    return json.loads(run('gh', *args, capture=True))


def version_tuple(value):
    if not re.fullmatch(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)', value):
        raise ValueError('版本必须为 X.Y.Z，不含 v 前缀、前导零或预发布后缀')
    return tuple(map(int, value.split('.')))


def next_version(current, latest):
    current_tuple = version_tuple(current)
    if latest is None or current_tuple > version_tuple(latest):
        return current
    major, minor, patch = max(current_tuple, version_tuple(latest))
    return f'{major}.{minor}.{patch + 1}'


def validate_new_version(version, current, latest):
    value = version_tuple(version)
    if value < version_tuple(current):
        raise ValueError('指定版本不得低于工程 VERSION')
    if latest and value <= version_tuple(latest):
        raise ValueError('新版本必须高于已发布正式版')


def make_feed(version, build, length, signature):
    version_tuple(version)
    rss = ET.Element('rss', {'version': '2.0'})
    channel = ET.SubElement(rss, 'channel')
    item = ET.SubElement(channel, 'item')
    for name, value in [('version', str(build)), ('shortVersionString', version),
                        ('minimumSystemVersion', '26.0'), ('hardwareRequirements', 'arm64')]:
        ET.SubElement(item, '{' + SPARKLE_NS + '}' + name).text = value
    ET.SubElement(item, 'enclosure', {
        'url': f'{BASE}/releases/download/v{version}/Markdown-{version}.zip',
        'length': str(length), 'type': 'application/octet-stream',
        '{' + SPARKLE_NS + '}edSignature': signature,
    })
    return ET.tostring(rss, encoding='utf-8', xml_declaration=True)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_state(directory, state):
    temp = directory / 'state.tmp'
    temp.write_text(json.dumps(state, ensure_ascii=False, indent=2) + '\n')
    temp.replace(directory / 'state.json')


def recover_commit(state, head, parent, tree):
    """提交与状态文件无法原子写入：用已保存的完整 Git tree 识别提交后的中断。"""
    if head == state['base_commit']:
        return False
    if parent == state['base_commit'] and tree == state.get('commit_tree'):
        state['commit'] = head
        state['phase'] = 'publish'
        return True
    raise RuntimeError('准备后 HEAD 已变化，必须重新审查构建，不能发布旧 App')


def next_build_from_bundle(app, reserved):
    try:
        info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
        previous = int(info['CFBundleVersion'])
    except (OSError, ValueError, KeyError, TypeError, plistlib.InvalidFileException):
        # 只在已有发布恢复状态时使用；不完整包不影响继续构建。
        previous = reserved - 1
    return max(reserved, previous + 1)


def clean_tree():
    if run('git', 'status', '--porcelain', capture=True):
        raise RuntimeError('工作区有未提交改动。Agent 必须先审查、提交本次开发，勿混入其他用户改动。')


def release_list():
    pages = gh_json('api', '--paginate', '--slurp', f'repos/{REPO}/releases?per_page=100')
    return [item for page in pages for item in page]


def official_versions(releases):
    versions = []
    for item in releases:
        if not item['draft'] and not item['prerelease'] and re.fullmatch(r'v\d+\.\d+\.\d+', item['tag_name']):
            version = item['tag_name'][1:]
            version_tuple(version)
            versions.append(version)
    return versions


def download(url, path):
    run('curl', '--fail', '--location', '--silent', '--show-error', '--retry', '3',
        '--connect-timeout', '15', '--max-time', '180', '--proto', '=https',
        '--proto-redir', '=https', '--output', path, url)


def preflight():
    clean_tree()
    # 仓库写死以避免误发布到 fork 或其他 remote。
    remote = run('git', 'remote', 'get-url', 'origin', capture=True)
    if remote not in (f'git@github.com:{REPO}.git', BASE + '.git', BASE):
        raise RuntimeError('origin 不是指定的发布仓库')
    repo = gh_json('repo', 'view', REPO, '--json', 'visibility,defaultBranchRef')
    if repo['visibility'] != 'PUBLIC':
        raise RuntimeError('更新依赖公开 Release，仓库必须为 PUBLIC')
    branch = run('git', 'branch', '--show-current', capture=True)
    if branch != repo['defaultBranchRef']['name']:
        raise RuntimeError('仅允许从默认分支发布')
    run('git', 'fetch', 'origin', branch)
    run('git', 'merge-base', '--is-ancestor', f'origin/{branch}', 'HEAD')
    run('swift', 'package', 'resolve')
    key = run(TOOLS / 'generate_keys', '--account', ACCOUNT, '-p', capture=True)
    if key != (ROOT / 'Resources/UpdatePublicKey.txt').read_text().strip():
        raise RuntimeError('钥匙串公钥与 App 不一致，禁止自动生成新密钥替换')
    return branch


def prepare(args, branch):
    releases = release_list()
    versions = official_versions(releases)
    latest = max(versions, key=version_tuple) if versions else None
    current = (ROOT / 'VERSION').read_text().strip()
    version = args.version or next_version(current, latest)
    validate_new_version(version, current, latest)
    tag = 'v' + version
    if any(r['tag_name'] == tag for r in releases) or run('git', 'ls-remote', '--tags', 'origin', f'refs/tags/{tag}', capture=True):
        raise RuntimeError('该版本已存在；请使用 --resume 恢复，不覆盖已有版本')
    directory = ROOT / 'dist/releases' / tag
    if (directory / 'state.json').exists():
        raise RuntimeError(f'本地已有准备状态，请使用 --resume {tag}')
    directory.mkdir(parents=True, exist_ok=True)
    info = plistlib.loads((ROOT / 'Markdown.app/Contents/Info.plist').read_bytes())
    build = int(info['CFBundleVersion']) + 1
    # 比较所有正式版的构建号，防止恢复旧源码或切换分支后倒退。
    for item in releases:
        if item['draft'] or item['prerelease']:
            continue
        feeds = [a for a in item['assets'] if a['name'] == 'appcast.xml']
        if feeds:
            previous = directory / 'previous-appcast.xml'
            download(feeds[0]['browser_download_url'], previous)
            run(TOOLS / 'sign_update', '--account', ACCOUNT, '--verify', previous)
            for node in ET.fromstring(previous.read_bytes()).iter('{' + SPARKLE_NS + '}version'):
                build = max(build, int(node.text) + 1)
    if args.notes_file:
        notes = Path(args.notes_file).read_text().strip()
    else:
        # 首次发布只列最近的提交，后续从上一正式 tag 起生成说明。
        revision = f'v{latest}..HEAD' if latest else 'HEAD'
        if latest:
            run('git', 'fetch', 'origin', f'tag', f'v{latest}')
        notes = run('git', 'log', '--no-merges', '--format=- %s', '-30', revision, capture=True)
    if not notes:
        raise RuntimeError('更新说明不能为空')
    notes += '\n\n点击安装更新后将自动下载、验证并重启；未保存内容会先提示保存。\n需要 macOS 26 或更新版本及 Apple Silicon。'
    state = {'version': version, 'tag': tag, 'build': build, 'branch': branch,
             'base_commit': run('git', 'rev-parse', 'HEAD', capture=True),
             'notes': notes, 'phase': 'build'}
    save_state(directory, state)
    return directory, state


def build_release(directory, state):
    # 失败重试仅允许发布过程自己的更改，不会把其他工作一起提交。
    changed = run('git', 'diff', '--name-only', 'HEAD', capture=True).splitlines()
    notes_rel = f"docs/releases/{state['version']}.md"
    allowed = lambda name: name == 'VERSION' or name == notes_rel or name.startswith('Markdown.app/')
    untracked = run('git', 'ls-files', '--others', '--exclude-standard', capture=True).splitlines()
    if any(not allowed(name) for name in changed + untracked):
        raise RuntimeError('存在非发布改动，先审查处理后恢复')
    if run('git', 'rev-parse', 'HEAD', capture=True) != state['base_commit']:
        raise RuntimeError('准备期间 HEAD 已改变，不能重新构建本次发布')
    (ROOT / 'VERSION').write_text(state['version'] + '\n')
    run('bash', 'scripts/test.sh')
    state['build'] = next_build_from_bundle(ROOT / 'Markdown.app', state['build'])
    save_state(directory, state)
    run('bash', 'scripts/build_app.sh', env=dict(os.environ, RELEASE_BUILD_NUMBER=str(state['build'])))
    archive = directory / f"Markdown-{state['version']}.zip"
    if archive.exists():
        archive.unlink()  # 仅重做本次尚未发布的压缩包。
    run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', 'Markdown.app', archive)
    with zipfile.ZipFile(archive) as zipped:
        info = plistlib.loads(zipped.read('Markdown.app/Contents/Info.plist'))
        if info['CFBundleShortVersionString'] != state['version'] or int(info['CFBundleVersion']) != state['build']:
            raise RuntimeError('压缩包版本不一致')
    signature = run(TOOLS / 'sign_update', '--account', ACCOUNT, '-p', archive, capture=True)
    if len(base64.b64decode(signature, validate=True)) != 64:
        raise RuntimeError('更新签名格式错误')
    run(TOOLS / 'sign_update', '--account', ACCOUNT, '--verify', archive, signature)
    feed = directory / 'appcast.xml'
    feed.write_bytes(make_feed(state['version'], state['build'], archive.stat().st_size, signature))
    run(TOOLS / 'sign_update', '--account', ACCOUNT, feed)
    run(TOOLS / 'sign_update', '--account', ACCOUNT, '--verify', feed)
    notes_path = ROOT / notes_rel
    notes_path.parent.mkdir(parents=True, exist_ok=True)
    notes_path.write_text('# Markdown ' + state['version'] + '\n\n' + state['notes'] + '\n')
    state['assets'] = {p.name: sha(p) for p in (archive, feed)}
    state['phase'] = 'commit'
    save_state(directory, state)


def verify_assets(directory, state):
    for name, digest in state['assets'].items():
        if Path(name).name != name or sha(directory / name) != digest:
            raise RuntimeError('发布附件发生变化，拒绝继续')


def publish(directory, state):
    verify_assets(directory, state)
    if state['phase'] == 'commit':
        recovered = recover_commit(state, run('git', 'rev-parse', 'HEAD', capture=True),
                                   run('git', 'rev-parse', 'HEAD^', capture=True),
                                   run('git', 'rev-parse', 'HEAD^{tree}', capture=True))
        if recovered:
            save_state(directory, state)
    if state['phase'] == 'commit':
        # 防止 --prepare-only 后又修改了交付包。
        with zipfile.ZipFile(directory / f"Markdown-{state['version']}.zip") as zipped:
            for name in zipped.namelist():
                if name.startswith('Markdown.app/') and not name.endswith('/'):
                    path = ROOT / name
                    if path.is_symlink():
                        if zipped.read(name).decode() != os.readlink(path):
                            raise RuntimeError('App 符号链接与准备的包不一致')
                    elif path.read_bytes() != zipped.read(name):
                        raise RuntimeError('App 与准备的包不一致，请勿修改待发布文件')
        if (ROOT / 'VERSION').read_text().strip() != state['version']:
            raise RuntimeError('VERSION 与准备的版本不一致')
        changed = run('git', 'diff', '--name-only', 'HEAD', capture=True).splitlines()
        untracked = run('git', 'ls-files', '--others', '--exclude-standard', capture=True).splitlines()
        if any(not (p == 'VERSION' or p.startswith('Markdown.app/') or p == f"docs/releases/{state['version']}.md") for p in changed + untracked):
            raise RuntimeError('准备后出现非发布改动，拒绝继续')
        run('git', 'add', 'VERSION', 'Markdown.app', f"docs/releases/{state['version']}.md")
        run('git', 'diff', '--cached', '--check')
        staged = run('git', 'diff', '--cached', '--name-only', capture=True).splitlines()
        if any(not (p == 'VERSION' or p.startswith('Markdown.app/') or p == f"docs/releases/{state['version']}.md") for p in staged):
            raise RuntimeError('暂存区含非发布文件，拒绝提交')
        state['commit_tree'] = run('git', 'write-tree', capture=True)
        save_state(directory, state)
        run('git', 'commit', '-m', f"发布 Markdown {state['version']}（构建 {state['build']}）")
        state['commit'] = run('git', 'rev-parse', 'HEAD', capture=True)
        state['phase'] = 'publish'
        save_state(directory, state)
    clean_tree()
    run('git', 'merge-base', '--is-ancestor', state['commit'], 'HEAD')
    run('git', 'push', '-u', 'origin', state['branch'])
    tag = state['tag']
    remote_ref = run('git', 'ls-remote', '--tags', 'origin', f'refs/tags/{tag}', capture=True)
    if remote_ref:
        if remote_ref.split()[0] != state['commit']:
            raise RuntimeError('远程 tag 指向其他提交，拒绝覆盖')
    else:
        run('git', 'push', 'origin', f"{state['commit']}:refs/tags/{tag}")
    matches = [item for item in release_list() if item['tag_name'] == tag]
    if not matches:
        run('gh', 'release', 'create', tag, '--repo', REPO, '--verify-tag', '--draft',
            '--title', f"Markdown {state['version']}", '--notes-file', ROOT / f"docs/releases/{state['version']}.md")
        matches = [item for item in release_list() if item['tag_name'] == tag]
    release = matches[0]
    if release['draft']:
        versions = official_versions(release_list())
        if any(version_tuple(v) >= version_tuple(state['version']) for v in versions):
            raise RuntimeError('已有相同或更高正式版本，禁止发布旧草稿或回退 latest')
        # 恢复时只补传缺失附件，已有附件必须一致，不使用 --clobber。
        existing = {a['name'] for a in release['assets']}
        for name in state['assets']:
            if name not in existing:
                run('gh', 'release', 'upload', tag, directory / name, '--repo', REPO)
        verify_dir = directory / 'verify-draft'
        verify_dir.mkdir(exist_ok=True)
        for name, digest in state['assets'].items():
            run('gh', 'release', 'download', tag, '--repo', REPO, '--pattern', name, '--dir', verify_dir, '--clobber')
            if sha(verify_dir / name) != digest:
                raise RuntimeError('GitHub 草稿附件校验失败，保持草稿状态')
        run('gh', 'release', 'edit', tag, '--repo', REPO, '--draft=false', '--latest')
    verify_public(directory, state)
    state['phase'] = 'done'
    save_state(directory, state)
    print(f"发布完成：{BASE}/releases/tag/{tag}")


def verify_public(directory, state):
    output = directory / 'verify-public'
    output.mkdir(exist_ok=True)
    for name, digest in state['assets'].items():
        download(f"{BASE}/releases/download/{state['tag']}/{name}", output / name)
        if sha(output / name) != digest:
            raise RuntimeError('公开附件与本地不一致')
    download(BASE + '/releases/latest/download/appcast.xml', output / 'latest.xml')
    if sha(output / 'latest.xml') != state['assets']['appcast.xml']:
        raise RuntimeError('最新版本入口尚未指向本次发布，请稍后 --resume 复验')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', help='指定 X.Y.Z；默认递增补丁版本，首次沿用 VERSION')
    parser.add_argument('--notes-file', help='UTF-8 更新说明文件，不指定时使用提交记录')
    parser.add_argument('--prepare-only', action='store_true', help='构建验签后停下，不提交或发布')
    parser.add_argument('--resume', metavar='vX.Y.Z', help='恢复 dist/releases 中的同一次发布')
    args = parser.parse_args()
    os.chdir(ROOT)
    (ROOT / 'dist/releases').mkdir(parents=True, exist_ok=True)
    with (ROOT / 'dist/releases/.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if args.resume:
            if args.version or args.notes_file:
                raise RuntimeError('恢复时不能更换版本或说明')
            if not args.resume.startswith('v'):
                raise ValueError('恢复版本格式为 vX.Y.Z')
            version_tuple(args.resume[1:])
            directory = ROOT / 'dist/releases' / args.resume
            state = json.loads((directory / 'state.json').read_text())
            key = run(TOOLS / 'generate_keys', '--account', ACCOUNT, '-p', capture=True)
            if key != (ROOT / 'Resources/UpdatePublicKey.txt').read_text().strip():
                raise RuntimeError('恢复发布时签名公钥不一致')
            if state['tag'] != args.resume or state['version'] != args.resume[1:]:
                raise RuntimeError('发布恢复状态不匹配')
            if run('git', 'branch', '--show-current', capture=True) != state['branch']:
                raise RuntimeError('请切回准备发布时的分支')
        else:
            directory, state = prepare(args, preflight())
        if state['phase'] == 'build':
            build_release(directory, state)
        if args.prepare_only:
            verify_assets(directory, state)
            print(f"准备完成，继续发布：python3 scripts/release.py --resume {state['tag']}")
        else:
            publish(directory, state)

if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'发布中止：{error}\n保留本地提交和发布状态；不要强推或覆盖已发布附件。', file=sys.stderr)
        sys.exit(1)
