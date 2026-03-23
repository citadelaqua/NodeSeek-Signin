# Contributing Guide

感谢您对本项目的关注！欢迎通过 Issue 反馈问题，或通过 Pull Request 贡献代码。

## 目录

- [开发环境搭建](#开发环境搭建)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [Pull Request 流程](#pull-request-流程)
- [Issue 报告](#issue-报告)

---

## 开发环境搭建

**要求：** Python 3.9+，Git

```bash
# 1. Fork 并克隆仓库
git clone https://github.com/<your-username>/NodeSeek-Signin.git
cd NodeSeek-Signin

# 2. 创建虚拟环境
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

# 3. 安装运行时依赖 + 开发依赖
pip install -r requirements.txt
pip install -r requirements-dev.txt

# 4. 安装 pre-commit hooks（每次提交前自动格式化和 lint）
pre-commit install

# 5. 复制并填写本地配置
cp .env.example .env
# 编辑 .env 填入你的账号、Cookie、验证码服务信息

# 6. 本地验证签到脚本
python test_run.py
```

---

## 代码规范

本项目使用 [Ruff](https://docs.astral.sh/ruff/) 作为 linter 和 formatter。

```bash
# 检查代码问题
ruff check .

# 自动修复可修复的问题
ruff check --fix .

# 格式化代码
ruff format .
```

> **提示**：安装 pre-commit 之后，上述步骤会在每次 `git commit` 时自动执行，无需手动运行。

**主要规范要点：**

- 使用 4 个空格缩进（不使用 Tab）
- 行最大长度为 120 个字符
- 字符串引号统一使用双引号
- import 顺序遵循 isort 规则：标准库 → 第三方 → 本地模块

---

## 提交规范

提交信息请遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/) 规范：

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

常用 `type`：

| type | 含义 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 仅文档变更 |
| `style` | 不影响代码逻辑的格式调整 |
| `refactor` | 代码重构（无新功能、无 Bug 修复） |
| `perf` | 性能优化 |
| `chore` | 构建过程或辅助工具变更 |
| `ci` | CI/CD 配置变更 |

**示例：**

```
feat(notify): 新增 ntfy 推送渠道支持

添加 ntfy_bot() 函数和对应的 push_config 字段，
通过 HTTP PUT 请求发送通知。

Closes #42
```

---

## Pull Request 流程

1. **基于 `main` 分支**创建特性分支：
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. 编写代码，确保通过 `ruff check .` 和 `ruff format --check .`。

3. 更新相关文档（`README.md`、`docs/` 下对应文件）。

4. 在 `CHANGELOG.md` 的 `[Unreleased]` 节中追加变更说明。

5. 推送分支并在 GitHub 创建 PR：
   - PR 标题遵循 Conventional Commits 格式
   - 描述中说明改动背景、解决的问题及测试方法

6. 维护者 Review 后合并。

---

## Issue 报告

提交 Bug 报告时，请包含：

- **运行环境**：部署方式（GitHub Actions / Docker / 青龙 / 本地）、Python 版本、OS
- **复现步骤**：最小可复现的步骤
- **实际行为**：贴上相关日志（注意删除 Cookie、密码、API Key 等敏感信息）
- **期望行为**：您期望发生什么

提交功能请求时，请描述使用场景和预期效果。
