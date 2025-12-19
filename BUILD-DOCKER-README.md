# Deep Research Docker 构建脚本使用文档

本文档介绍如何使用 `build-docker.sh` 脚本打包 Deep Research 项目的 Docker 镜像。

## 功能特性

该脚本支持两种构建模式：

### 1. 开源版
- 保留所有12个AI供应商选项
- 用户可以自由配置任何供应商
- 适合个人使用或需要灵活配置的场景

### 2. 分发版
- 只保留一个指定的AI供应商
- 简化配置流程
- 预设API Base URL和模型
- 支持两种运行模式：
  - **Local模式**：浏览器直接调用AI API，用户输入API Key
  - **Proxy模式**：服务端代理，API Key预设在服务端，用户只需输入访问密码

## 使用方法

### 快速开始

```bash
# 运行构建脚本
./build-docker.sh
```

脚本会交互式地引导你完成所有配置。

## 构建流程详解

### 开源版构建流程

1. 运行脚本，选择 `1) 开源版`
2. 输入镜像名称（默认：deep-research）
3. 输入镜像标签（默认：latest）
4. 等待构建完成

**构建完成后：**
```bash
# 1. 复制环境变量模板
cp env.tpl .env

# 2. 编辑 .env 文件，配置你需要的AI供应商
vim .env

# 3. 启动服务
docker-compose up -d

# 4. 访问应用
open http://localhost:3333
```

### 分发版构建流程

1. 运行脚本，选择 `2) 分发版`
2. 选择AI供应商（1-12）
3. 选择运行模式：
   - `1) Local模式`
   - `2) Proxy模式`
4. 输入API Base URL（可使用默认值）
5. 如果是Proxy模式，输入API Key
6. 配置Thinking Model（深度思考模型）
7. 配置Task Model（快速任务模型）
8. 输入镜像名称和标签
9. 确认配置并开始构建

**构建完成后会生成以下文件：**
- `Dockerfile.dist` - 分发版Dockerfile
- `docker-compose.dist.yml` - 分发版docker-compose配置
- `.env.dist` - 环境变量配置模板
- `patch-dist.sh` - 源码patch脚本（构建时使用）

## 支持的AI供应商

| 编号 | 供应商 | 默认Base URL | 默认Thinking Model | 默认Task Model |
|------|--------|--------------|-------------------|----------------|
| 1 | Google Gemini | https://generativelanguage.googleapis.com | gemini-2.5-pro | gemini-2.5-flash |
| 2 | Google Vertex AI | https://LOCATION-aiplatform.googleapis.com | gemini-2.5-pro | gemini-2.5-flash |
| 3 | OpenRouter | https://openrouter.ai/api | anthropic/claude-3.5-sonnet | anthropic/claude-3.5-haiku |
| 4 | OpenAI | https://api.openai.com | gpt-5 | gpt-5-mini |
| 5 | Anthropic Claude | https://api.anthropic.com | claude-3-5-sonnet-20250219 | claude-3-5-haiku-20250219 |
| 6 | DeepSeek | https://api.deepseek.com | deepseek-reasoner | deepseek-chat |
| 7 | XAI (Grok) | https://api.x.ai | grok-beta | grok-beta |
| 8 | Mistral AI | https://api.mistral.ai | mistral-large-latest | mistral-medium-latest |
| 9 | Azure OpenAI | https://YOUR-RESOURCE.openai.azure.com | gpt-5 | gpt-5-mini |
| 10 | OpenAI Compatible | https://api.example.com | custom-model | custom-model |
| 11 | Pollinations.ai | https://text.pollinations.ai/openai | openai | openai |
| 12 | Ollama (本地) | http://localhost:11434 | llama3.1 | llama3.1 |

## 分发版使用示例

### Local模式示例

假设你选择了OpenAI供应商，Local模式：

```bash
./build-docker.sh
# 选择: 2 (分发版)
# 供应商: 4 (OpenAI)
# 模式: 1 (Local)
# API Base URL: https://api.openai.com (使用默认)
# Thinking Model: gpt-5 (使用默认)
# Task Model: gpt-5-mini (使用默认)
# 镜像名: my-deep-research
# 标签: v1.0
```

**使用方法：**
```bash
# 启动服务
docker-compose -f docker-compose.dist.yml up -d

# 访问 http://localhost:3333
# 用户界面：
# - 只显示OpenAI供应商选项
# - API Base URL已预设为 https://api.openai.com
# - 模型已预设：gpt-5 和 gpt-5-mini
# - 用户只需输入自己的OpenAI API Key即可使用
```

### Proxy模式示例

假设你选择了DeepSeek供应商，Proxy模式：

```bash
./build-docker.sh
# 选择: 2 (分发版)
# 供应商: 6 (DeepSeek)
# 模式: 2 (Proxy)
# API Base URL: https://api.deepseek.com (使用默认)
# API Key: sk-xxxxxxxxxxxxxxxx (你的DeepSeek API Key)
# Thinking Model: deepseek-reasoner (使用默认)
# Task Model: deepseek-chat (使用默认)
# 镜像名: deepseek-research
# 标签: v1.0
```

**使用方法：**
```bash
# 1. 编辑 .env.dist，设置访问密码
echo "ACCESS_PASSWORD=my-secure-password" > .env.dist

# 注意：API Key已经在构建时预设到docker-compose.dist.yml中

# 2. 启动服务
docker-compose -f docker-compose.dist.yml up -d

# 3. 访问 http://localhost:3333
# 用户界面：
# - 只显示DeepSeek供应商选项
# - 用户输入访问密码 "my-secure-password"
# - 无需配置API Key，直接使用
```

## 运行模式对比

| 特性 | Local模式 | Proxy模式 |
|------|-----------|-----------|
| API调用位置 | 浏览器端 | 服务端 |
| 用户需要输入 | API Key | 访问密码 |
| API Key安全性 | 用户自己管理 | 预设在服务端，用户不可见 |
| 网络要求 | 用户浏览器能访问AI API | 服务器能访问AI API |
| 适用场景 | 个人使用，用户有自己的API Key | 分发给客户，统一管理API Key |

## 目录结构

构建后的项目结构：

```
deep-research/
├── build-docker.sh              # 主构建脚本
├── BUILD-DOCKER-README.md       # 本文档
├── Dockerfile                   # 开源版Dockerfile
├── docker-compose.yml           # 开源版docker-compose
├── env.tpl                      # 环境变量模板
│
# 以下文件在运行分发版构建后生成：
├── Dockerfile.dist              # 分发版Dockerfile
├── docker-compose.dist.yml      # 分发版docker-compose
├── .env.dist                    # 分发版环境变量
└── patch-dist.sh                # 源码patch脚本
```

## 常见问题

### Q1: 如何更新上游代码？

**开源版：**
```bash
git pull upstream main
./build-docker.sh
# 选择开源版重新构建
```

**分发版：**
```bash
git pull upstream main
./build-docker.sh
# 选择分发版，重新配置并构建
```

### Q2: 分发版是否可以添加其他供应商？

不可以。分发版在构建时已经通过环境变量 `NEXT_PUBLIC_DISABLED_AI_PROVIDER` 禁用了其他供应商。如果需要更换供应商，需要重新运行构建脚本。

### Q3: Proxy模式下如何更换API Key？

方法1：修改 `.env.dist` 文件中的API Key，然后重启容器：
```bash
# 编辑 .env.dist，修改对应的 API Key
docker-compose -f docker-compose.dist.yml restart
```

方法2：修改 `docker-compose.dist.yml` 中的环境变量，然后重启：
```bash
# 编辑 docker-compose.dist.yml
# 修改 environment 部分的 API Key
docker-compose -f docker-compose.dist.yml up -d
```

### Q4: 如何查看构建的镜像？

```bash
# 查看所有镜像
docker images | grep deep-research

# 查看镜像详情
docker inspect <镜像名>:<标签>
```

### Q5: 构建失败怎么办？

```bash
# 清理缓存重新构建
docker builder prune -a

# 重新运行构建脚本
./build-docker.sh
```

### Q6: 如何自定义端口？

编辑 `docker-compose.yml` 或 `docker-compose.dist.yml`：
```yaml
ports:
  - "8080:3000"  # 将3333改为你想要的端口
```

### Q7: 分发版可以设置多个模型吗？

不可以。分发版在构建时已经固定了Thinking Model和Task Model。如果需要更换模型，需要重新构建。

### Q8: Local模式和Proxy模式可以切换吗？

不可以。模式在构建时已经固定。如果需要切换模式，需要重新运行构建脚本。

## 高级用法

### 批量构建多个分发版

创建一个配置文件 `build-configs.txt`：
```
# 格式: 供应商编号|模式|镜像名|标签|API_BASE_URL|THINKING_MODEL|TASK_MODEL
4|local|openai-local|v1.0|https://api.openai.com|gpt-5|gpt-5-mini
6|proxy|deepseek-proxy|v1.0|https://api.deepseek.com|deepseek-reasoner|deepseek-chat
```

然后可以编写自动化脚本批量构建。

### 自定义模型列表

如果你想使用非默认的模型，在构建时输入自定义的模型名称即可。例如：

```
Thinking Model: gpt-o1-pro
Task Model: gpt-4-turbo
```

### 使用自定义API Base URL

如果你使用反向代理或自建API服务，可以在构建时输入自定义URL：

```
API Base URL: https://my-proxy.example.com/v1
```

## 注意事项

1. **构建时间**：首次构建需要下载依赖，可能需要10-20分钟
2. **磁盘空间**：确保有至少5GB的可用磁盘空间
3. **网络环境**：构建过程需要访问npm仓库和Docker Hub
4. **API Key安全**：
   - Local模式：API Key存储在用户浏览器中
   - Proxy模式：API Key存储在服务端环境变量中，注意保护 `.env.dist` 文件
5. **端口占用**：默认使用3333端口，确保端口未被占用
6. **Docker版本**：建议使用Docker 20.10+和Docker Compose 2.0+

## 技术原理

### 分发版实现原理

1. **供应商禁用**：通过环境变量 `NEXT_PUBLIC_DISABLED_AI_PROVIDER` 禁用未选择的供应商
2. **默认值设置**：通过 `patch-dist.sh` 脚本在构建时修改 `src/store/setting.ts` 的默认值
3. **编译时注入**：配置在构建时通过环境变量注入到Next.js应用中
4. **多阶段构建**：使用Docker多阶段构建优化镜像大小

### 文件修改说明

分发版构建过程中，`patch-dist.sh` 会临时修改以下文件（仅在Docker构建容器内）：
- `src/store/setting.ts` - 修改默认的provider、apiProxy和模型配置

**原项目代码不会被修改**，所有改动都在Docker构建容器内进行。

## 技术支持

如有问题或建议，请参考项目文档或提交Issue。

## 更新日志

- **v1.0** (2025-12-20)
  - 初始版本
  - 支持12个AI供应商
  - 支持Local和Proxy两种模式
  - 交互式构建流程
