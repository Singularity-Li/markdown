# 安全与隐私 / Security and privacy

## 报告问题 / Reporting

请优先使用仓库 Security 页面的 **Report a vulnerability**（若已启用），私下提供版本、影响和最小复现。若该入口不可用，请先创建不含漏洞细节的 Issue，请维护者建立私密沟通渠道；不要公开可利用步骤、私人文档或密钥。

Prefer **Report a vulnerability** on the repository's Security page when available. If unavailable, open an issue requesting a private contact without exploit details. Never post private documents, credentials, or signing keys. There is no guaranteed response time; fixes target the latest release rather than every historical version.

## 数据与网络 / Data and networking

- 文档由本地文件读写；未保存编辑保留在运行中的应用中。关闭前的保存提示不等同于自动备份。
- 应用设置和更新恢复的文件列表保存在本机。更新恢复不保存用户明确放弃的修改。
- 未集成账号、云同步或使用行为分析服务。
- Sparkle 更新检查连接 GitHub；远程图片、内嵌 HTML 内容可能访问外部站点。外链可在默认浏览器打开。
- Markdown 支持内嵌 HTML，当前预览不应被视为隔离恶意内容的安全沙箱。仅打开可信文档，尤其留意远程资源与链接。

Documents and settings are local. Save prompts are not automatic backups. The app has no account, cloud sync, or integrated usage analytics. GitHub is contacted for updates, and remote document content may contact other hosts. HTML preview is not a security sandbox for hostile input; use trusted documents.

## 更新信任 / Update trust

更新包和清单由 Sparkle 验证 Ed25519 签名；私钥不进入仓库。公开的 `Resources/UpdatePublicKey.txt` 是验证用公钥，不是秘密。当前 App 为 ad-hoc 签名，未经过 Apple 公证。更新签名与 Apple 的开发者身份验证是不同机制。

Sparkle validates signed feeds and update archives. The checked-in public key is intentionally public. Releases are currently ad-hoc signed, not Apple notarized. Only the maintainer holds the update signing private key.
