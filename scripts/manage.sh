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
    docker compose -f "$DOCKER_COMPOSE" ps
    
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
    docker compose -f "$DOCKER_COMPOSE" up -d
    echo -e "${GREEN}完成!${NC}"
}

# 停止所有容器
function stop_all() {
    echo -e "${BLUE}停止所有虚拟服务器...${NC}"
    docker compose -f "$DOCKER_COMPOSE" down
    echo -e "${GREEN}完成!${NC}"
}

# 重启单个容器
function restart_container() {
    echo -e "${BLUE}可用的容器:${NC}"
    docker compose -f "$DOCKER_COMPOSE" ps --services
    
    read -p "请输入要重启的容器名称: " container_name
    
    if [ -z "$container_name" ]; then
        echo -e "${RED}未指定容器名称${NC}"
        return
    fi
    
    echo -e "${BLUE}重启容器 $container_name...${NC}"
    docker compose -f "$DOCKER_COMPOSE" restart "$container_name"
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