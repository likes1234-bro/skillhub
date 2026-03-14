#!/bin/bash

# SkillHub 阿里云镜像部署测试脚本
# 用于模拟国内服务器环境测试部署

set -e

echo "=========================================="
echo "SkillHub 阿里云镜像部署测试"
echo "=========================================="
echo ""

# 保存当前代理设置
OLD_HTTP_PROXY="${http_proxy:-}"
OLD_HTTPS_PROXY="${https_proxy:-}"
OLD_ALL_PROXY="${all_proxy:-}"

echo "📋 步骤 1: 保存并关闭代理设置"
echo "原代理设置:"
echo "  http_proxy: ${OLD_HTTP_PROXY:-未设置}"
echo "  https_proxy: ${OLD_HTTPS_PROXY:-未设置}"
echo "  all_proxy: ${OLD_ALL_PROXY:-未设置}"
echo ""

# 关闭代理
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset all_proxy
unset ALL_PROXY

echo "✅ 代理已关闭"
echo ""

# 清理函数
cleanup() {
    echo ""
    echo "=========================================="
    echo "📋 清理和恢复"
    echo "=========================================="

    # 恢复代理设置
    if [ -n "$OLD_HTTP_PROXY" ]; then
        export http_proxy="$OLD_HTTP_PROXY"
        export HTTP_PROXY="$OLD_HTTP_PROXY"
        echo "✅ 已恢复 http_proxy"
    fi

    if [ -n "$OLD_HTTPS_PROXY" ]; then
        export https_proxy="$OLD_HTTPS_PROXY"
        export HTTPS_PROXY="$OLD_HTTPS_PROXY"
        echo "✅ 已恢复 https_proxy"
    fi

    if [ -n "$OLD_ALL_PROXY" ]; then
        export all_proxy="$OLD_ALL_PROXY"
        export ALL_PROXY="$OLD_ALL_PROXY"
        echo "✅ 已恢复 all_proxy"
    fi
}

# 设置退出时自动清理
trap cleanup EXIT

echo "📋 步骤 2: 检查 Docker 环境"
docker --version || { echo "❌ Docker 未安装"; exit 1; }
docker compose version || { echo "❌ Docker Compose 未安装"; exit 1; }
echo "✅ Docker 环境正常"
echo ""

echo "📋 步骤 3: 检查现有容器"
echo "运行中的容器:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
echo ""

echo "📋 步骤 4: 测试访问 GitHub"
echo "测试下载部署脚本..."
if curl -fsSL --connect-timeout 10 https://raw.githubusercontent.com/likes1234-bro/skillhub/main/scripts/runtime.sh -o /tmp/runtime-test.sh; then
    echo "✅ 可以访问 GitHub"
    rm -f /tmp/runtime-test.sh
else
    echo "⚠️  无法访问 GitHub (这是预期的，模拟国内环境)"
fi
echo ""

echo "📋 步骤 5: 测试拉取阿里云镜像"
echo "测试拉取 PostgreSQL 镜像..."
time docker pull crpi-ptu2rqimrigtq0qx.cn-hangzhou.personal.cr.aliyuncs.com/test1245/postgres:16-alpine || {
    echo "❌ 拉取阿里云镜像失败"
    echo "可能原因:"
    echo "  1. 镜像尚未同步完成"
    echo "  2. 镜像仓库是私有的，需要登录"
    echo "  3. 网络问题"
    exit 1
}
echo "✅ 阿里云镜像拉取成功"
echo ""

echo "📋 步骤 6: 对比镜像拉取速度"
echo "清理测试镜像..."
docker rmi redis:7-alpine 2>/dev/null || true

echo ""
echo "测试 1: 拉取 Docker Hub 官方镜像 (redis:7-alpine)"
time docker pull redis:7-alpine

echo ""
echo "测试 2: 拉取阿里云镜像 (redis:7-alpine)"
docker rmi crpi-ptu2rqimrigtq0qx.cn-hangzhou.personal.cr.aliyuncs.com/test1245/redis:7-alpine 2>/dev/null || true
time docker pull crpi-ptu2rqimrigtq0qx.cn-hangzhou.personal.cr.aliyuncs.com/test1245/redis:7-alpine

echo ""
echo "=========================================="
echo "📊 测试总结"
echo "=========================================="
echo "✅ Docker 环境正常"
echo "✅ 阿里云镜像可以正常拉取"
echo "✅ 镜像拉取速度对比完成"
echo ""
echo "💡 提示:"
echo "  - 如果 GitHub 无法访问，说明成功模拟了国内环境"
echo "  - 阿里云镜像应该比 Docker Hub 快很多"
echo "  - 如果阿里云镜像拉取失败，请检查镜像是否设置为公开"
echo ""
echo "🚀 下一步:"
echo "  如果测试通过，可以运行完整部署:"
echo "  curl -fsSL https://raw.githubusercontent.com/likes1234-bro/skillhub/main/scripts/runtime.sh | sh -s -- up"
echo ""
