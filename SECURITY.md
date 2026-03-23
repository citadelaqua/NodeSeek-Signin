# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

如果您发现了安全漏洞，**请勿**通过 GitHub Issues 公开披露。

请通过以下方式私下联系维护者：

1. 使用 GitHub 的 [Private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability) 功能（推荐）。
2. 或发送邮件至项目维护者（见 GitHub Profile）。

报告时请尽量包含以下信息：

- 漏洞的类型（例如：凭证泄露、命令注入等）
- 触发该漏洞所需的步骤
- 漏洞的潜在影响

我们承诺在收到报告后 **7 个工作日内**回复，并尽快发布修复版本。

## Security Considerations

本项目涉及敏感信息（Cookie、账号密码、API 密钥），请注意：

- **不要**将 `.env` 文件提交到版本控制系统。`.gitignore` 已默认排除该文件。
- **不要**在公开场合（Issues、PR 描述、截图等）暴露您的 Cookie 或密钥。
- 建议为 `GH_PAT` 使用**最小权限**原则，仅授予 `Actions variables: Read and write` 权限。
- 定期轮换 API 密钥（验证码服务、Telegram Bot Token 等）。
