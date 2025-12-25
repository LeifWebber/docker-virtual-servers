#!/bin/bash

# Copyright © 2025 LeavesWebber
# 
# SPDX-License-Identifier: MPL-2.0
# 
# Feel free to contact LeavesWebber@outlook.com



# 设置root密码
echo "root:${ROOT_PASSWORD}" | chpasswd

# 创建用户并设置密码
if [ ! -z "$USERNAME" ] && [ ! -z "$USER_PASSWORD" ]; then
    # 检查用户是否已存在
    if ! id -u "$USERNAME" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$USERNAME"
        echo "$USERNAME:$USER_PASSWORD" | chpasswd
        # 添加到sudo组
        usermod -aG sudo "$USERNAME"
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
        chmod 0440 /etc/sudoers.d/$USERNAME
    fi
fi

# 如果是首次启动，创建欢迎信息
if [ ! -f "/etc/welcome_created" ]; then
    # 获取分配的端口范围
    PORT_START=$(echo $PORT_RANGE | cut -d'-' -f1)
    PORT_END=$(echo $PORT_RANGE | cut -d'-' -f2)
    
    # 创建欢迎信息
    cat > /etc/motd << EOF
欢迎使用您的虚拟Linux服务器！

服务器信息:
- 容器名称: ${CONTAINER_NAME}
- SSH端口: ${SSH_PORT}
- 分配的端口范围: ${PORT_RANGE}
- 可用资源: CPU: ${CPU_LIMIT} 核, 内存: ${MEMORY_LIMIT}

您可以使用这些端口来运行您的应用程序。
请记住定期备份重要数据。
数据持久化目录位于: /data (容器内路径)

祝您使用愉快！
EOF
    
    # 标记欢迎信息已创建
    touch /etc/welcome_created
fi

# 启动SSH服务
/usr/sbin/sshd -D