# Docker 构建指南 / Docker Build Guide

## 快速开始 / Quick Start

使用交互式脚本构建 Docker 镜像：

```bash
./build-docker.sh
```

## 构建选项 / Build Options

### 1. 开源版 (Open Source)

包含所有 AI Provider 支持，适合开发和自托管使用。

**特点：**
- ✅ 支持所有 AI Provider（Google, OpenAI, Anthropic, DeepSeek, xAI, Mistral 等）
- ✅ 完整的配置选项
- ✅ Local 和 Proxy 两种模式

**构建命令：**
```bash
./build-docker.sh
# 选择: 1) 开源版 (Open Source)
```

**或手动构建：**
```bash
docker build -t deep-research:latest .
```

**运行：**
```bash
docker run -p 3000:3000 deep-research:latest
```

---

### 2. 分发版 (Distribution)

仅包含 modAI Provider，适合企业分发和简化部署。

**特点：**
- ✅ 只显示 modAI Provider
- ✅ 只使用 Local 模式
- ✅ API URL 和默认模型在构建时配置
- ✅ 用户只需配置 API Key
- ✅ 更简洁的用户界面

**构建流程：**

1. 运行脚本：
```bash
./build-docker.sh
```

2. 选择 `2) 分发版 (Distribution)`

3. 按照提示输入配置：
   - **API Base URL**: 你的 API 服务地址
   - **Thinking Model**: 用于深度思考的模型
   - **Networking Model**: 用于快速任务的模型
   - **Image Tag**: Docker 镜像标签

**示例配置：**
```
API Base URL: https://generativelanguage.googleapis.com
Thinking Model: gemini-2.0-flash-thinking-exp-01-21
Networking Model: gemini-2.0-flash-exp
Image Tag: deep-research:distribution
```

**或手动构建：**
```bash
docker build -t deep-research:distribution \
  --build-arg BUILD_VARIANT=distribution \
  --build-arg MODAI_API_BASE_URL=https://generativelanguage.googleapis.com \
  --build-arg MODAI_THINKING_MODEL=gemini-2.0-flash-thinking-exp-01-21 \
  --build-arg MODAI_NETWORKING_MODEL=gemini-2.0-flash-exp \
  .
```

**运行：**
```bash
docker run -p 3000:3000 deep-research:distribution
```

---

## Docker Compose 部署 / Docker Compose Deployment

### 开源版 / Open Source

```bash
docker-compose up -d
```

### 分发版 / Distribution

1. 编辑 `docker-compose.distribution.yml`，修改构建参数：

```yaml
services:
  deep-research-distribution:
    build:
      args:
        BUILD_VARIANT: distribution
        MODAI_API_BASE_URL: https://your-api-url.com
        MODAI_THINKING_MODEL: your-thinking-model
        MODAI_NETWORKING_MODEL: your-networking-model
```

2. 启动服务：

```bash
docker-compose -f docker-compose.distribution.yml up -d
```

---

## 环境变量配置 / Environment Variables

### 构建时配置 (Build-time)

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `BUILD_VARIANT` | 构建类型: `open` 或 `distribution` | `open` |
| `MODAI_API_BASE_URL` | modAI API 基础 URL | `https://generativelanguage.googleapis.com` |
| `MODAI_THINKING_MODEL` | 默认思考模型 | `gemini-2.0-flash-thinking-exp-01-21` |
| `MODAI_NETWORKING_MODEL` | 默认网络模型 | `gemini-2.0-flash-exp` |

### 运行时配置 (Runtime)

```bash
docker run -p 3000:3000 \
  -e MODAI_API_BASE_URL=https://your-api-url.com \
  deep-research:distribution
```

**注意：** 运行时只能修改 `MODAI_API_BASE_URL`，模型配置已固化在镜像中。

---

## 脚本功能说明 / Script Features

`build-docker.sh` 脚本提供了以下功能：

✅ **交互式界面** - 友好的中英文双语提示
✅ **输入验证** - 自动验证 URL 格式
✅ **默认值** - 提供合理的默认配置
✅ **构建确认** - 构建前显示完整配置供确认
✅ **彩色输出** - 使用颜色区分信息类型
✅ **错误处理** - 遇到错误时自动停止

---

## 常见问题 / FAQ

### Q: 如何更改分发版的模型？

A: 模型配置在构建时固化到镜像中，需要重新构建：

```bash
./build-docker.sh
# 选择分发版，输入新的模型配置
```

### Q: 可以在运行时更改 API URL 吗？

A: 可以，使用环境变量覆盖：

```bash
docker run -p 3000:3000 \
  -e MODAI_API_BASE_URL=https://new-api-url.com \
  deep-research:distribution
```

### Q: 如何查看镜像的构建配置？

A: 使用 docker inspect：

```bash
docker inspect deep-research:distribution | grep -A 5 "ENV"
```

### Q: 分发版用户如何配置 API Key？

A: 用户访问应用后，在 Settings 页面中只需填写 API Key 即可，其他配置已预设。

---

## 镜像大小优化 / Image Size Optimization

构建的镜像使用了多阶段构建和 Next.js standalone 输出，已经过优化：

- 使用 `node:18-alpine` 基础镜像
- 多阶段构建减少最终镜像大小
- Next.js standalone 输出仅包含必要文件

---

## 安全建议 / Security Recommendations

1. **不要在镜像中硬编码 API Key**
2. **使用环境变量或密钥管理服务**
3. **定期更新基础镜像**
4. **扫描镜像漏洞**

```bash
# 使用 Docker Scout 扫描
docker scout quickview deep-research:distribution
```

---

## 技术支持 / Support

如有问题，请访问：
- GitHub Issues: https://github.com/u14app/deep-research/issues
- 文档: https://github.com/u14app/deep-research

---

## License

MIT License - See LICENSE file for details
