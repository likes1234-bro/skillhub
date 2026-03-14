# 自动同步镜像到阿里云配置指南

本文档说明如何配置 SkillHub 仓库，使其在推送镜像到 GitHub Container Registry 后，自动触发阿里云镜像同步。

## 🎯 工作流程

```
SkillHub 仓库推送代码
    ↓
构建并推送镜像到 GHCR (publish-images.yml)
    ↓
触发 docker_image_pusher 仓库 (trigger-image-sync.yml)
    ↓
同步镜像到阿里云 (docker.yaml)
    ↓
完成！
```

## 📋 配置步骤

### 1. 创建 GitHub Personal Access Token

1. 访问 GitHub Settings: https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 设置 Token 名称: `skillhub-trigger-token`
4. 选择权限:
   - ✅ `repo` (完整仓库访问权限)
   - ✅ `workflow` (触发 workflow 权限)
5. 点击 "Generate token"
6. **复制生成的 token**（只显示一次！）

### 2. 在 skillhub 仓库配置 Secret

1. 进入 skillhub 仓库: https://github.com/likes1234-bro/skillhub
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**
4. 配置:
   - Name: `TRIGGER_TOKEN`
   - Secret: 粘贴刚才复制的 token
5. 点击 **Add secret**

### 3. 验证配置

#### 方法 1: 手动触发测试

```bash
# 在 skillhub 仓库
cd D:\06-base\github\skillhub

# 进入 Actions 页面，手动触发 "Trigger Image Sync" workflow
# https://github.com/likes1234-bro/skillhub/actions
```

#### 方法 2: 推送代码测试

```bash
# 修改任意文件
echo "test" >> README.md

# 提交并推送
git add .
git commit -m "test: 测试自动同步"
git push origin main

# 观察 Actions 执行情况
```

### 4. 查看执行结果

1. **skillhub 仓库 Actions**:
   - https://github.com/likes1234-bro/skillhub/actions
   - 查看 "Publish Images" 和 "Trigger Image Sync" 的执行状态

2. **docker_image_pusher 仓库 Actions**:
   - https://github.com/likes1234-bro/docker_image_pusher/actions
   - 查看 "Docker" workflow 的执行状态

## 🔧 已创建的文件

### 1. docker_image_pusher/.github/workflows/docker.yaml

添加了 `repository_dispatch` 触发器：

```yaml
on:
  workflow_dispatch:
  push:
    branches: [ main ]
  repository_dispatch:
    types: [sync-images]  # 新增：允许外部触发
```

### 2. skillhub/.github/workflows/trigger-image-sync.yml

新建的触发器 workflow：

```yaml
name: Trigger Image Sync

on:
  workflow_run:
    workflows: ["Publish Images"]  # 监听镜像发布完成
    types:
      - completed
  workflow_dispatch:  # 支持手动触发

jobs:
  trigger-sync:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}

    steps:
      - name: Trigger docker_image_pusher workflow
        run: |
          curl -X POST \
            -H "Authorization: token ${{ secrets.TRIGGER_TOKEN }}" \
            https://api.github.com/repos/${{ github.repository_owner }}/docker_image_pusher/dispatches \
            -d '{"event_type":"sync-images"}'
```

## 📊 触发时机

自动同步会在以下情况触发：

1. **发布新版本**
   - 创建 GitHub Release 时
   - "Publish Images" workflow 成功完成后

2. **手动触发**
   - 在 skillhub 仓库手动运行 "Trigger Image Sync"
   - 在 docker_image_pusher 仓库手动运行 "Docker"

3. **推送到 docker_image_pusher**
   - 修改 `images.txt` 并推送到 main 分支

## 🔍 故障排查

### 问题 1: 触发失败，提示 401 Unauthorized

**原因**: TRIGGER_TOKEN 配置错误或权限不足

**解决方案**:
1. 检查 token 是否正确配置
2. 确认 token 有 `repo` 和 `workflow` 权限
3. 重新生成 token 并更新 Secret

### 问题 2: 触发成功但 docker_image_pusher 没有执行

**原因**: repository_dispatch 配置错误

**解决方案**:
1. 检查 docker.yaml 中的 `repository_dispatch` 配置
2. 确认 `event_type` 匹配（都是 `sync-images`）
3. 查看 docker_image_pusher 的 Actions 日志

### 问题 3: 镜像同步失败

**原因**: 阿里云凭证配置问题

**解决方案**:
1. 检查 docker_image_pusher 仓库的 Secrets:
   - ALIYUN_REGISTRY
   - ALIYUN_NAME_SPACE
   - ALIYUN_REGISTRY_USER
   - ALIYUN_REGISTRY_PASSWORD
2. 确认阿里云凭证是否有效
3. 查看详细的错误日志

## 📝 最佳实践

### 1. 版本管理

建议在 `images.txt` 中使用具体的版本标签：

```
# 推荐：使用具体版本
ghcr.io/iflytek/skillhub-server:v1.0.0
ghcr.io/iflytek/skillhub-web:v1.0.0

# 不推荐：使用 latest 或 edge（会频繁更新）
ghcr.io/iflytek/skillhub-server:edge
```

### 2. 监控同步状态

定期检查：
- GitHub Actions 执行历史
- 阿里云镜像仓库的镜像列表
- 镜像的更新时间

### 3. 通知设置

在 GitHub 仓库设置中启用 Actions 失败通知：
- Settings → Notifications → Actions
- 勾选 "Send notifications for failed workflows"

## 🎉 完成

配置完成后，每次 skillhub 仓库发布新版本时，都会自动：

1. ✅ 构建并推送镜像到 GHCR
2. ✅ 触发 docker_image_pusher 同步
3. ✅ 将镜像同步到阿里云
4. ✅ 国内用户可以快速拉取

## 🔗 相关链接

- SkillHub 仓库: https://github.com/likes1234-bro/skillhub
- 镜像同步仓库: https://github.com/likes1234-bro/docker_image_pusher
- GitHub Actions 文档: https://docs.github.com/en/actions
- Repository Dispatch 文档: https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event
