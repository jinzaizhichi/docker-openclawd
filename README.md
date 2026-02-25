# docker-openclawd 🦞

> **🚀 一键安装 OpenClawd（原名Clawdbot）的 Docker 部署方案** | 自动配置，开箱即用

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![Docker Compose](https://img.shields.io/badge/docker--compose-v2-blue.svg)

**OpenClawd** 是自托管个人 AI 助手，支持 WhatsApp / Telegram / Discord / Slack / 飞书等通道，对接 Pi 等 Agent。

## ✨ 特性

- 🎯 **一行命令安装**：无需手动配置，自动完成所有设置
- ⚙️ **自动配置**：首次运行自动执行 onboarding，创建最小配置
- 🐳 **完整 Docker 方案**：无需在宿主机安装 Node.js 或全局包
- 🔒 **权限优化**：使用非 root 用户运行，更安全

**官方文档**：[docs.clawd.bot](https://docs.clawd.bot/) · [GitHub openclaw/openclaw](https://github.com/openclaw/openclaw)

## 前置要求

- Docker Desktop 或 Docker Engine + Docker Compose v2

## 🚀 安装

**macOS/Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/liam798/docker-openclawd/main/scripts/install.sh | bash
```
**Windows**

```powershell
irm https://raw.githubusercontent.com/liam798/docker-openclawd/main/scripts/install.bat -OutFile install.bat; .\install.bat
```

**脚本会自动完成：**
- ✅ 从 npm 安装 OpenClaw 并构建镜像（无需源码）
- ✅ 创建 `.env` 并生成 Gateway 令牌
- ✅ 构建 Docker 镜像
- ✅ 启动 Gateway 服务
- ✅ **自动执行 onboarding 配置**（首次运行）

**🎉 安装完成后即可使用！** 访问 `http://127.0.0.1:18789/` 打开 Control UI。


**从其他设备访问（两种方式任选）：**

1. **允许局域网/外网 HTTP 访问（简单，仅限受信任网络）**  
   开启后可直接用 `http://<服务器IP>:18789/` 访问，需配合 token 认证：
   ```bash
   docker compose run --rm openclaw-cli config set gateway.controlUi.allowInsecureAuth true
   docker compose restart openclaw-gateway
   ```
   然后在浏览器打开 `http://<服务器IP>:18789/`，在设置中填入 Gateway 令牌。  
   ⚠️ 仅建议在受信任的局域网使用；暴露到公网时请改用 HTTPS。

2. **保持默认安全策略（推荐公网/不受信任网络）**  
   不开启 HTTP 时，请用以下方式之一访问，避免 1008（secure context）断开：
   - **SSH 端口转发**：本地执行 `ssh -N -L 18789:127.0.0.1:18789 user@服务器`，浏览器打开 `http://127.0.0.1:18789/?token=你的令牌`。
   - **Tailscale**：在 Gateway 所在机启用 Tailscale Serve，用 `https://<magicdns>/` 访问（见 [官方文档](https://docs.clawd.bot/help/faq#how-do-i-authenticate-the-dashboard-token-on-localhost-vs-remote)）。
   - **HTTPS 反向代理**：在 Gateway 前加 Nginx/Caddy 配 TLS，用 `https://你的域名` 访问。

配置与工作区会持久化在 `./data/openclaw` 与 `./data/workspace`（可在 `.env` 中修改 `OPENCLAW_CONFIG_DIR` / `OPENCLAW_WORKSPACE_DIR`）。

## 可选：使用 docker-compose.override.yml 添加挂载

如需把宿主机目录挂载进容器（例如让 OpenClaw 访问本机代码或文件），可使用 **docker-compose.override.yml**。Docker Compose 会自动合并该文件与 `docker-compose.yml`，无需修改主配置，且该文件通常不提交到 Git（可加入 `.gitignore`），便于本地定制。

**示例：挂载宿主机目录到容器的 `/host/Work`**

在项目根目录创建 `docker-compose.override.yml`：

```yaml
# docker-compose.override.yml（仅本地使用，可不提交）
services:
  openclaw-gateway:
    volumes:
      - /Volumes/Disk_APFS/Work:/host/Work
  openclaw-cli:
    volumes:
      - /Volumes/Disk_APFS/Work:/host/Work
```

挂载多个目录时，在 `volumes` 下列出多项即可：

```yaml
services:
  openclaw-gateway:
    volumes:
      - /path/on/host/projects:/host/projects
      - /path/on/host/data:/host/data
  openclaw-cli:
    volumes:
      - /path/on/host/projects:/host/projects
      - /path/on/host/data:/host/data
```

修改后执行 `docker compose up -d openclaw-gateway`（或先 down 再 up）使挂载生效。容器内路径可自定（如 `/host/Work`、`/host/projects` 等），按需与 Agent 或工具约定一致即可。

## 首次配置（Onboarding）

**一键脚本会自动执行 onboarding**，创建最小配置并启动 Gateway。

如需完整配置向导（模型、通道等），可手动执行：

```bash
docker compose run --rm openclaw-cli onboard
```

按提示完成模型、通道等配置。配置会自动保存，无需重启 Gateway。

## 通道登录示例

- **WhatsApp（扫码）**  
  ```bash
  docker compose run --rm openclaw-cli channels login
  ```
- **Telegram**  
  ```bash
  docker compose run --rm openclaw-cli channels add --channel telegram --token "YOUR_BOT_TOKEN"
  ```
- **Discord**  
  ```bash
  docker compose run --rm openclaw-cli channels add --channel discord --token "YOUR_BOT_TOKEN"
  ```
- **飞书（Feishu）**  
  OpenClawd 已内置官方飞书通道，无需安装社区插件。配置步骤：
  
  1. 在 [飞书开放平台](https://open.feishu.cn/) 创建自建应用，获取 App ID 和 App Secret
  2. **配置事件订阅（必需）**：在应用后台 → **事件与回调** → 将事件订阅方式设为 **「长连接」**（不要用「HTTP 回调」）；在事件列表中添加 **「接收消息 v2.0」**（事件标识：`im.message.receive_v1`），保存后等待生效。
  3. 申请所需权限（见下方）
  4. 配置通道：
     ```bash
     docker compose run --rm openclaw-cli config set channels.feishu.appId "cli_xxxxx"
     docker compose run --rm openclaw-cli config set channels.feishu.appSecret "your_app_secret"
     docker compose run --rm openclaw-cli config set channels.feishu.enabled true
     ```
  5. 重启 Gateway：
     ```bash
     docker compose restart openclaw-gateway
     ```
  
  **必需权限**：
  - `contact:user.base:readonly` - 用户信息
  - `im:message` - 消息
  - `im:message.p2p_msg:readonly` - 私聊
  - `im:message.group_at_msg:readonly` - 群聊 @ 消息
  - `im:message:send_as_bot` - 发送消息
  - `im:resource` - 媒体资源
  
  **发消息无响应时排查**（按顺序检查）：
  1. **事件订阅**（最常见）：飞书开放平台 → 应用 → **事件与回调** → 事件订阅方式必须为 **「长连接」**（使用长连接接收事件），并添加事件 **「接收消息 v2.0」**（`im.message.receive_v1`），保存后等待生效；权限里「事件订阅」相关权限需已申请并审核通过。
  2. **通道开关**：`docker compose run --rm openclaw-cli config get channels.feishu.enabled` 为 `true`。
  3. **appId / appSecret**：与开放平台一致，且应用已发布（至少测试版本）；改过配置后执行 `docker compose restart openclaw-gateway`。
  4. **私聊需配对**：默认私聊策略为「配对」时，用户首次私聊机器人会收到一个 **8 位配对码**（约 1 小时有效）。管理员在服务器上执行下方命令通过配对后，该用户才能正常对话。
  5. **群聊需 @**：群内需 **@ 机器人** 才会触发回复（可配置 `requireMention: false` 改为不要求 @）。
  6. **看日志**：`docker compose logs -f openclaw-gateway` 看是否有 feishu 连接/鉴权/收消息相关报错。
  
  **飞书私聊配对步骤**（当用户首次私聊机器人并收到配对码时）：
  1. 用户在飞书私聊里把机器人发来的 **8 位配对码**（大写字母）记下或截图给你。
  2. 在宿主机执行，查看待配对列表（可选）：  
     `docker compose run --rm openclaw-cli pairing list feishu`
  3. 用配对码通过该用户：  
     `docker compose run --rm openclaw-cli pairing approve feishu <配对码>`  
     例如：`docker compose run --rm openclaw-cli pairing approve feishu ABCDEFGH`
  4. 通过后，该用户再在飞书里发消息即可正常收到回复。配对码约 1 小时有效，超时需用户再发一条消息让机器人重新下发新码后再执行 `pairing approve`。
  
更多通道与配置见 [官方文档 · Channels](https://docs.clawd.bot/channels)。

## 常用命令

| 说明           | 命令 |
|----------------|------|
| 启动 Gateway  | `docker compose up -d openclaw-gateway` |
| 查看日志      | `docker compose logs -f openclaw-gateway` |
| 停止          | `docker compose down` |
| 健康检查      | `docker compose exec openclaw-gateway openclaw health --token "$OPENCLAW_GATEWAY_TOKEN"` |
| 使用 CLI 发消息 | `docker compose run --rm openclaw-cli message send --to +1234567890 --message "Hello"` |

## 环境变量说明

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `OPENCLAW_IMAGE` | `openclaw:local` | 使用的镜像名（不设则本地构建） |
| `OPENCLAW_VERSION` | `latest` | 构建时安装的 npm 版本（如 latest、2026.1.30） |
| `OPENCLAW_CONFIG_DIR` | `./data/openclaw` | 宿主机配置目录（挂载为 ~/.openclaw） |
| `OPENCLAW_WORKSPACE_DIR` | `./data/workspace` | 宿主机工作区目录 |
| `OPENCLAW_GATEWAY_PORT` | `18789` | Gateway 端口 |
| `OPENCLAW_GATEWAY_BIND` | `lan` | 绑定方式：`loopback` / `lan` |
| `OPENCLAW_GATEWAY_TOKEN` | （空） | Gateway 访问令牌，建议设置 |

更多见 `.env.example` 内注释。

## 国内用户：Docker 镜像加速

若构建时拉取 `node:22-bookworm` 等基础镜像很慢或报错（如 `load metadata for docker.io/library/node:22-bookworm`），可配置 Docker 使用国内镜像源。

**方式一：Docker Desktop**  
打开 Docker Desktop → Settings → Docker Engine，在 JSON 中增加 `registry-mirrors`，例如：

```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me",
    "https://hub.rat.dev"
  ]
}
```

保存后 Apply and restart。

**方式二：Linux 宿主机（Docker Engine）**  
编辑 `/etc/docker/daemon.json`（不存在则新建），加入：

```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me",
    "https://hub.rat.dev"
  ]
}
```

然后执行 `sudo systemctl restart docker`。

**常用国内/加速源（按可用性自选）：**

| 镜像源 | 地址 | 说明 |
|--------|------|------|
| 1ms | https://docker.1ms.run | 公共加速 |
| 玄渊 | https://docker.xuanyuan.me | 公共加速 |
| Rat.dev | https://hub.rat.dev | 公共加速 |
| 阿里云 | https://&lt;你的ID&gt;.mirror.aliyuncs.com | 需在[容器镜像服务](https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors)获取专属地址 |
| 腾讯云 | https://mirror.ccs.tencentyun.com | 部分地域 |
| 中科大 | https://docker.mirrors.ustc.edu.cn | 可能限速 |

配置完成后重新执行 `./docker-setup.sh` 或 `docker compose build`。

## 故障排查

### Control UI 显示 disconnected (1008): pairing required

浏览器打开 Control UI 时出现 **disconnected (1008): pairing required**，表示当前设备尚未与 Gateway 完成配对，需在服务器上批准该设备。

**解决步骤：**

1. 查看待配对设备列表：
   ```bash
   docker compose exec openclaw-gateway openclaw devices list
   ```
   或使用容器名（将 `docker-openclawd-openclaw-gateway-1` 替换为你的 gateway 容器名）：
   ```bash
   docker exec -it docker-openclawd-openclaw-gateway-1 openclaw devices list
   ```

2. 批准最新请求配对的设备：
   ```bash
   docker compose exec openclaw-gateway openclaw devices approve --latest
   ```
   或：
   ```bash
   docker exec -it docker-openclawd-openclaw-gateway-1 openclaw devices approve --latest
   ```

3. 刷新 Control UI 页面，连接应恢复正常。

## 参考

- [OpenClaw 官方 Docker 文档](https://docs.clawd.bot/install/docker)
- [OpenClaw 配置说明](https://docs.clawd.bot/gateway/configuration)
- [环境变量](https://docs.clawd.bot/environment)

## 许可证

本仓库采用 Apache-2.0。OpenClaw 项目采用 MIT 许可证。
