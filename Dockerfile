# Copyright © 2025 LeavesWebber
# 
# SPDX-License-Identifier: MPL-2.0
# 
# Feel free to contact LeavesWebber@outlook.com

FROM debian:bookworm

# 使用默认的 Debian 源安装证书包和基本工具
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 切换到中科大 HTTPS 源
RUN echo "Types: deb\n\
URIs: https://mirrors.ustc.edu.cn/debian\n\
Suites: bookworm bookworm-updates bookworm-backports\n\
Components: main contrib non-free non-free-firmware\n\
\n\
Types: deb\n\
URIs: https://mirrors.ustc.edu.cn/debian-security\n\
Suites: bookworm-security\n\
Components: main contrib non-free non-free-firmware" > /etc/apt/sources.list.d/debian.sources

# 安装其他工具和SSH服务
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    vim \
    curl \
    wget \
    git \
    htop \
    net-tools \
    iputils-ping \
    python3 \
    python3-pip \
    openjdk-17-jre-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 配置SSH服务
RUN mkdir -p /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 设置启动脚本
COPY ./scripts/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# 设置工作目录
WORKDIR /root

# 开放SSH端口
EXPOSE 22

# 启动SSH服务
CMD ["/usr/local/bin/init.sh"] 