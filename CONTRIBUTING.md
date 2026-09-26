# 贡献指南 / Contributing

欢迎通过 [Issues](https://github.com/Singularity-Li/markdown/issues) 和 Pull Request 参与。请先搜索已有问题；缺陷报告需包含 macOS / App 版本、复现步骤、预期与实际结果。示例文档请移除私人信息。

Contributions are welcome through issues and focused pull requests. Include OS/app versions, reproduction steps, and expected versus actual behavior. Remove private content from examples. Security issues follow [SECURITY.md](SECURITY.md).

## 开发环境 / Development

- macOS 26+、Apple Silicon；Swift 6.2 与 macOS 26 SDK（Xcode 工具链）。
- Python 3、Git；构建使用系统 `iconutil`、`codesign` 等工具。
- 首次构建需要网络下载固定版本的 Sparkle。无需发布私钥或 GitHub 写权限。

```sh
bash scripts/build_app.sh
bash scripts/test.sh
```

The same commands build and test the app. UI-related tests require a logged-in macOS graphical session; do not assume they can run on a headless Linux runner.

构建在根目录直接生成并验证唯一的 `Markdown.app`，该包按本仓库约定纳入 Git。`.build/`、`dist/` 是忽略的中间产物目录，不在其中组装另一个 App。每次构建递增构建号。启动测试使用根目录 App，退出或重启前保护未保存文档。

## 代码与资源 / Code and assets

| 路径 / Path | 用途 / Purpose |
| --- | --- |
| `Sources/Markdown/` | SwiftUI / AppKit UI、文档状态与 WebKit 预览 |
| `Resources/` | 预览 CSS、固定版本 JavaScript、公钥 |
| `Tests/` | 文档、渲染、编辑、控件、图标与更新回归测试 |
| `scripts/` | 资源生成、构建、验证和正式发布 |
| `docs/` | 项目说明、README 截图与历史发布记录 |
| `LICENSES/` | 完整第三方许可 |

编辑 `Resources/` 后运行构建重新生成 `Assets.swift`，不要手改生成文件。图标源在 `scripts/make_assets.swift`。主题与控件尺寸复用 `AppTheme.swift`。详细工程约定见 [AGENTS.md](AGENTS.md)。

Edit resource sources rather than generated `Assets.swift`. Keep UI changes small and consistent with `AppTheme.swift`; preserve keyboard interaction and both appearances. Add meaningful regression coverage for behavior changes. Update dependency notices when changing dependencies.

## 提交检查 / Pull request checklist

- 描述解决的问题、用户可见变化与验证结果；界面改动附真实截图。
- 运行相关检查、`bash scripts/test.sh` 和 `bash scripts/build_app.sh`。
- 检查 diff，包含必要源码、文档及根目录 App，不加入日志、缓存、密钥或无关修改。
- 本地修改依赖时保留其许可声明。提交的原创贡献按 [MIT](LICENSE) 分发；仅提交你有权授权的内容，不要求转让版权。

Describe the problem, resulting behavior, and validation. Keep changes focused and include the rebuilt root App under this repository's delivery convention. Submit only material you have the right to license under MIT; no copyright assignment is required.

## 发布与 Fork / Releases and forks

正式发布仅由维护者执行，见 [发布指南](docs/自动更新与发布.md)。普通 PR 不需要发布，也不需要签名私钥。

Fork 可以本地构建，但默认更新地址仍指向上游。若独立分发，请配置自己的 Bundle ID、仓库、更新地址与签名公钥，并同步更新校验脚本；不要将 Fork 宣称为上游官方发行版，不要索取上游私钥。

Forks may build locally. Before distributing an independent update channel, configure your own identity, repository, feed, public key and corresponding validation. The default configuration points to upstream releases.
