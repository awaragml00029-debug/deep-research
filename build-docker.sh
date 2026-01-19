#!/bin/bash

# Deep Research Docker 打包脚本
# 支持开源版和分发版的构建

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 打印标题
print_header() {
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
}

# AI供应商列表和配置
declare -A AI_PROVIDERS=(
    ["1"]="google|Google Gemini|GOOGLE_GENERATIVE_AI|https://generativelanguage.googleapis.com|gemini-2.5-pro|gemini-2.5-flash"
    ["2"]="google-vertex|Google Vertex AI|GOOGLE_VERTEX|https://LOCATION-aiplatform.googleapis.com|gemini-2.5-pro|gemini-2.5-flash"
    ["3"]="openrouter|OpenRouter|OPENROUTER|https://openrouter.ai/api|anthropic/claude-3.5-sonnet|anthropic/claude-3.5-haiku"
    ["4"]="openai|OpenAI|OPENAI|https://api.openai.com|gpt-5|gpt-5-mini"
    ["5"]="anthropic|Anthropic Claude|ANTHROPIC|https://api.anthropic.com|claude-3-5-sonnet-20250219|claude-3-5-haiku-20250219"
    ["6"]="deepseek|DeepSeek|DEEPSEEK|https://api.deepseek.com|deepseek-reasoner|deepseek-chat"
    ["7"]="xai|XAI (Grok)|XAI|https://api.x.ai|grok-beta|grok-beta"
    ["8"]="mistral|Mistral AI|MISTRAL|https://api.mistral.ai|mistral-large-latest|mistral-medium-latest"
    ["9"]="azure|Azure OpenAI|AZURE|https://YOUR-RESOURCE.openai.azure.com|gpt-5|gpt-5-mini"
    ["10"]="openaicompatible|OpenAI Compatible|OPENAI_COMPATIBLE|https://api.example.com|custom-model|custom-model"
    ["11"]="pollinations|Pollinations.ai (Free)|POLLINATIONS|https://text.pollinations.ai/openai|openai|openai"
    ["12"]="ollama|Ollama (Local)|OLLAMA|http://localhost:11434|llama3.1|llama3.1"
)

# 显示AI供应商选择菜单
show_provider_menu() {
    print_header "选择 AI 供应商"
    echo "1)  Google Gemini"
    echo "2)  Google Vertex AI"
    echo "3)  OpenRouter"
    echo "4)  OpenAI"
    echo "5)  Anthropic Claude"
    echo "6)  DeepSeek"
    echo "7)  XAI (Grok)"
    echo "8)  Mistral AI"
    echo "9)  Azure OpenAI"
    echo "10) OpenAI Compatible"
    echo "11) Pollinations.ai (Free)"
    echo "12) Ollama (Local)"
    echo ""
}

# 获取供应商信息
get_provider_info() {
    local choice=$1
    local field=$2
    local provider_info="${AI_PROVIDERS[$choice]}"

    IFS='|' read -r provider_id provider_name env_prefix default_base_url default_thinking default_networking <<< "$provider_info"

    case $field in
        "id") echo "$provider_id" ;;
        "name") echo "$provider_name" ;;
        "env") echo "$env_prefix" ;;
        "url") echo "$default_base_url" ;;
        "thinking") echo "$default_thinking" ;;
        "networking") echo "$default_networking" ;;
    esac
}

# 主函数
main() {
    print_header "Deep Research Docker 构建脚本"

    # 步骤1: 选择版本类型
    echo "请选择构建类型："
    echo "1) 开源版 (保持所有功能，无限制)"
    echo "2) 分发版 (简化配置，只保留指定的AI供应商)"
    echo ""
    read -p "请输入选择 [1/2]: " build_type

    case $build_type in
        1)
            build_opensource
            ;;
        2)
            build_distribution
            ;;
        *)
            print_error "无效的选择！"
            exit 1
            ;;
    esac
}

# 构建开源版
build_opensource() {
    print_header "构建开源版"

    print_info "开源版将使用原有的 Dockerfile 和 docker-compose.yml"
    print_info "保持所有12个AI供应商可选"

    # 询问镜像名称
    read -p "请输入镜像名称 [deep-research]: " image_name
    image_name=${image_name:-deep-research}

    read -p "请输入镜像标签 [latest]: " image_tag
    image_tag=${image_tag:-latest}

    # 构建镜像
    print_info "开始构建 Docker 镜像: ${image_name}:${image_tag}"
    docker build -t "${image_name}:${image_tag}" .

    print_success "开源版构建完成！"
    print_info "镜像名称: ${image_name}:${image_tag}"
    echo ""
    print_info "使用方法："
    echo "  1. 复制 env.tpl 为 .env"
    echo "  2. 编辑 .env 文件，配置你需要的AI供应商"
    echo "  3. 运行: docker-compose up -d"
    echo ""
}

# 构建分发版
build_distribution() {
    print_header "构建分发版"

    # 步骤1: 选择AI供应商
    show_provider_menu
    read -p "请选择AI供应商 [1-12]: " provider_choice

    if [[ ! "$provider_choice" =~ ^[0-9]+$ ]] || [ "$provider_choice" -lt 1 ] || [ "$provider_choice" -gt 12 ]; then
        print_error "无效的选择！"
        exit 1
    fi

    PROVIDER_ID=$(get_provider_info "$provider_choice" "id")
    PROVIDER_NAME=$(get_provider_info "$provider_choice" "name")
    ENV_PREFIX=$(get_provider_info "$provider_choice" "env")
    DEFAULT_BASE_URL=$(get_provider_info "$provider_choice" "url")
    DEFAULT_THINKING=$(get_provider_info "$provider_choice" "thinking")
    DEFAULT_NETWORKING=$(get_provider_info "$provider_choice" "networking")

    print_success "已选择: $PROVIDER_NAME"

    # 步骤2: 选择模式
    echo ""
    print_header "选择运行模式"
    echo "1) Local 模式 - 浏览器直接调用AI API (用户需输入API Key)"
    echo "2) Proxy 模式 - 服务端代理调用 (API Key预设在服务端，用户只需密码)"
    echo ""
    read -p "请选择模式 [1/2]: " mode_choice

    case $mode_choice in
        1)
            MODE="local"
            print_success "已选择: Local 模式"
            ;;
        2)
            MODE="proxy"
            print_success "已选择: Proxy 模式"
            ;;
        *)
            print_error "无效的选择！"
            exit 1
            ;;
    esac

    # 步骤3: 配置API Base URL（仅Local模式需要）
    if [ "$MODE" = "local" ]; then
        echo ""
        print_info "Local模式需要配置API Base URL（前端直接调用）"
        read -p "API Base URL [${DEFAULT_BASE_URL}]: " api_base_url
        api_base_url=${api_base_url:-$DEFAULT_BASE_URL}
    else
        # Proxy模式使用环境变量配置，有默认值
        api_base_url="$DEFAULT_BASE_URL"
    fi

    # 步骤4: 配置模型
    echo ""
    print_header "配置模型"
    print_info "Thinking Model: 用于深度思考的主要模型"
    read -p "Thinking Model [${DEFAULT_THINKING}]: " thinking_model
    thinking_model=${thinking_model:-$DEFAULT_THINKING}

    print_info "Task Model: 用于快速任务的辅助模型"
    read -p "Task Model [${DEFAULT_NETWORKING}]: " networking_model
    networking_model=${networking_model:-$DEFAULT_NETWORKING}

    # 步骤6: 配置镜像名称
    echo ""
    read -p "请输入镜像名称 [deep-research-dist]: " image_name
    image_name=${image_name:-deep-research-dist}

    read -p "请输入镜像标签 [latest]: " image_tag
    image_tag=${image_tag:-latest}

    # 生成禁用列表（禁用除选中外的所有供应商）
    DISABLED_PROVIDERS=""
    for key in "${!AI_PROVIDERS[@]}"; do
        current_id=$(get_provider_info "$key" "id")
        if [ "$current_id" != "$PROVIDER_ID" ]; then
            if [ -z "$DISABLED_PROVIDERS" ]; then
                DISABLED_PROVIDERS="$current_id"
            else
                DISABLED_PROVIDERS="${DISABLED_PROVIDERS},$current_id"
            fi
        fi
    done

    # 显示配置摘要
    print_header "配置摘要"
    echo "AI 供应商: $PROVIDER_NAME ($PROVIDER_ID)"
    echo "运行模式: $MODE"
    if [ "$MODE" = "local" ]; then
        echo "API Base URL: $api_base_url"
    else
        echo "API Base URL: (运行时通过环境变量配置)"
    fi
    echo "Thinking Model: $thinking_model"
    echo "Task Model: $networking_model"
    echo "镜像名称: ${image_name}:${image_tag}"
    echo ""

    read -p "确认以上配置并开始构建？[y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "已取消构建"
        exit 0
    fi

    # 生成分发版文件
    generate_dist_files

    # 构建镜像
    print_info "开始构建分发版 Docker 镜像..."
    docker build -f Dockerfile.dist -t "${image_name}:${image_tag}" \
        --build-arg DISABLED_PROVIDERS="$DISABLED_PROVIDERS" \
        --build-arg DEFAULT_PROVIDER="$PROVIDER_ID" \
        --build-arg DEFAULT_MODE="$MODE" \
        --build-arg API_BASE_URL="$api_base_url" \
        --build-arg THINKING_MODEL="$thinking_model" \
        --build-arg NETWORKING_MODEL="$networking_model" \
        --build-arg DIST_MODE="$MODE" \
        .

    print_success "分发版构建完成！"
    print_info "镜像名称: ${image_name}:${image_tag}"

    # 显示使用说明
    show_usage_instructions
}

# 生成分发版文件
generate_dist_files() {
    print_info "生成分发版配置文件..."

    # 生成源码patch脚本
    cat > patch-dist.sh << 'PATCHEOF'
#!/bin/sh
# 分发版源码patch脚本 - 设置默认值

PROVIDER_ID="$1"
API_BASE_URL="$2"
THINKING_MODEL="$3"
NETWORKING_MODEL="$4"

SETTING_FILE="src/store/setting.ts"

echo "正在为分发版设置默认值..."
echo "Provider: $PROVIDER_ID"
echo "API Base URL: $API_BASE_URL"
echo "Thinking Model: $THINKING_MODEL"
echo "Networking Model: $NETWORKING_MODEL"

# 根据不同的provider设置对应的字段名
case "$PROVIDER_ID" in
    "google")
        API_KEY_FIELD="apiKey"
        API_PROXY_FIELD="apiProxy"
        THINKING_FIELD="thinkingModel"
        NETWORKING_FIELD="networkingModel"
        ;;
    "google-vertex")
        API_KEY_FIELD="googleVertexProject"
        API_PROXY_FIELD="googleVertexLocation"
        THINKING_FIELD="googleVertexThinkingModel"
        NETWORKING_FIELD="googleVertexNetworkingModel"
        ;;
    "openrouter")
        API_KEY_FIELD="openRouterApiKey"
        API_PROXY_FIELD="openRouterApiProxy"
        THINKING_FIELD="openRouterThinkingModel"
        NETWORKING_FIELD="openRouterNetworkingModel"
        ;;
    "openai")
        API_KEY_FIELD="openAIApiKey"
        API_PROXY_FIELD="openAIApiProxy"
        THINKING_FIELD="openAIThinkingModel"
        NETWORKING_FIELD="openAINetworkingModel"
        ;;
    "anthropic")
        API_KEY_FIELD="anthropicApiKey"
        API_PROXY_FIELD="anthropicApiProxy"
        THINKING_FIELD="anthropicThinkingModel"
        NETWORKING_FIELD="anthropicNetworkingModel"
        ;;
    "deepseek")
        API_KEY_FIELD="deepseekApiKey"
        API_PROXY_FIELD="deepseekApiProxy"
        THINKING_FIELD="deepseekThinkingModel"
        NETWORKING_FIELD="deepseekNetworkingModel"
        ;;
    "xai")
        API_KEY_FIELD="xAIApiKey"
        API_PROXY_FIELD="xAIApiProxy"
        THINKING_FIELD="xAIThinkingModel"
        NETWORKING_FIELD="xAINetworkingModel"
        ;;
    "mistral")
        API_KEY_FIELD="mistralApiKey"
        API_PROXY_FIELD="mistralApiProxy"
        THINKING_FIELD="mistralThinkingModel"
        NETWORKING_FIELD="mistralNetworkingModel"
        ;;
    "azure")
        API_KEY_FIELD="azureApiKey"
        API_PROXY_FIELD="azureResourceName"
        THINKING_FIELD="azureThinkingModel"
        NETWORKING_FIELD="azureNetworkingModel"
        ;;
    "openaicompatible")
        API_KEY_FIELD="openAICompatibleApiKey"
        API_PROXY_FIELD="openAICompatibleApiProxy"
        THINKING_FIELD="openAICompatibleThinkingModel"
        NETWORKING_FIELD="openAICompatibleNetworkingModel"
        ;;
    "pollinations")
        API_KEY_FIELD="pollinationsApiProxy"
        API_PROXY_FIELD="pollinationsApiProxy"
        THINKING_FIELD="pollinationsThinkingModel"
        NETWORKING_FIELD="pollinationsNetworkingModel"
        ;;
    "ollama")
        API_KEY_FIELD="ollamaApiProxy"
        API_PROXY_FIELD="ollamaApiProxy"
        THINKING_FIELD="ollamaThinkingModel"
        NETWORKING_FIELD="ollamaNetworkingModel"
        ;;
esac

# 修改默认provider
sed -i "s/provider: \"google\",/provider: \"$PROVIDER_ID\",/" "$SETTING_FILE"

# 修改API Proxy默认值
sed -i "s|$API_PROXY_FIELD: \"\",|$API_PROXY_FIELD: \"$API_BASE_URL\",|" "$SETTING_FILE"

# 修改模型默认值
sed -i "s|$THINKING_FIELD: \"[^\"]*\",|$THINKING_FIELD: \"$THINKING_MODEL\",|" "$SETTING_FILE"
sed -i "s|$NETWORKING_FIELD: \"[^\"]*\",|$NETWORKING_FIELD: \"$NETWORKING_MODEL\",|" "$SETTING_FILE"

# 也修改全局的默认模型
sed -i "s|thinkingModel: \"[^\"]*\",|thinkingModel: \"$THINKING_MODEL\",|" "$SETTING_FILE"
sed -i "s|networkingModel: \"[^\"]*\",|networkingModel: \"$NETWORKING_MODEL\",|" "$SETTING_FILE"

echo "默认值设置完成"
PATCHEOF

    chmod +x patch-dist.sh

    # 生成 Dockerfile.dist
    cat > Dockerfile.dist << 'EOF'
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json pnpm-lock.yaml ./
RUN yarn global add pnpm && pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 构建参数
ARG DISABLED_PROVIDERS
ARG DEFAULT_PROVIDER
ARG DEFAULT_MODE
ARG API_BASE_URL
ARG THINKING_MODEL
ARG NETWORKING_MODEL
ARG DIST_MODE

# 应用分发版patch（修改默认值）
COPY patch-dist.sh ./
RUN chmod +x patch-dist.sh && \
    ./patch-dist.sh "$DEFAULT_PROVIDER" "$API_BASE_URL" "$THINKING_MODEL" "$NETWORKING_MODEL"

# 设置环境变量（构建时注入）
ENV NEXT_PUBLIC_DISABLED_AI_PROVIDER=$DISABLED_PROVIDERS
ENV NEXT_PUBLIC_DIST_MODE=$DIST_MODE

RUN yarn run build:standalone

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_PUBLIC_BUILD_MODE=standalone

# 复制构建参数到运行时
ARG DISABLED_PROVIDERS
ARG DEFAULT_PROVIDER
ARG DEFAULT_MODE
ARG API_BASE_URL
ARG THINKING_MODEL
ARG NETWORKING_MODEL
ARG DIST_MODE

ENV NEXT_PUBLIC_DISABLED_AI_PROVIDER=$DISABLED_PROVIDERS
ENV NEXT_PUBLIC_DEFAULT_PROVIDER=$DEFAULT_PROVIDER
ENV NEXT_PUBLIC_DEFAULT_MODE=$DEFAULT_MODE
ENV NEXT_PUBLIC_DEFAULT_API_BASE_URL=$API_BASE_URL
ENV NEXT_PUBLIC_DEFAULT_THINKING_MODEL=$THINKING_MODEL
ENV NEXT_PUBLIC_DEFAULT_NETWORKING_MODEL=$NETWORKING_MODEL
ENV NEXT_PUBLIC_DIST_MODE=$DIST_MODE

# Automatically leverage output traces to reduce image size
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000

CMD ["node", "server.js"]
EOF

    # 生成 docker-compose.dist.yml（使用 environment 配置，一个文件搞定）
    if [ "$MODE" = "proxy" ]; then
        cat > docker-compose.dist.yml << EOF
version: "3.9"
services:
  deep-research:
    build:
      context: .
      dockerfile: Dockerfile.dist
      args:
        DISABLED_PROVIDERS: "$DISABLED_PROVIDERS"
        DEFAULT_PROVIDER: "$PROVIDER_ID"
        DEFAULT_MODE: "$MODE"
        API_BASE_URL: "$api_base_url"
        THINKING_MODEL: "$thinking_model"
        NETWORKING_MODEL: "$networking_model"
        DIST_MODE: "$MODE"
    image: ${image_name}:${image_tag}
    container_name: deep-research-dist
    ports:
      - "3333:3000"
    restart: unless-stopped
    environment:
      # ========== Proxy 模式配置 ==========
      # 访问密码（必填）- 最终用户需要输入此密码
      - ACCESS_PASSWORD=your-password-here
      # ${PROVIDER_NAME} API Key（必填）
      - ${ENV_PREFIX}_API_KEY=your-api-key-here
      # API Base URL（可选，有默认值）
      # - ${ENV_PREFIX}_API_BASE_URL=https://your-custom-url
      # MCP 配置
      - MCP_AI_PROVIDER=${PROVIDER_ID}
      - MCP_THINKING_MODEL=${thinking_model}
      - MCP_TASK_MODEL=${networking_model}
EOF
    else
        cat > docker-compose.dist.yml << EOF
version: "3.9"
services:
  deep-research:
    build:
      context: .
      dockerfile: Dockerfile.dist
      args:
        DISABLED_PROVIDERS: "$DISABLED_PROVIDERS"
        DEFAULT_PROVIDER: "$PROVIDER_ID"
        DEFAULT_MODE: "$MODE"
        API_BASE_URL: "$api_base_url"
        THINKING_MODEL: "$thinking_model"
        NETWORKING_MODEL: "$networking_model"
        DIST_MODE: "$MODE"
    image: ${image_name}:${image_tag}
    container_name: deep-research-dist
    ports:
      - "3333:3000"
    restart: unless-stopped
    environment:
      # ========== Local 模式配置 ==========
      # 访问密码（可选）
      - ACCESS_PASSWORD=
      # 用户在浏览器界面输入 API Key 即可使用
EOF
    fi

    print_success "配置文件生成完成："
    echo "  - Dockerfile.dist"
    echo "  - docker-compose.dist.yml"
    echo "  - patch-dist.sh"
}

# 显示使用说明
show_usage_instructions() {
    echo ""
    print_header "使用说明"

    if [ "$MODE" = "proxy" ]; then
        echo "📦 Proxy 模式 - 服务端代理"
        echo ""
        echo "1. 编辑 docker-compose.dist.yml，配置 environment 部分："
        echo "   ${YELLOW}ACCESS_PASSWORD=your-secure-password${NC}  （最终用户需要输入的密码）"
        echo "   ${YELLOW}${ENV_PREFIX}_API_KEY=your-api-key${NC}  （你的 ${PROVIDER_NAME} API Key）"
        echo ""
        echo "2. 启动服务："
        echo "   ${BLUE}docker-compose -f docker-compose.dist.yml up -d${NC}"
        echo ""
        echo "3. 访问 http://localhost:3333"
        echo ""
        echo "4. 最终用户只需要输入访问密码即可使用"
        echo "   ${GREEN}API Key 已在服务端配置，用户无需知道${NC}"
    else
        echo "🌐 Local 模式 - 浏览器直接调用"
        echo ""
        echo "1. 启动服务："
        echo "   ${BLUE}docker-compose -f docker-compose.dist.yml up -d${NC}"
        echo ""
        echo "2. 访问 http://localhost:3333"
        echo ""
        echo "3. 用户需要在界面输入："
        echo "   - API Key (必填)"
        echo "   ${GREEN}API Base URL 已预设为: ${api_base_url}${NC}"
        echo "   ${GREEN}模型已预设: Thinking=${thinking_model}, Task=${networking_model}${NC}"
    fi

    echo ""
    echo "✨ 特性："
    echo "  - 只显示 ${PROVIDER_NAME} 选项，其他供应商已隐藏"
    echo "  - 模型配置已固定，用户无需选择"
    echo "  - 简化的配置流程"
    echo ""
}

# 执行主函数
main
