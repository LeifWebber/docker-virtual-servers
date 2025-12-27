# 快速开 debian docker 虚拟机

1. **创建配置**：  
    更名 .env.example 为 .env，然后修改成你需要的配置  

2. **构建并启动**：
    在终端进入该文件夹，运行：

    ```bash
    docker compose up -d --build
    ```

3. **在容器内验证 Docker**：

登录进去后，可以输入：  

```bash
docker run hello-world
```

如果看到 Hello from Docker，说明 Docker in Docker 运行成功。  
