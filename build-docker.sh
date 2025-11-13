#!/bin/bash

# Docker Build Script for Deep Research
# Supports both open source and distribution builds

set -e

echo "=================================="
echo "  Deep Research Docker Builder"
echo "=================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to validate URL
validate_url() {
    local url=$1
    if [[ $url =~ ^https?:// ]]; then
        return 0
    else
        return 1
    fi
}

echo "请选择构建版本 / Please select build variant:"
echo ""
echo "1) 开源版 (Open Source) - 包含所有 AI Provider 支持"
echo "2) 分发版 (Distribution) - 仅包含 modAI Provider"
echo ""
read -p "请输入选项 (1 或 2) / Enter option (1 or 2): " build_choice

case $build_choice in
    1)
        BUILD_VARIANT="open"
        IMAGE_TAG="deep-research:latest"
        print_info "选择了开源版构建 / Selected open source build"

        print_info "开始构建 Docker 镜像..."
        docker build -t "$IMAGE_TAG" \
            --build-arg BUILD_VARIANT=open \
            .

        print_success "构建完成！/ Build completed!"
        print_info "镜像标签 / Image tag: $IMAGE_TAG"
        echo ""
        print_info "运行命令 / Run command:"
        echo "  docker run -p 3000:3000 $IMAGE_TAG"
        ;;

    2)
        BUILD_VARIANT="distribution"
        print_info "选择了分发版构建 / Selected distribution build"
        echo ""

        # Get API Base URL
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "配置 modAI API 基础 URL / Configure modAI API Base URL"
        echo ""
        read -p "请输入 API Base URL (默认: https://generativelanguage.googleapis.com): " api_url
        api_url=${api_url:-https://generativelanguage.googleapis.com}

        # Validate URL
        if ! validate_url "$api_url"; then
            print_error "无效的 URL 格式 / Invalid URL format"
            exit 1
        fi

        print_success "API URL: $api_url"
        echo ""

        # Get Thinking Model
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "配置默认 Thinking Model / Configure default Thinking Model"
        echo ""
        print_warning "这是用于深度思考和复杂推理的模型"
        print_warning "This is the model for deep thinking and complex reasoning"
        echo ""
        read -p "请输入 Thinking Model (默认: gemini-2.0-flash-thinking-exp-01-21): " thinking_model
        thinking_model=${thinking_model:-gemini-2.0-flash-thinking-exp-01-21}

        print_success "Thinking Model: $thinking_model"
        echo ""

        # Get Networking Model
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "配置默认 Networking Model / Configure default Networking Model"
        echo ""
        print_warning "这是用于网络搜索和快速任务的模型"
        print_warning "This is the model for web search and quick tasks"
        echo ""
        read -p "请输入 Networking Model (默认: gemini-2.0-flash-exp): " networking_model
        networking_model=${networking_model:-gemini-2.0-flash-exp}

        print_success "Networking Model: $networking_model"
        echo ""

        # Get Image Tag
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "配置 Docker 镜像标签 / Configure Docker image tag"
        echo ""
        read -p "请输入镜像标签 (默认: deep-research:distribution): " image_tag
        IMAGE_TAG=${image_tag:-deep-research:distribution}

        print_success "镜像标签 / Image tag: $IMAGE_TAG"
        echo ""

        # Confirm build
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "构建配置确认 / Build Configuration Confirmation"
        echo ""
        echo "  版本类型 / Build Variant: distribution"
        echo "  API URL: $api_url"
        echo "  Thinking Model: $thinking_model"
        echo "  Networking Model: $networking_model"
        echo "  镜像标签 / Image Tag: $IMAGE_TAG"
        echo ""
        read -p "确认构建？(y/n) / Confirm build? (y/n): " confirm

        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_warning "构建已取消 / Build cancelled"
            exit 0
        fi

        echo ""
        print_info "开始构建 Docker 镜像... / Starting Docker build..."
        echo ""

        # Build Docker image
        docker build -t "$IMAGE_TAG" \
            --build-arg BUILD_VARIANT=distribution \
            --build-arg MODAI_API_BASE_URL="$api_url" \
            --build-arg MODAI_THINKING_MODEL="$thinking_model" \
            --build-arg MODAI_NETWORKING_MODEL="$networking_model" \
            .

        print_success "构建完成！/ Build completed!"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "镜像信息 / Image Information"
        echo ""
        echo "  镜像标签 / Image tag: $IMAGE_TAG"
        echo "  版本类型 / Build variant: distribution"
        echo "  API URL: $api_url"
        echo "  Thinking Model: $thinking_model"
        echo "  Networking Model: $networking_model"
        echo ""
        print_info "运行命令 / Run command:"
        echo ""
        echo "  docker run -p 3000:3000 $IMAGE_TAG"
        echo ""
        print_warning "注意：用户仍需在 Settings 中配置 API Key"
        print_warning "Note: Users still need to configure API Key in Settings"
        ;;

    *)
        print_error "无效的选项 / Invalid option"
        exit 1
        ;;
esac

echo ""
echo "=================================="
print_success "全部完成！/ All done!"
echo "=================================="
