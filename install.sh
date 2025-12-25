#!/bin/bash

# Copyright © 2025 LeavesWebber
# 
# SPDX-License-Identifier: MPL-2.0
# 
# Feel free to contact LeavesWebber@outlook.com

# 设置颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}===== 虚拟服务器管理系统安装 =====${NC}"

# 创建目录结构
echo -e "${YELLOW}创建目录结构...${NC}"
mkdir -p "$PROJECT_DIR/data"
mkdir -p "$PROJECT_DIR/scripts"

# 创建初始化脚本
echo -e "${YELLOW}创建初始化脚本...${NC}"
cat > "$PROJECT_DIR/scripts/init.sh" << 'EOF'
#!/bin/bash

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
    cat > /etc/motd << EOMOTD
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
EOMOTD
    
    # 标记欢迎信息已创建
    touch /etc/welcome_created
fi

# 启动SSH服务
/usr/sbin/sshd -D
EOF

chmod +x "$PROJECT_DIR/scripts/init.sh"

# 创建Dockerfile
echo -e "${YELLOW}创建Dockerfile...${NC}"
cat > "$PROJECT_DIR/Dockerfile" << 'EOF'
FROM debian:bookworm

# 安装基本工具和SSH服务
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
EOF

# 创建docker-compose.yml文件
echo -e "${YELLOW}创建docker-compose.yml文件...${NC}"
cat > "$PROJECT_DIR/docker-compose.yml" << 'EOF'
version: '3'

services:
  # 示例虚拟服务器1
  user1-server:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ${USER1_CONTAINER_NAME:-user1-server}
    restart: unless-stopped
    ports:
      # SSH端口映射 (外部端口:内部端口)
      - "${USER1_SSH_PORT:-6001}:22"
      # 分配给用户的其他端口
      - "${USER1_PORT_RANGE:-6002-6020}"
    volumes:
      # 持久化存储
      - ./data/${USER1_CONTAINER_NAME:-user1-server}:/data
      - ./scripts:/scripts
    environment:
      - CONTAINER_NAME=${USER1_CONTAINER_NAME:-user1-server}
      - ROOT_PASSWORD=${USER1_ROOT_PASSWORD:-StrongPassword1!}
      - USERNAME=${USER1_USERNAME:-user1}
      - USER_PASSWORD=${USER1_USER_PASSWORD:-UserPass1!}
      - SSH_PORT=${USER1_SSH_PORT:-6001}
      - PORT_RANGE=${USER1_PORT_RANGE:-6002-6020}
      - CPU_LIMIT=${USER1_CPU_LIMIT:-2}
      - MEMORY_LIMIT=${USER1_MEMORY_LIMIT:-2G}
    cpus: ${USER1_CPU_LIMIT:-2}
    mem_limit: ${USER1_MEMORY_LIMIT:-2G}

  # 示例虚拟服务器2
  user2-server:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ${USER2_CONTAINER_NAME:-user2-server}
    restart: unless-stopped
    ports:
      # SSH端口映射
      - "${USER2_SSH_PORT:-6021}:22"
      # 分配给用户的其他端口
      - "${USER2_PORT_RANGE:-6022-6040}"
    volumes:
      # 持久化存储
      - ./data/${USER2_CONTAINER_NAME:-user2-server}:/data
      - ./scripts:/scripts
    environment:
      - CONTAINER_NAME=${USER2_CONTAINER_NAME:-user2-server}
      - ROOT_PASSWORD=${USER2_ROOT_PASSWORD:-StrongPassword2!}
      - USERNAME=${USER2_USERNAME:-user2}
      - USER_PASSWORD=${USER2_USER_PASSWORD:-UserPass2!}
      - SSH_PORT=${USER2_SSH_PORT:-6021}
      - PORT_RANGE=${USER2_PORT_RANGE:-6022-6040}
      - CPU_LIMIT=${USER2_CPU_LIMIT:-2}
      - MEMORY_LIMIT=${USER2_MEMORY_LIMIT:-2G}
    cpus: ${USER2_CPU_LIMIT:-2}
    mem_limit: ${USER2_MEMORY_LIMIT:-2G}

  # 你可以按照相同的模式添加更多虚拟服务器
EOF

# 创建.env文件
echo -e "${YELLOW}创建.env文件...${NC}"
cat > "$PROJECT_DIR/.env" << 'EOF'
# 用户1服务器配置
USER1_CONTAINER_NAME=user1-server
USER1_ROOT_PASSWORD=StrongRootPass1!
USER1_USERNAME=user1
USER1_USER_PASSWORD=UserPass1!
USER1_SSH_PORT=6001
USER1_PORT_RANGE=6002-6020
USER1_CPU_LIMIT=2
USER1_MEMORY_LIMIT=2G

# 用户2服务器配置
USER2_CONTAINER_NAME=user2-server
USER2_ROOT_PASSWORD=StrongRootPass2!
USER2_USERNAME=user2
USER2_USER_PASSWORD=UserPass2!
USER2_SSH_PORT=6021
USER2_PORT_RANGE=6022-6040
USER2_CPU_LIMIT=2
USER2_MEMORY_LIMIT=2G

# 用户3服务器配置 (示例)
USER3_CONTAINER_NAME=user3-server
USER3_ROOT_PASSWORD=StrongRootPass3!
USER3_USERNAME=user3
USER3_USER_PASSWORD=UserPass3!
USER3_SSH_PORT=6041
USER3_PORT_RANGE=6042-6060
USER3_CPU_LIMIT=2
USER3_MEMORY_LIMIT=2G
EOF

# 创建管理脚本
echo -e "${YELLOW}创建管理脚本...${NC}"
cat > "$PROJECT_DIR/scripts/manage.sh" << 'EOF'
#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
DOCKER_COMPOSE="$PROJECT_DIR/docker-compose.yml"

# 读取.env文件中的所有用户配置
function read_user_configs() {
    grep -E "^USER[0-9]+_CONTAINER_NAME=" "$ENV_FILE" | cut -d'=' -f1 | sed 's/_CONTAINER_NAME//'
}

# 显示所有容器信息
function show_all_containers() {
    echo -e "${BLUE}===== 虚拟服务器容器状态 =====${NC}"
    docker-compose -f "$DOCKER_COMPOSE" ps
    
    echo -e "\n${BLUE}===== 服务器详细信息 =====${NC}"
    
    local user_prefixes=$(read_user_configs)
    
    for prefix in $user_prefixes; do
        local container_name=$(grep "${prefix}_CONTAINER_NAME" "$ENV_FILE" | cut -d'=' -f2)
        local ssh_port=$(grep "${prefix}_SSH_PORT" "$ENV_FILE" | cut -d'=' -f2)
        local port_range=$(grep "${prefix}_PORT_RANGE" "$ENV_FILE" | cut -d'=' -f2)
        local username=$(grep "${prefix}_USERNAME" "$ENV_FILE" | cut -d'=' -f2)
        local user_pass=$(grep "${prefix}_USER_PASSWORD" "$ENV_FILE" | cut -d'=' -f2)
        local root_pass=$(grep "${prefix}_ROOT_PASSWORD" "$ENV_FILE" | cut -d'=' -f2)
        local cpu=$(grep "${prefix}_CPU_LIMIT" "$ENV_FILE" | cut -d'=' -f2)
        local memory=$(grep "${prefix}_MEMORY_LIMIT" "$ENV_FILE" | cut -d'=' -f2)
        
        local status=$(docker ps -a --filter "name=$container_name" --format "{{.Status}}")
        local running=$(docker ps --filter "name=$container_name" -q)
        
        echo -e "${YELLOW}容器名称: ${NC}$container_name"
        echo -e "${YELLOW}状态: ${NC}$status"
        echo -e "${YELLOW}SSH端口: ${NC}$ssh_port"
        echo -e "${YELLOW}端口范围: ${NC}$port_range"
        echo -e "${YELLOW}默认用户: ${NC}$username / $user_pass"
        echo -e "${YELLOW}Root密码: ${NC}$root_pass"
        echo -e "${YELLOW}资源限制: ${NC}CPU: $cpu, 内存: $memory"
        echo -e "${YELLOW}持久化目录: ${NC}$PROJECT_DIR/data/$container_name"
        
        # 显示SSH连接命令
        if [ ! -z "$running" ]; then
            echo -e "${GREEN}SSH连接命令: ${NC}ssh $username@<服务器IP> -p $ssh_port"
        fi
        echo -e "------------------------------"
    done
}

# 添加新用户容器
function add_new_container() {
    # 查找当前最大用户编号
    local max_user_num=$(grep -E "^USER[0-9]+_CONTAINER_NAME=" "$ENV_FILE" | cut -d'=' -f1 | sed 's/USER//' | sed 's/_CONTAINER_NAME//' | sort -nr | head -1)
    
    # 如果未找到，从1开始
    if [ -z "$max_user_num" ]; then
        max_user_num=0
    fi
    
    # 新用户编号
    local new_user_num=$((max_user_num + 1))
    local prefix="USER${new_user_num}"
    
    # 确定端口
    local last_port=$(grep -E "USER[0-9]+_PORT_RANGE=" "$ENV_FILE" | cut -d'=' -f2 | cut -d'-' -f2 | sort -nr | head -1)
    
    if [ -z "$last_port" ]; then
        last_port=6000
    fi
    
    local new_ssh_port=$((last_port + 1))
    local new_port_start=$((new_ssh_port + 1))
    local new_port_end=$((new_port_start + 18)) # 总共20个端口(包括SSH)
    
    # 询问用户名和密码
    read -p "请输入新用户名 [user$new_user_num]: " username
    username=${username:-user$new_user_num}
    
    read -p "请输入用户密码 [UserPass$new_user_num!]: " user_pass
    user_pass=${user_pass:-UserPass$new_user_num!}
    
    read -p "请输入Root密码 [StrongRootPass$new_user_num!]: " root_pass
    root_pass=${root_pass:-StrongRootPass$new_user_num!}
    
    read -p "请输入CPU限制 [2]: " cpu_limit
    cpu_limit=${cpu_limit:-2}
    
    read -p "请输入内存限制(带单位,如2G) [2G]: " mem_limit
    mem_limit=${mem_limit:-2G}
    
    # 添加到.env文件
    echo "" >> "$ENV_FILE"
    echo "# 用户${new_user_num}服务器配置" >> "$ENV_FILE"
    echo "${prefix}_CONTAINER_NAME=${username}-server" >> "$ENV_FILE"
    echo "${prefix}_ROOT_PASSWORD=${root_pass}" >> "$ENV_FILE"
    echo "${prefix}_USERNAME=${username}" >> "$ENV_FILE"
    echo "${prefix}_USER_PASSWORD=${user_pass}" >> "$ENV_FILE"
    echo "${prefix}_SSH_PORT=${new_ssh_port}" >> "$ENV_FILE"
    echo "${prefix}_PORT_RANGE=${new_port_start}-${new_port_end}" >> "$ENV_FILE"
    echo "${prefix}_CPU_LIMIT=${cpu_limit}" >> "$ENV_FILE"
    echo "${prefix}_MEMORY_LIMIT=${mem_limit}" >> "$ENV_FILE"
    
    # 添加到docker-compose.yml文件
    local service_template="
  # 用户${new_user_num}虚拟服务器
  ${username}-server:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: \${${prefix}_CONTAINER_NAME:-${username}-server}
    restart: unless-stopped
    ports:
      # SSH端口映射
      - \"\${${prefix}_SSH_PORT:-${new_ssh_port}}:22\"
      # 分配给用户的其他端口
      - \"\${${prefix}_PORT_RANGE:-${new_port_start}-${new_port_end}}\"
    volumes:
      # 持久化存储
      - ./data/\${${prefix}_CONTAINER_NAME:-${username}-server}:/data
      - ./scripts:/scripts
    environment:
      - CONTAINER_NAME=\${${prefix}_CONTAINER_NAME:-${username}-server}
      - ROOT_PASSWORD=\${${prefix}_ROOT_PASSWORD:-${root_pass}}
      - USERNAME=\${${prefix}_USERNAME:-${username}}
      - USER_PASSWORD=\${${prefix}_USER_PASSWORD:-${user_pass}}
      - SSH_PORT=\${${prefix}_SSH_PORT:-${new_ssh_port}}
      - PORT_RANGE=\${${prefix}_PORT_RANGE:-${new_port_start}-${new_port_end}}
      - CPU_LIMIT=\${${prefix}_CPU_LIMIT:-${cpu_limit}}
      - MEMORY_LIMIT=\${${prefix}_MEMORY_LIMIT:-${mem_limit}}
    cpus: \${${prefix}_CPU_LIMIT:-${cpu_limit}}
    mem_limit: \${${prefix}_MEMORY_LIMIT:-${mem_limit}}
"
    # 在文件末尾添加新服务
    echo -e "$service_template" >> "$DOCKER_COMPOSE"
    
    # 创建持久化目录
    mkdir -p "$PROJECT_DIR/data/${username}-server"
    
    echo -e "${GREEN}新容器 ${username}-server 配置已添加${NC}"
    echo -e "${GREEN}运行 'docker-compose up -d ${username}-server' 启动新容器${NC}"
}

# 启动所有容器
function start_all() {
    echo -e "${BLUE}启动所有虚拟服务器...${NC}"
    docker-compose -f "$DOCKER_COMPOSE" up -d
    echo -e "${GREEN}完成!${NC}"
}

# 停止所有容器
function stop_all() {
    echo -e "${BLUE}停止所有虚拟服务器...${NC}"
    docker-compose -f "$DOCKER_COMPOSE" down
    echo -e "${GREEN}完成!${NC}"
}

# 重启单个容器
function restart_container() {
    echo -e "${BLUE}可用的容器:${NC}"
    docker-compose -f "$DOCKER_COMPOSE" ps --services
    
    read -p "请输入要重启的容器名称: " container_name
    
    if [ -z "$container_name" ]; then
        echo -e "${RED}未指定容器名称${NC}"
        return
    fi
    
    echo -e "${BLUE}重启容器 $container_name...${NC}"
    docker-compose -f "$DOCKER_COMPOSE" restart "$container_name"
    echo -e "${GREEN}完成!${NC}"
}

# 显示菜单
function show_menu() {
    echo -e "${BLUE}===== 虚拟服务器管理工具 =====${NC}"
    echo "1. 显示所有容器状态和信息"
    echo "2. 添加新用户容器"
    echo "3. 启动所有容器"
    echo "4. 停止所有容器"
    echo "5. 重启指定容器"
    echo "0. 退出"
    echo -e "${BLUE}=========================${NC}"
}

# 主程序
while true; do
    show_menu
    read -p "请选择操作: " choice
    
    case $choice in
        1)
            show_all_containers
            ;;
        2)
            add_new_container
            ;;
        3)
            start_all
            ;;
        4)
            stop_all
            ;;
        5)
            restart_container
            ;;
        0)
            echo "退出管理工具"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重试${NC}"
            ;;
    esac
    
    echo
    read -p "按Enter继续..."
done
EOF

chmod +x "$PROJECT_DIR/scripts/manage.sh"

# 在项目根目录创建一个符号链接到管理脚本
ln -sf "$PROJECT_DIR/scripts/manage.sh" "$PROJECT_DIR/manage.sh"
chmod +x "$PROJECT_DIR/manage.sh"

# 创建每个用户的持久化目录
echo -e "${YELLOW}创建持久化数据目录...${NC}"
mkdir -p "$PROJECT_DIR/data/user1-server"
mkdir -p "$PROJECT_DIR/data/user2-server"
mkdir -p "$PROJECT_DIR/data/user3-server"

echo -e "${GREEN}安装完成！${NC}"
echo -e "${BLUE}使用方法:${NC}"
echo -e "1. 运行 ${YELLOW}./manage.sh${NC} 启动管理工具"
echo -e "2. 选择选项3启动所有容器，或者使用 ${YELLOW}docker-compose up -d${NC} 命令"
echo -e "3. 使用选项1查看所有容器的状态和信息"
echo -e "4. 使用选项2添加新的用户容器"
echo -e "\n祝您使用愉快！"