# Image Promotion Process

## Overview

This document describes the automated image promotion workflow using Argo CD Image Updater.

## Promotion Strategy

### Development (Automatic)

```
CI Build → Container Registry → Image Updater → Git Commit → Argo CD Sync
```

- **Trigger**: New image tag pushed to registry (any tag)
- **Strategy**: `newest-build` - Uses the most recently built image
- **Action**: Automatic commit to gitops repo
- **Gate**: None - immediate deployment to dev

**Configuration:**
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: sample-app=ghcr.io/RadiantKnightLLC/sample-app
  argocd-image-updater.argoproj.io/sample-app.update-strategy: newest-build
  argocd-image-updater.argoproj.io/write-back-method: git
  argocd-image-updater.argoproj.io/git-branch: main
```

### Production (PR-Gated)

```
CI Build (semver tag) → Container Registry → Image Updater → GitHub PR → Approval → Merge → Argo CD Sync
```

- **Trigger**: New semantic version tag (vX.Y.Z)
- **Strategy**: `semver` - Uses semantic versioning
- **Action**: Create PR in gitops repo
- **Gate**: Human approval required

**Configuration:**
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: sample-app=ghcr.io/RadiantKnightLLC/sample-app
  argocd-image-updater.argoproj.io/sample-app.update-strategy: semver
  # NO write-back-method - Image Updater creates PR via GitHub API
```

## Approval Criteria for Production

- [ ] Image tag is semantic version (vX.Y.Z), not SHA or "latest"
- [ ] Dev environment has been stable for > 1 hour
- [ ] No critical alerts in monitoring
- [ ] Within change window (if applicable)
- [ ] Code review approved

## Flow Diagram

```
┌─────────────────┐
│  Developer      │
│  pushes code    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  CI Pipeline    │
│  - Build image  │
│  - Run tests    │
│  - Push to      │
│    registry     │
└────────┬────────┘
         │
         ▼
┌──────────────────────────┐
│  Container Registry      │
│  - Tag: sha-abc123 (dev) │
│  - Tag: v1.2.3 (prod)    │
└────────┬─────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Argo CD Image Updater              │
│                                     │
│  Dev: Detects new tag → Auto-commit │
│  Prod: Detects semver → Create PR   │
└────────┬────────────────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│  Dev   │ │  Prod    │
│ Commit │ │  PR      │
└───┬────┘ └────┬─────┘
    │           │
    ▼           ▼
┌────────┐ ┌──────────┐
│  Argo  │ │  Human   │
│  CD    │ │  Review  │
│  Sync  │ └────┬─────┘
└────────┘      │
                ▼
           ┌──────────┐
           │  Merge   │
           └────┬─────┘
                │
                ▼
           ┌──────────┐
           │  Argo CD │
           │  Sync    │
           └──────────┘
```

## Image Tagging Strategy

| Environment | Tag Pattern | Example | Set By |
|-------------|-------------|---------|--------|
| Dev | Git SHA | `sha-abc1234` | CI on push to main |
| Dev | Latest | `latest` | CI on push to main |
| Prod | Semantic | `v1.2.3` | Manual release/tag |

## Configuration Files

### Application Annotations

See:
- `argocd/applications/sample-app-dev.yaml` for dev configuration
- `argocd/applications/sample-app-prod.yaml` for prod configuration

### Image Updater Configuration

See:
- `platform/image-updater/kustomization.yaml`
- `platform/image-updater/patch-credentials.yaml`

## Troubleshooting

### Image Updater not detecting new images

1. Check Image Updater logs:
   ```bash
   kubectl logs -n argocd deployment/argocd-image-updater
   ```

2. Verify annotations on Application:
   ```bash
   kubectl get application sample-app-dev -n argocd -o yaml | grep annotations -A 10
   ```

3. Check registry credentials:
   ```bash
   kubectl get secret -n argocd
   ```

### Write-back to Git failing

1. Verify Git credentials secret exists:
   ```bash
   kubectl get secret image-updater-git-credentials -n argocd
   ```

2. Check GitHub token permissions (needs `repo` scope)

3. Verify Git user/email configuration

## Rollback Procedures

If a promoted image causes issues, see [Rollback Runbook](./rollback-runbook.md) for detailed recovery procedures.

### Quick Rollback Commands

```bash
# Dev: Revert to previous image
argocd app rollback sample-app-dev <revision-id>

# Prod: Revert kustomization and sync
kubectl apply -f apps/sample-app/overlays/prod/
argocd app sync sample-app-prod

# Or use direct kubectl
kubectl rollout undo deployment/prod-sample-app -n sample-app-prod
```

## Security Considerations

- GitHub token stored as Kubernetes secret
- Token has minimal permissions (repo scope only)
- Production requires human approval (PR review)
- Audit trail via Git history
- All images scanned by Trivy before deployment (see `.github/workflows/security-scan.yaml`)

