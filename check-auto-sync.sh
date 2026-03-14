#!/bin/bash

# 自动同步配置检查脚本

echo "=========================================="
echo "SkillHub 自动同步配置检查"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_file() {
    local file=$1
    local desc=$2

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc"
        return 0
    else
        echo -e "${RED}✗${NC} $desc"
        return 1
    fi
}

echo "📋 检查本地文件..."
echo ""

# 检查 skillhub 仓库文件
cd "$(dirname "$0")"

check_file ".github/workflows/trigger-image-sync.yml" "触发器 workflow 文件"
check_file ".github/workflows/publish-images.yml" "镜像发布 workflow 文件"
check_file "AUTO_SYNC_SETUP.md" "配置说明文档"

echo ""
echo "📋 检查 docker_image_pusher 仓库文件..."
echo ""

PUSHER_PATH="../docker_image_pusher"
if [ -d "$PUSHER_PATH" ]; then
    check_file "$PUSHER_PATH/.github/workflows/docker.yaml" "镜像同步 workflow 文件"
    check_file "$PUSHER_PATH/images.txt" "镜像列表文件"
else
    echo -e "${YELLOW}⚠${NC} docker_image_pusher 仓库不在预期位置"
fi

echo ""
echo "=========================================="
echo "📝 下一步操作"
echo "=========================================="
echo ""
echo "1. 创建 GitHub Personal Access Token"
echo "   访问: https://github.com/settings/tokens"
echo "   权限: repo + workflow"
echo ""
echo "2. 在 skillhub 仓库配置 Secret"
echo "   访问: https://github.com/likes1234-bro/skillhub/settings/secrets/actions"
echo "   添加: TRIGGER_TOKEN = <你的 token>"
echo ""
echo "3. 测试配置"
echo "   方法 1: 手动触发 'Trigger Image Sync' workflow"
echo "   方法 2: 推送代码到 main 分支"
echo ""
echo "4. 查看执行结果"
echo "   skillhub Actions: https://github.com/likes1234-bro/skillhub/actions"
echo "   pusher Actions: https://github.com/likes1234-bro/docker_image_pusher/actions"
echo ""
echo "详细说明请查看: AUTO_SYNC_SETUP.md"
echo ""
