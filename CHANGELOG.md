# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-02-08

### Added

- 多账号批量签到，支持 `NS_COOKIE`（`&` 分隔）或 `USERn`/`PASSn` 账号密码两种登录方式
- 自动 Turnstile 验证码解决：支持自建 CloudFreed 服务（`turnstile_solver.py`）与 YesCaptcha 商业服务（`yescaptcha.py`）
- `curl_cffi` 浏览器指纹伪装，自动轮询多个 Chrome / Safari / Edge / Firefox 指纹以绕过 Cloudflare 拦截
- 签到成功后查询近 30 天鸡腿收益统计
- Cookie 自动回写：支持 GitHub Actions 变量（`GH_PAT`）、青龙面板 API、Docker 文件（`cookie/NS_COOKIE.txt`）
- `scheduler.py` 内置定时调度器，支持固定时间（`HH:MM`）与随机时间范围（`HH:MM-HH:MM`）
- 多渠道推送通知（`notify.py`）：Telegram、Bark、PushPlus、Server 酱、PushDeer、飞书、钉钉、企业微信、
  Gotify、iGot、SMTP 邮件、QMSG、go-cqhttp、智能微秘书、PushMe、CHRONOCAT、自定义 Webhook 等 20+ 渠道
- GitHub Actions 工作流（`.github/workflows/blank.yml`）支持 Push / 定时 / 手动触发
- Docker Compose 一键部署，Cookie 持久化挂载
- 青龙面板深度集成，沿用面板通知体系
- Cloudflare Worker 版本（`nodeseek-cloudflare-worker.js`），使用 2captcha 解决验证码
- 完整的部署文档（`docs/deployment/`）与环境变量手册（`docs/configuration/`）
- `.env.example` 配置模板
- `test_run.py` 本地调试入口

[Unreleased]: https://github.com/yowiv/NodeSeek-Signin/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yowiv/NodeSeek-Signin/releases/tag/v1.0.0
