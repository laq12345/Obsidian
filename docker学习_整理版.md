# Docker 学习笔记

## 一、镜像管理

### 1. 拉取镜像
```bash
sudo docker pull image  # 拉取镜像
```

### 2. 删除镜像
```bash
sudo docker rmi image  # 删除镜像
```

---

## 二、容器操作

### 1. 创建并运行容器
```bash
sudo docker run image  # 创建并运行容器
```

### 2. 后台运行容器
```bash
sudo docker run -d image  # 创建容器并在后台运行（-d：分离容器）
```

### 3. 端口映射
```bash
sudo docker run -p 80:80 image  # -p：端口映射
```

### 4. 挂载卷
```bash
sudo docker run -v 宿主机目录:容器内目录 image  # -v：挂载卷
```

### 5. 查看容器
```bash
sudo docker ps  # 查看正在运行的容器
sudo docker ps -a  # 查看所有容器，包括停止的容器
```

### 6. 停止容器
```bash
sudo docker stop <容器ID或名字>  # 停止容器
```

### 7. 删除容器
```bash
sudo docker rm -f <容器ID或名字>  # 删除正在运行的容器
```

> **注意**：`rm` 删除容器，`rmi` 删除镜像

---

## 三、数据卷管理

### 1. 创建卷
```bash
sudo docker volume create nginx_html  # 创建宿主机挂载卷
```

### 2. 查看卷信息
```bash
sudo docker volume inspect nginx_html  # 查看挂载卷目录
```

### 3. 列出所有卷
```bash
sudo docker volume list  # 列出所有创建过的卷
```

### 4. 删除卷
```bash
sudo docker volume rm <挂载卷>  # 删除一个卷
sudo docker volume prune -a  # 删除所有没有任何容器使用的卷
```

---

## 四、容器运行进阶选项

### 1. 命名容器
```bash
sudo docker run -d --name my_nginx nginx  # 使用 --name 给容器起一个名字
```

### 2. 交互模式
```bash
sudo docker run -it --rm alpine  # -it：让控制台进入容器进行交互，--rm：容器运行结束时自动删除
```

### 3. 重启策略
```bash
sudo docker run -d --restart always nginx  # 使用 --restart 调配容器重启时的策略
```

| 策略 | 说明 |
|------|------|
| `no` | **默认**。容器退出时不自动重启 |
| `always` | 容器总是自动重启（无论退出代码是什么） |
| `unless-stopped` | 总是自动重启，除非被手动停止 |
| `on-failure[:<重试次数>]` | 仅在容器以非零退出代码退出时重启，可指定最大重试次数 |

```bash
# 永不自动重启（默认）
docker run -d --restart no nginx

# 失败时才重启，最多重试3次
docker run -d --restart on-failure:3 nginx

# 总是重启，除非手动停止
docker run -d --restart unless-stopped nginx

# 总是重启
docker run -d --restart always nginx
```

### 4. 容器生命周期管理
```bash
# 注意：sudo docker run 每次都会创建一个新的容器
# 如果不想每次都创建新的容器，可以使用以下命令：

sudo docker stop <容器>  # 停止一个容器
sudo docker ps -a  # 查看所有容器，包括停止的容器
sudo docker start <容器ID或名字>  # 启动一个容器
sudo docker inspect <容器>  # 输出容器的各种信息，可以直接发给AI，让它回答诸如有没有做端口映射，有没有挂载卷等等
```

### 5. 创建但不启动容器
```bash
sudo docker create <镜像>  # 与 sudo docker run 命令非常相似，但是 docker create 只创建容器但是不启动
# 如果想启动的话还需要输入 docker start 命令
```

### 6. 查看日志
```bash
sudo docker logs <容器>  # 查看容器的日志
sudo docker logs <容器ID或名字> -f  # 滚动查看容器的日志
```

### 7. 在容器内执行命令
```bash
# 每个 Docker 都是一套独立的运行环境，表现的都像一个独立的 Linux 系统
# 这个命令可以在容器内部执行 Linux 命令

sudo docker exec <容器ID> <Linux命令>

# 示例：
docker exec <容器ID> ps -ef  # 查看容器内的进程（或 ps aux）
docker exec <容器ID> ls -la /app  # 查看容器内的文件列表
docker exec <容器ID> python /app/script.py  # 在容器内运行 Python 脚本
docker exec <容器ID> nginx -t  # 查看 Nginx 配置文件是否正确
```

### 8. 进入容器交互式环境
```bash
sudo docker exec -it <容器ID> /bin/sh  # 进入容器内部执行 Linux 命令

# 进入后可以执行：
cat /etc/os-release  # 查看容器内的发行版

# 其他示例：
docker exec -it <容器ID> /bin/bash  # 进入容器的 bash 环境（像 SSH 登录一样）
docker exec -it <容器ID> /bin/sh  # 如果容器没有 bash，使用 sh
```

---

## 五、Dockerfile 构建

### 1. Dockerfile 示例
```dockerfile
FROM python:3.13-slim

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt

EXPOSE 8000

CMD ["python3", "main.py"]
```

### 2. 构建镜像
```bash
docker build -t <镜像名>:<标签> <构建上下文路径>  # 从 Dockerfile 构建镜像，并为生成的镜像指定一个名称（标签）

# 示例：
docker build -t myapp .  # 构建镜像，命名为 myapp，标签为 latest（默认）
docker build -t myapp:v1.0 .  # 构建镜像，指定具体版本标签
docker build -t myapp -f ./docker/Dockerfile .  # Dockerfile 在 ./docker 目录下
docker build -t myapp -f ./Dockerfile.prod .  # 或者 Dockerfile 改名了
```

### 3. 登录与推送
```bash
docker login  # 登录 Docker Hub
docker push [选项] <镜像完整名称>  # 将本地构建的 Docker 镜像推送到远程镜像仓库（如 Docker Hub、阿里云容器镜像服务等），方便在其他机器或服务器上拉取使用
```

---

## 六、网络管理

### 1. 创建网络
```bash
sudo docker network create network1  # 创建子网
```

### 2. 列出网络
```bash
sudo docker network list  # 列出所有的网络类型
```

| 类型 | 说明 | 使用场景 |
|------|------|----------|
| bridge | 默认，容器间通过网桥通信 | 单机多容器通信 |
| host | 容器直接使用宿主机网络 | 需要高性能网络 |
| none | 容器无网络接口 | 完全隔离 |

### 3. 删除网络
```bash
sudo docker network rm network1  # 删除网络
```

---

## 七、Docker Compose

Docker Compose 用于**定义和运行多容器应用**。通过一个 YAML 文件（通常是 `docker-compose.yml`），可以一次性配置应用的所有服务、网络和卷。

### 1. 常用命令

| 命令 | 功能 | 常用场景 |
|------|------|----------|
| `docker compose up` | 创建并启动所有服务 | 首次部署或更新应用 |
| `docker compose down` | 停止并删除容器、网络 | 完全清理环境 |
| `docker compose start` | 启动已存在的服务 | 暂停后恢复 |
| `docker compose stop` | 停止服务（保留容器） | 临时暂停 |
| `docker compose restart` | 重启服务 | 配置更新后 |
| `docker compose ps` | 查看运行状态 | 检查服务健康 |
| `docker compose logs` | 查看日志 | 排查问题 |
| `docker compose exec` | 进入运行中的容器 | 调试、执行命令 |
| `docker compose build` | 重新构建镜像 | 代码更新后 |
| `docker compose pull` | 拉取最新镜像 | 更新镜像版本 |

### 2. 使用示例
```bash
# 1. 启动所有服务（后台运行）
docker compose up -d

# 使用非标准文件名
docker compose -f text.yaml up -d

# 2. 查看状态
docker compose ps

# 3. 查看日志（实时跟踪）
docker compose logs -f

# 4. 进入某个服务容器
docker compose exec web bash

# 5. 停止服务（保留容器和数据）
docker compose stop

# 6. 完全清理（删容器+网络，默认保留卷）
docker compose down

# 7. 彻底清理（包括卷）
docker compose down -v
```
