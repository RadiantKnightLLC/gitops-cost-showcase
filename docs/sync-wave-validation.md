# Sync Wave Validation

Validates deployment ordering for the GitOps-FinOps showcase.

## Sync Wave Assignments

| Wave | Resources | Dependencies |
|------|-----------|--------------|
| **-2** | Namespaces | None |
| **-1** | RBAC, ConfigMaps | Wave -2 |
| **0** | Argo CD, Kubecost | Wave -1 |
| **1** | App-of-Apps | Wave 0 |
| **2** | Applications | Wave 1 |

## Resource Mapping

### Wave -2: Namespaces
```yaml
platform/namespaces/argocd.yaml
platform/namespaces/kubecost.yaml
apps/sample-app/overlays/dev/namespace.yaml
apps/sample-app/overlays/prod/namespace.yaml
```

### Wave -1: RBAC
```yaml
platform/argocd/argocd-rbac-cm.yaml
platform/argocd/argocd-cm.yaml
```

### Wave 0: Platform
```yaml
platform/kubecost/  # Helm chart
```

### Wave 2: Applications
```yaml
argocd/applications/sample-app-dev.yaml
argocd/applications/sample-app-prod.yaml
```

## Dependency Graph

```
Namespaces (-2)
    │
    ▼
RBAC (-1)
    │
    ├───► Kubecost (0)
    │
    └───► Applications (2)
```

## Validation

```bash
# Check sync wave annotations
kubectl get applications -n argocd -o yaml | grep sync-wave

# Verify deployment order
argocd app list

# Check Kubecost readiness
kubectl get pods -n kubecost
```

## Bootstrap Sequence

```bash
# Apply in order
kubectl apply -f platform/namespaces/          # Wave -2
kubectl apply -f platform/argocd/              # Wave -1
kubectl apply -f platform/kubecost/            # Wave 0
kubectl apply -f argocd/applications/          # Wave 2
```
