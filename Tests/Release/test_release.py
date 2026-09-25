import importlib.util
import unittest
import tempfile
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('release', ROOT / 'scripts/release.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)

class ReleaseTests(unittest.TestCase):
    def test_head_change_after_prepare_is_rejected(self):
        state = {'base_commit': 'base', 'commit_tree': 'prepared'}
        with self.assertRaises(RuntimeError):
            release.recover_commit(state, 'new', 'base', 'changed-source')

    def test_commit_completed_before_state_write_is_recovered(self):
        state = {'base_commit': 'base', 'commit_tree': 'prepared', 'phase': 'commit'}
        self.assertTrue(release.recover_commit(state, 'release', 'base', 'prepared'))
        self.assertEqual(state['commit'], 'release')
        self.assertEqual(state['phase'], 'publish')

    def test_uncommitted_preparation_stays_in_commit_phase(self):
        self.assertFalse(release.recover_commit({'base_commit': 'base'}, 'base', 'parent', 'tree'))

    def test_missing_or_partial_bundle_uses_reserved_build(self):
        with tempfile.TemporaryDirectory() as directory:
            # 仅建立 plist 测试夹具，不组装 App。
            root = Path(directory)
            self.assertEqual(release.next_build_from_bundle(root, 42), 42)
            (root / 'Contents').mkdir()
            plist = root / 'Contents/Info.plist'
            plist.write_bytes(b'incomplete')
            self.assertEqual(release.next_build_from_bundle(root, 42), 42)
            plist.write_bytes(plistlib.dumps({'CFBundleVersion': '42'}))
            self.assertEqual(release.next_build_from_bundle(root, 42), 43)

    def test_explicit_version_cannot_downgrade_project_or_release(self):
        with self.assertRaises(ValueError):
            release.validate_new_version('1.1.0', '2.0.0', None)
        with self.assertRaises(ValueError):
            release.validate_new_version('2.0.0', '2.0.0', '2.0.0')
        release.validate_new_version('2.1.0', '2.0.0', '2.0.0')

    def test_first_release_uses_project_version(self):
        self.assertEqual(release.next_version('1.2.0', None), '1.2.0')

    def test_next_release_increments_patch_numerically(self):
        self.assertEqual(release.next_version('1.2.9', '1.2.9'), '1.2.10')
        self.assertEqual(release.next_version('1.2.8', '1.2.9'), '1.2.10')

    def test_intentionally_bumped_version_is_preserved(self):
        self.assertEqual(release.next_version('1.3.0', '1.2.9'), '1.3.0')

    def test_unsafe_or_ambiguous_versions_rejected(self):
        for value in ('../oops', 'v1.2.0', '1.2', '01.2.3', '1.2.3-beta', '1.2.3\n'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                release.version_tuple(value)

    def test_feed_points_to_exact_release_and_escapes_notes(self):
        data = release.make_feed('1.2.0', 42, 1234, 'signature', '<MD> & 更新')
        root = release.ET.fromstring(data)
        ns = {'s': release.SPARKLE_NS}
        item = root.find('./channel/item')
        self.assertEqual(item.find('s:version', ns).text, '42')
        self.assertEqual(item.find('description').text, '<MD> & 更新')
        self.assertEqual(item.find('enclosure').attrib['url'],
                         'https://github.com/Singularity-Li/markdown/releases/download/v1.2.0/Markdown-1.2.0.zip')
        self.assertEqual(item.find('enclosure').attrib['length'], '1234')
        self.assertEqual(item.find('s:minimumSystemVersion', ns).text, '26.0')

if __name__ == '__main__':
    unittest.main()
