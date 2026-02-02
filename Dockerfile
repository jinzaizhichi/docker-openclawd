# OpenClaw Gateway 镜像
# 从官方仓库克隆并构建，无需本地源码
# 文档: https://docs.clawd.bot/install/docker

FROM node:22-bookworm

# 构建阶段不使用宿主机代理，避免错误格式（如 192.168.31.121://7890）导致 apt 失败
ENV HTTP_PROXY=
ENV HTTPS_PROXY=
ENV http_proxy=
ENV https_proxy=
ENV NO_PROXY=*
ENV no_proxy=*

# 构建时可选：指定 OpenClaw 版本（分支或 tag）
ARG OPENCLAW_VERSION=main
# 构建时可选：额外安装的 apt 包，空格分隔
ARG OPENCLAW_DOCKER_APT_PACKAGES=""

# Bun（构建脚本需要）
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# 克隆官方仓库并保留构建所需文件（99noproxy 禁用 apt 代理，避免宿主机错误代理注入）
RUN printf 'Acquire::http::Proxy "false";\nAcquire::https::Proxy "false";\n' > /etc/apt/apt.conf.d/99noproxy \
    && apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && git clone --depth 1 --branch "${OPENCLAW_VERSION}" https://github.com/openclaw/openclaw.git . \
    && rm -rf .git \
    && apt-get purge -y git && apt-get autoremove -y --purge && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# 可选：安装额外系统依赖（如 ffmpeg、build-essential）
RUN (unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY 2>/dev/null; \
    if [ -n "${OPENCLAW_DOCKER_APT_PACKAGES}" ]; then \
    printf 'Acquire::http::Proxy "false";\nAcquire::https::Proxy "false";\n' > /etc/apt/apt.conf.d/99noproxy; \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${OPENCLAW_DOCKER_APT_PACKAGES} \
    && apt-get clean && rm -rf /var/lib/apt/lists/*; \
    fi)

# 依赖与构建（与官方 Dockerfile 一致）
RUN pnpm install --frozen-lockfile
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# 以非 root 用户运行
USER node

WORKDIR /app
CMD ["node", "dist/index.js"]
