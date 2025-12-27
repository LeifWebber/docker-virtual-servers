#!/bin/bash
set -e

# 1. 设置 Root 密码
if [ -n "$ROOT_PASSWORD" ]; then
    echo "root:$ROOT_PASSWORD" | chpasswd
    echo "Root password set successfully."
fi

# 2. 配置 Docker 镜像加速 (针对中国大陆)
# 如果没有配置过 daemon.json，则写入配置
if [ ! -f /etc/docker/daemon.json ]; then
    mkdir -p /etc/docker
    cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://huecker.io",
    "https://dockerhub.timeweb.cloud"
  ]
}
EOF
fi

# 3. 启动内部 Docker Daemon
# 删除可能存在的旧 pid 文件以防止启动失败
rm -f /var/run/docker.pid
# 在后台启动 dockerd
dockerd > /var/log/dockerd.log 2>&1 &

# 4. 启动 SSH 服务
# 确保 ssh 目录存在
mkdir -p /run/sshd
# 生成主机密钥（如果不存在）
ssh-keygen -A

echo "Starting SSH server..."
# 在前台运行 SSH，作为主进程保持容器运行
/usr/sbin/sshd -D