# Third-party notices / 第三方开源声明

Markdown's original work is licensed under MIT. The following bundled dependencies retain their own copyright and license terms. Full, unmodified license texts are kept in `LICENSES/` and copied into `Markdown.app/Contents/Resources/LICENSES/` during every build.

Markdown 原创部分采用 MIT 许可。以下依赖保留其原始版权与许可，完整文本随源码及应用一同分发。

| Component | Version | License | Source and license |
| --- | --- | --- | --- |
| Marked | 12.0.2 | MIT; includes historical Markdown BSD notice | [Source](https://github.com/markedjs/marked/tree/v12.0.2) · [License](LICENSES/marked-MIT.txt) |
| highlight.js | 11.9.0 | BSD-3-Clause | [Source](https://github.com/highlightjs/highlight.js/tree/11.9.0) · [License](LICENSES/highlightjs-BSD-3-Clause.txt) |
| Sparkle | 2.10.0 | MIT plus bundled component licenses | [Source](https://github.com/sparkle-project/Sparkle/tree/2.10.0) · [Full notices](LICENSES/Sparkle.txt) |

Marked and highlight.js are vendored in `Resources/` and embedded into generated `Assets.swift`. Sparkle is pinned in `Package.swift` and `Package.resolved`. Its notices also cover bsdiff/bspatch, sais-lite, Ed25519, and the signature verifier. `Sparkle-LICENSE.txt` is retained in the App for compatibility.

When updating a dependency, update this inventory and its full license text together. System frameworks (AppKit, SwiftUI, WebKit and others) are supplied by macOS; their names do not imply endorsement by Apple or the dependency authors.
