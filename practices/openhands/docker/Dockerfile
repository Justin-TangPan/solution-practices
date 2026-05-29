# ================================================
# OpenHands CLI — Docker Image
# 构建后推送到 SWR，供华为云 ECS 部署使用
# 构建方式:
#   docker build -t openhands-cli:1.16.0 .
#   docker tag openhands-cli:1.16.0 swr.cn-north-4.myhuaweicloud.com/{namespace}/openhands-cli:1.16.0
#   docker push swr.cn-north-4.myhuaweicloud.com/{namespace}/openhands-cli:1.16.0
# ================================================

FROM python:3.12-slim

LABEL maintainer="Huawei Cloud Solution"
LABEL description="OpenHands CLI - AI Software Development Agent"
LABEL version="1.16.0"

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 下载 OpenHands CLI 二进制
# 版本号与 release 保持一致
ARG OPENHANDS_VERSION=1.16.0
ARG TARGETARCH=linux-x86_64

RUN curl -fsSL -o /usr/local/bin/openhands \
    "https://github.com/OpenHands/OpenHands-CLI/releases/download/${OPENHANDS_VERSION}/openhands-linux-x86_64" && \
    chmod +x /usr/local/bin/openhands && \
    /usr/local/bin/openhands --version

# 配置目录
RUN mkdir -p /root/.openhands

# 服务端口
EXPOSE 3000

# 默认启动 Web UI 模式
ENTRYPOINT ["/usr/local/bin/openhands"]
CMD ["serve", "--host", "0.0.0.0", "--port", "3000"]
