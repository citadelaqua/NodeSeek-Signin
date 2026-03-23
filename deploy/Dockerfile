# 使用轻量级的 Python 基础镜像
FROM python:3.9-alpine

# 设置时区为 GMT+8
RUN apk add --no-cache tzdata ca-certificates
ENV TZ=Asia/Shanghai

# 设置工作目录
WORKDIR /app

# 复制 requirements.txt 并安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制 Python 包源码到工作目录（保持扁平结构，脚本间可互相导入）
COPY src/nodeseek/ ./

# 设置默认启动命令
CMD ["python", "scheduler.py"]
