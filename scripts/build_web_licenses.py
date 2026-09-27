"""Collect original license texts for npm packages included in the editor bundle."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
# esbuild retains whitespace-only lines inside bundled SVG templates. Removing
# that insignificant whitespace keeps both tracked copies free of diff noise.
bundle = root / "Resources/editor.js"
bundle.write_text("".join(line.lstrip(" \t") if not line.strip() else line
                          for line in bundle.read_text().splitlines(keepends=True)))
meta = json.loads((root / "dist/editor-meta.json").read_text())
names = set()
for source in meta["inputs"]:
    match = re.search(r"node_modules/((?:@[^/]+/)?[^/]+)/", source)
    if match:
        names.add(match.group(1))

parts = ["Bundled visual editor dependency licenses\n"]
for name in sorted(names):
    directory = root / "web/node_modules" / name
    package = json.loads((directory / "package.json").read_text())
    files = sorted(p for p in directory.iterdir() if re.match(r"^(licen[sc]e|copying)(\..*)?$", p.name, re.I) and p.is_file())
    if name == "remark-math":
        files = [root / "LICENSES/remark-math-MIT.txt"]
    if not files:
        raise SystemExit(f"Missing license text for {name}")
    parts.append(f"\n{'=' * 72}\n{name} {package['version']} — {package.get('license', 'see text')}\n{'=' * 72}\n")
    for file in files:
        parts.append(file.read_text(encoding="utf-8", errors="replace").rstrip() + "\n")

out = root / "LICENSES/web-editor.txt"
out.write_text("\n".join(parts), encoding="utf-8")
print(f"Collected {len(names)} editor package licenses in {out}")
