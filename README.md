# Docker 虚拟服务器管理系统

一个基于 Docker 和 Docker Compose 的虚拟 Linux 服务器管理系统，可以为多个用户创建独立的容器化服务器环境。

## 功能特性

- 🐳 **基于 Docker**：使用容器技术，轻量级且易于管理
- 👥 **多用户支持**：为每个用户创建独立的虚拟服务器
- 🔐 **SSH 访问**：每个服务器都有独立的 SSH 端口和用户账户
- 💾 **数据持久化**：用户数据存储在宿主机，容器重启不丢失
- ⚙️ **资源限制**：可配置 CPU 和内存限制
- 🔌 **端口映射**：为每个用户分配独立的端口范围
- 🛠️ **管理工具**：提供便捷的管理脚本

## 系统要求

- Docker Engine 20.10+
- Docker Compose 2.0+ (或 docker-compose 1.29+)
- Linux/macOS/Windows (WSL2)
- 至少 2GB 可用内存（根据容器数量调整）

## 快速开始

### 1. 安装项目

首次使用需要运行安装脚本：

```bash
chmod +x install.sh
./install.sh
```

安装脚本会：

- 创建必要的目录结构
- 生成 `Dockerfile`、`docker-compose.yml` 和 `.env` 配置文件
- 创建管理脚本

### 2. 配置环境变量

编辑 `.env` 文件来配置服务器参数：

```bash
# 用户1服务器配置
USER1_CONTAINER_NAME=user1-server
USER1_ROOT_PASSWORD=StrongRootPass1!
USER1_USERNAME=user1
USER1_USER_PASSWORD=UserPass1!
USER1_SSH_PORT=6001
USER1_PORT_RANGE=6002-6020
USER1_CPU_LIMIT=2
USER1_MEMORY_LIMIT=2G
```

### 3. 启动服务器

使用管理工具启动：

```bash
./scripts/manage.sh
# 或
./manage.sh  # 如果创建了符号链接
```

选择菜单选项：

- **选项 1**：查看所有容器状态和信息
- **选项 2**：添加新的用户容器
- **选项 3**：启动所有容器
- **选项 4**：停止所有容器
- **选项 5**：重启指定容器

或者直接使用 Docker Compose：

```bash
# 启动所有容器
docker compose up -d

# 启动特定容器
docker compose up -d user1-server

# 查看状态
docker compose ps

# 停止所有容器
docker compose down
```

### 4. 连接服务器

使用 SSH 连接到虚拟服务器：

```bash
ssh user1@<服务器IP> -p 6001
```

使用配置的用户名和密码登录。默认情况下，用户具有 sudo 权限。

## 项目结构

```
docker-virtual-servers/
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置文件
├── install.sh              # 安装脚本
├── .env                    # 环境变量配置文件（由 install.sh 生成）
├── README.md               # 本文件
├── data/                   # 数据持久化目录
│   ├── user1-server/      # 用户1的数据目录
│   └── user2-server/      # 用户2的数据目录
└── scripts/
    ├── init.sh             # 容器初始化脚本
    └── manage.sh           # 管理工具脚本
```

## 配置说明

### 环境变量

每个用户服务器都有以下配置项：

| 变量名                 | 说明           | 示例               |
| ---------------------- | -------------- | ------------------ |
| `USER*_CONTAINER_NAME` | 容器名称       | `user1-server`     |
| `USER*_ROOT_PASSWORD`  | Root 用户密码  | `StrongRootPass1!` |
| `USER*_USERNAME`       | 普通用户名     | `user1`            |
| `USER*_USER_PASSWORD`  | 普通用户密码   | `UserPass1!`       |
| `USER*_SSH_PORT`       | SSH 端口映射   | `6001`             |
| `USER*_PORT_RANGE`     | 分配的端口范围 | `6002-6020`        |
| `USER*_CPU_LIMIT`      | CPU 核心数限制 | `2`                |
| `USER*_MEMORY_LIMIT`   | 内存限制       | `2G`               |

### 端口映射

- **SSH 端口**：每个服务器都有独立的 SSH 端口（如 6001, 6021）
- **应用端口**：每个用户分配一个端口范围，可在容器内使用这些端口运行应用
- **注意**：端口范围需要在防火墙中开放，才能从外部访问

### 数据持久化

每个用户的数据存储在 `./data/<容器名称>/` 目录中，映射到容器内的 `/data` 目录。即使容器被删除，数据也不会丢失。

## 管理操作

### 添加新用户

1. 运行管理工具：`./scripts/manage.sh`
2. 选择选项 2：添加新用户容器
3. 按提示输入配置信息
4. 启动新容器：`docker compose up -d <新容器名>`

### 查看容器信息

```bash
# 使用管理工具
./scripts/manage.sh  # 选择选项 1

# 或使用 Docker 命令
docker compose ps
docker compose logs <容器名>
```

### 备份数据

```bash
# 备份用户数据
tar -czf user1-backup.tar.gz ./data/user1-server/

# 恢复数据
tar -xzf user1-backup.tar.gz
```

### 修改配置

1. 编辑 `.env` 文件修改环境变量
2. 编辑 `docker-compose.yml` 修改容器配置
3. 重启容器使配置生效：`docker compose restart <容器名>`

## 容器内环境

每个容器基于 Debian Bookworm，预装了以下工具：

- SSH 服务器
- sudo
- vim
- curl, wget
- git
- htop
- net-tools
- iputils-ping
- Python 3 和 pip
- OpenJDK 17

## 常见问题

### Q: 如何修改用户密码？

A: 可以通过 SSH 登录后使用 `passwd` 命令修改，或修改 `.env` 文件后重启容器。

### Q: 如何增加资源限制？

A: 修改 `.env` 文件中对应的 `CPU_LIMIT` 和 `MEMORY_LIMIT`，然后重启容器。

### Q: 容器无法启动怎么办？

A: 检查日志：`docker compose logs <容器名>`，常见问题包括端口冲突、资源不足等。

### Q: 如何删除用户服务器？

A:

1. 停止并删除容器：`docker compose stop <容器名> && docker compose rm -f <容器名>`
2. 从 `docker-compose.yml` 中删除对应服务配置
3. 从 `.env` 中删除对应配置
4. （可选）删除数据目录：`rm -rf ./data/<容器名>`

## 安全建议

1. **修改默认密码**：首次使用后立即修改所有默认密码
2. **使用强密码**：密码应包含大小写字母、数字和特殊字符
3. **限制 SSH 访问**：考虑使用 SSH 密钥认证替代密码认证
4. **防火墙配置**：只开放必要的端口
5. **定期更新**：定期更新容器镜像和系统包

## 许可证

SPDX-License-Identifier: MPL-2.0

Copyright © 2025 LeavesWebber

## 联系方式

如有问题或建议，请联系：LeavesWebber@outlook.com
