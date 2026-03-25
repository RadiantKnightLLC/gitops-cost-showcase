# Screenshot Capture Guide

Quick reference for capturing proof artifacts.

## Pre-Flight

```bash
# Check cluster
kubectl cluster-info
kubectl get pods -n argocd
kubectl get pods -n kubecost
kubectl get pods -n sample-app-dev

# Verify labels
kubectl get pods -n sample-app-dev --show-labels
```

## Port Forwards

```bash
# Terminal 1: Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Kubecost
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090:9090
```

## URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Argo CD | https://localhost:8080 | admin / finops@p1 |
| Kubecost | http://localhost:9090 | - |

## Screenshot Checklist

### Argo CD (5 min)
- [ ] Applications list (all healthy)
- [ ] sample-app-dev detail (sync status, annotations)
- [ ] Resource tree view

### Kubecost (10 min)
- [ ] Overview dashboard
- [ ] Allocations by namespace
- [ ] Allocations by label:environment
- [ ] Savings recommendations

### Application (2 min)
- [ ] Tic-Tac-Toe app running

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No Kubecost data | Wait 5-10 min for metrics |
| Labels not visible | Check pod labels: `kubectl get pods --show-labels` |
| Argo CD not syncing | Check repo connection in Settings |

## Post-Capture

```bash
# Rename and commit
git add docs/proof-artifacts/
git commit -m "docs: Update proof artifacts"
```

## API Fallback

If UI fails, capture API responses:

```bash
curl "http://localhost:9090/model/allocation?window=7d&aggregate=namespace" > kubecost-api.json
argocd app list > argocd-apps.txt
```
