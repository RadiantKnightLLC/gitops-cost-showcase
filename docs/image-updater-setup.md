# ArgoCD Image Updater Setup

This document describes how to set up ArgoCD Image Updater for automatic image updates.

## Overview

ArgoCD Image Updater monitors container registries for new images and automatically updates the GitOps repository.

### Flow

```
sample-app CI Build → GHCR → Image Updater → Git Commit → ArgoCD Sync
```

## Prerequisites

1. ArgoCD Image Updater installed in the cluster (already done)
2. GitHub Personal Access Token (PAT) with `repo` scope
3. GHCR credentials (if private registry)

## Setup Steps

### 1. Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (full control of private repositories)
4. Generate and copy the token

### 2. Create Git Credentials Secret

```bash
kubectl create secret generic image-updater-git-credentials \
  --from-literal=username=<your-github-username> \
  --from-literal=password=<your-github-pat> \
  -n argocd
```

### 3. Create GHCR Credentials (if private)

```bash
kubectl create secret generic ghcr-credentials \
  --from-literal=username=<your-github-username> \
  --from-literal=password=<your-github-pat> \
  -n argocd
```

### 4. Apply Image Updater Configuration

```bash
kubectl apply -k gitops-cost-showcase/platform/image-updater/
```

### 5. Restart Image Updater

```bash
kubectl rollout restart deployment argocd-image-updater -n argocd
```

## Configuration

### Application Annotations

The `sample-app` ApplicationSet already has the required annotations:

```yaml
argocd-image-updater.argoproj.io/image-list: showcase-app-p1=ghcr.io/radiantknightllc/showcase-app-p1
argocd-image-updater.argoproj.io/showcase-app-p1.update-strategy: newest-build
argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/image-updater-git-credentials
argocd-image-updater.argoproj.io/git-branch: master
```

### Update Strategies

| Strategy | Description | Use Case |
|----------|-------------|----------|
| `newest-build` | Latest image by build time | Dev environments |
| `semver` | Semantic versioning | Prod environments |
| `latest` | Tag "latest" | Simple setups |
| `digest` | Track by digest | Immutable tags |

## Verification

### Check Image Updater Logs

```bash
kubectl logs -n argocd deployment/argocd-image-updater -f
```

### Test Image Update

1. Build and push a new image to GHCR
2. Watch Image Updater logs for detection
3. Verify Git commit in gitops-cost-showcase repo
4. Verify ArgoCD sync

## Troubleshooting

### Image Not Detected

- Check image tag format matches strategy
- Verify registry credentials
- Check Image Updater logs for errors

### Git Write-Back Fails

- Verify PAT has `repo` scope
- Check secret exists: `kubectl get secret image-updater-git-credentials -n argocd`
- Check logs for authentication errors

### ArgoCD Doesn't Sync

- Verify Application has correct sync policy
- Check ArgoCD logs for sync errors
- Verify Git commit was successful

## Security Notes

- Use fine-grained PAT with minimal permissions
- Rotate PATs regularly
- Store credentials as Kubernetes secrets
- Consider using GitHub App instead of PAT for production
