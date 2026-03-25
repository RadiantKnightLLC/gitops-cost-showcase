# Image Promotion Process

> **Note**: Current deployment uses direct `kubectl apply`. Image Updater setup is documented here for future CI/CD integration.

## Promotion Strategy

### Development (Automatic)

```
CI Build → Registry → Image Updater → Git Commit → Argo CD Sync
```

- **Trigger**: New image tag pushed
- **Strategy**: `newest-build`
- **Action**: Automatic commit to gitops repo

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: sample-app=ghcr.io/RadiantKnightLLC/sample-app
  argocd-image-updater.argoproj.io/sample-app.update-strategy: newest-build
  argocd-image-updater.argoproj.io/write-back-method: git
```

### Production (PR-Gated)

```
CI Build → Registry → Image Updater → GitHub PR → Approval → Merge → Sync
```

- **Trigger**: Semantic version tag (vX.Y.Z)
- **Strategy**: `semver`
- **Action**: Create PR (requires human approval)

```yaml
annotations:
  argocd-image-updater.argoproj.io/sample-app.update-strategy: semver
```

## Image Tagging

| Environment | Tag Pattern | Example |
|-------------|-------------|---------|
| Dev | Git SHA | `sha-abc1234` |
| Prod | Semantic | `v1.2.3` |

## Current Manual Process

```bash
# Build and load to Kind
docker build -t showcase-app-p1:local .
kind load docker-image showcase-app-p1:local --name gitops-finops

# Restart deployment
kubectl rollout restart deployment dev-sample-app -n sample-app-dev
```

## Rollback

```bash
# Argo CD rollback
argocd app rollback sample-app-dev <revision-id>

# Or kubectl
kubectl rollout undo deployment/dev-sample-app -n sample-app-dev
```

See [Rollback Runbook](./rollback-runbook.md) for detailed procedures.
