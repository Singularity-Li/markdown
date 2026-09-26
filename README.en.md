<div align="center">

# Markdown

**A lightweight, native Markdown reader and editor for macOS**

[中文](README.md) · English

[Download](https://github.com/Singularity-Li/markdown/releases/latest) · [Report an issue](https://github.com/Singularity-Li/markdown/issues) · [Contribute](CONTRIBUTING.md)

macOS 26+ · Apple Silicon · Swift / SwiftUI · MIT licensed

</div>

---

## Built around your words

Read a note, review a long document, or edit a project README. Markdown brings local files, readable typography, and native macOS interactions together, without an account.

- **Native glass interface** — Liquid Glass, adjustable background opacity, system light and dark appearance, and a compact toolbar.
- **Read and edit** — Rendered preview and highlighted Markdown source, with approximate position preservation between modes and automatic keyboard focus.
- **Multiple documents** — Tabs, multi-file selection, batch drag and drop, and folder navigation. Each document keeps its own mode and unsaved state.
- **Everyday Markdown** — Tables, task lists, highlighted code, images, quotations, heading links, custom HTML anchors, and relative image paths.
- **Your files stay yours** — Plain-text files, no proprietary format, and an embedded renderer that works offline for local text. Live character and line counts stay within reach.
- **Save protection and updates** — Save prompts before closing or quitting, signed updates through Sparkle, and restoration of recorded file tabs after an update restart.

## A closer look

**Preview** · Built-in code highlighting with room for your content.

![Markdown preview showing Swift and Python syntax highlighting](docs/images/preview.jpg)

**Editor** · Highlighted Markdown source and quick mode switching

![Markdown source editor showing the same document](docs/images/editor.jpg)

<sub>Both screenshots show the actual root App with the repository's sample document. Open an image for its full resolution.</sub>

## Get started

1. Download `Markdown-X.Y.Z.zip` from [Releases](https://github.com/Singularity-Li/markdown/releases/latest).
2. Unzip, move `Markdown.app` to Applications, and launch it once.
3. Drop in Markdown files or a folder, or press `⌘O`. Use `⇧⌘P` to switch between editing and preview.

Requires **macOS 26 or later and Apple Silicon**. Releases currently use ad-hoc signing and are not Apple Developer ID signed or notarized. macOS may warn that the developer cannot be verified. Check the download source, or build the app yourself.

Use **Markdown → 检查更新…** to check for updates. See [release notes](https://github.com/Singularity-Li/markdown/releases) for changes.

| Shortcut | Action |
| :--- | :--- |
| `⌘N` | New document |
| `⌘O` | Open files or a folder |
| `⌘S` | Save the current document |
| `⌘W` | Close the current tab |
| `⇧⌘P` | Switch edit / preview |

## Scope and privacy

Preview uses Marked in GitHub Flavored Markdown mode and highlight.js for code. Source highlighting for math or footnote syntax does not imply support for rendering those extensions. PDF export, cloud sync, and collaborative editing are not included. The app interface is currently primarily in Chinese.

Local text renders offline. Remote images and embedded remote content can contact their host sites; update checks contact GitHub. No account is required, and the project does not integrate usage analytics. Preview only trusted documents; see [security and privacy](SECURITY.md).

## Build from source

Use macOS 26+, Apple Silicon, and an Xcode toolchain with the macOS 26 SDK and Swift 6.2. Initial dependency resolution requires network access.

```sh
git clone https://github.com/Singularity-Li/markdown.git
cd markdown
bash scripts/build_app.sh
bash scripts/test.sh
open Markdown.app
```

The build generates only the root `Markdown.app`, signs it locally, and validates its icon and update configuration. The maintainer's update signing key is not needed. See [CONTRIBUTING.md](CONTRIBUTING.md) for development details.

## Open source

Original code, documentation, and assets are available under the [MIT License](LICENSE), permitting use, modification, redistribution, and commercial use with the license notice retained. Dependencies retain their own licenses; see [third-party notices](THIRD_PARTY_NOTICES.md). Apple's SDK and system frameworks are provided by Apple and are not relicensed under MIT.

Reproducible bug reports, documentation improvements, and focused pull requests are welcome. Please read the [contribution guide](CONTRIBUTING.md), [code of conduct](CODE_OF_CONDUCT.md), and [security reporting policy](SECURITY.md).
