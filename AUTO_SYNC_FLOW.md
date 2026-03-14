# 自动同步流程图

## 📊 完整流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    SkillHub 仓库 (skillhub)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 1. 推送代码 / 创建 Release
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Workflow: Publish Images (.github/workflows/publish-images.yml)│
│  - 构建 skillhub-server 镜像                                     │
│  - 构建 skillhub-web 镜像                                        │
│  - 推送到 ghcr.io/likes1234-bro/skillhub-*                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 2. 构建成功后触发
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Workflow: Trigger Image Sync (trigger-image-sync.yml)           │
│  - 检测 Publish Images 完成                                      │
│  - 调用 GitHub API                                               │
│  - 触发 docker_image_pusher 仓库                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 3. Repository Dispatch
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              docker_image_pusher 仓库                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 4. 接收触发事件
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Workflow: Docker (.github/workflows/docker.yaml)               │
│  - 读取 images.txt                                               │
│  - 从 Docker Hub / GHCR 拉取镜像                                 │
│  - 推送到阿里云容器镜像服务                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 5. 同步完成
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    阿里云容器镜像服务                             │
│  crpi-ptu2rqimrigtq0qx.cn-hangzhou.personal.cr.aliyuncs.com    │
│  /test1245/                                                     │
│    ├─ postgres:16-alpine                                        │
│    ├─ redis:7-alpine                                            │
│    ├─ minio_minio:latest                                        │
│    ├─ nginx:alpine                                              │
│    ├─ iflytek_skillhub-server:edge                              │
│    └─ iflytek_skillhub-web:edge                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 6. 国内用户拉取
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        国内服务器                                 │
│  docker pull crpi-ptu2rqimrigtq0qx...                           │
│  ✅ 快速完成（1-2秒）                                             │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 触发方式

### 自动触发

```
发布 Release
    ↓
Publish Images (自动)
    ↓
Trigger Image Sync (自动)
    ↓
Docker Workflow (自动)
    ↓
同步到阿里云 ✅
```

### 手动触发

#### 方式 1: 触发完整流程
```bash
# 在 skillhub 仓库
GitHub Actions → Trigger Image Sync → Run workflow
```

#### 方式 2: 直接触发同步
```bash
# 在 docker_image_pusher 仓库
GitHub Actions → Docker → Run workflow
```

#### 方式 3: 推送 images.txt
```bash
# 修改 images.txt
cd docker_image_pusher
vim images.txt
git add images.txt
git commit -m "update: 更新镜像列表"
git push
```

## 🔐 权限配置

### GitHub Personal Access Token

**需要的权限**:
- ✅ `repo` - 完整仓库访问
- ✅ `workflow` - 触发 workflow

**配置位置**:
- skillhub 仓库 → Settings → Secrets → Actions
- Secret 名称: `TRIGGER_TOKEN`

### 阿里云凭证

**需要的信息**:
- `ALIYUN_REGISTRY` - 仓库地址
- `ALIYUN_NAME_SPACE` - 命名空间
- `ALIYUN_REGISTRY_USER` - 用户名
- `ALIYUN_REGISTRY_PASSWORD` - 密码

**配置位置**:
- docker_image_pusher 仓库 → Settings → Secrets → Actions

## 📝 配置文件说明

### 1. docker_image_pusher/.github/workflows/docker.yaml

```yaml
on:
  workflow_dispatch:           # 手动触发
  push:
    branches: [ main ]         # 推送到 main 分支
  repository_dispatch:         # 外部触发 ⭐ 新增
    types: [sync-images]
```

### 2. skillhub/.github/workflows/trigger-image-sync.yml

```yaml
on:
  workflow_run:
    workflows: ["Publish Images"]  # 监听镜像发布
    types: [completed]
  workflow_dispatch:               # 支持手动触发

jobs:
  trigger-sync:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - name: Trigger docker_image_pusher
        run: |
          curl -X POST \
            -H "Authorization: token ${{ secrets.TRIGGER_TOKEN }}" \
            https://api.github.com/repos/.../docker_image_pusher/dispatches \
            -d '{"event_type":"sync-images"}'
```

## 🎯 使用场景

### 场景 1: 发布新版本

```bash
# 1. 在 skillhub 仓库创建 Release
git tag v1.0.0
git push origin v1.0.0

# 2. 在 GitHub 创建 Release
# 自动触发: Publish Images → Trigger Sync → Docker Workflow

# 3. 等待完成（约 10-20 分钟）
# 查看进度:
# - https://github.com/likes1234-bro/skillhub/actions
# - https://github.com/likes1234-bro/docker_image_pusher/actions

# 4. 验证镜像
docker pull crpi-ptu2rqimrigtq0qx.cn-hangzhou.personal.cr.aliyuncs.com/test1245/iflytek_skillhub-server:edge
```

### 场景 2: 添加新镜像

```bash
# 1. 修改 images.txt
cd docker_image_pusher
echo "new-image:latest" >> images.txt

# 2. 提交并推送
git add images.txt
git commit -m "add: 新增镜像"
git push

# 3. 自动触发同步
# 查看进度: https://github.com/likes1234-bro/docker_image_pusher/actions
```

### 场景 3: 手动同步

```bash
# 方式 1: 在 skillhub 仓库手动触发
# GitHub → Actions → Trigger Image Sync → Run workflow

# 方式 2: 在 docker_image_pusher 仓库手动触发
# GitHub → Actions → Docker → Run workflow
```

## 🔍 监控和调试

### 查看执行日志

1. **skillhub 仓库**:
   ```
   https://github.com/likes1234-bro/skillhub/actions
   ```
   - Publish Images - 镜像构建日志
   - Trigger Image Sync - 触发器日志

2. **docker_image_pusher 仓库**:
   ```
   https://github.com/likes1234-bro/docker_image_pusher/actions
   ```
   - Docker - 镜像同步日志

### 常见问题

**Q: 触发器执行了但没有同步？**
- 检查 TRIGGER_TOKEN 是否配置正确
- 查看 trigger-image-sync.yml 的执行日志
- 确认 repository_dispatch 的 event_type 匹配

**Q: 同步失败？**
- 检查阿里云凭证是否正确
- 查看 docker.yaml 的详细错误日志
- 确认镜像地址是否正确

**Q: 如何验证配置？**
- 运行 `check-auto-sync.sh` 脚本
- 手动触发 workflow 测试
- 查看 Actions 执行历史

## 📊 性能指标

### 同步时间

| 镜像大小 | 预计时间 |
|---------|---------|
| 小型 (<50MB) | 1-3 分钟 |
| 中型 (50-200MB) | 3-8 分钟 |
| 大型 (>200MB) | 8-20 分钟 |

### 触发延迟

- Publish Images 完成 → Trigger 触发: ~5-10 秒
- Trigger 触发 → Docker Workflow 开始: ~10-30 秒
- 总延迟: ~15-40 秒

## 🎉 总结

配置完成后，你的工作流程将变成：

```
开发 → 推送代码 → 自动构建 → 自动同步 → 国内可用 ✅
```

完全自动化，无需手动干预！
