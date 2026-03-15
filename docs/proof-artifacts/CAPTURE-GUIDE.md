# Phase 5 Screenshot Capture Guide

> Quick reference for executing the proof artifact capture

---

## Pre-Flight Checklist

Run these commands before starting:

```bash
# 1. Check cluster connectivity
kubectl cluster-info

# 2. Verify Argo CD pods (expect 7/7 Running)
kubectl get pods -n argocd

# 3. Verify Kubecost pods (expect 5/5 Running)
kubectl get pods -n kubecost

# 4. Verify sample apps
kubectl get pods -n sample-app-dev
kubectl get pods -n sample-app-prod

# 5. CRITICAL: Verify labels on pods
kubectl get pods -n sample-app-dev --show-labels
kubectl get pods -n sample-app-prod --show-labels

# 6. Check Kubecost age (must be <15 days)
kubectl get pods -n kubecost -l app=cost-analyzer -o jsonpath='{.items[0].metadata.creationTimestamp}'
```

---

## Port Forward Setup

```bash
# Terminal 1: Argo CD (if not using ingress)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Kubecost
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090:9090
```

---

## Browser URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Argo CD | https://localhost:8080 | From `argocd admin initial-password` |
| Kubecost | http://localhost:9090 | No auth (default) |

---

## Screenshot Checklist

### Group A: Argo CD (8 minutes)
- [ ] **A1**: Applications list (https://localhost:8080/applications)
  - Grid view, all 3 apps visible
  - Health: Healthy, Sync: Synced
  
- [ ] **A2**: App-of-Apps detail (click app-of-apps → Tree tab)
  - Show sync waves (-2 to +2)
  - Expand to show child applications
  
- [ ] **A3**: sample-app-dev detail (click sample-app-dev)
  - Tree view with Deployment, Service, ConfigMap
  - Show Parameters tab for Image Updater annotations

### Group B: Kubecost Allocation (10 minutes)
- [ ] **B4**: Namespace view (http://localhost:9090/allocations)
  - Aggregation: Namespace
  - Window: Last 7 days
  - All 4 namespaces visible
  
- [ ] **B5**: Environment label (Aggregation dropdown → label:environment)
  - dev/prod breakdown
  - Idle costs visible
  
- [ ] **B6**: All 4 labels (cycle through: team, cost-center, owner)
  - Screenshot each aggregation
  - Verify values: platform, agency-rnd, agency-internal

### Group C: Idle & Alerts (7 minutes)
- [ ] **C7**: Idle costs separate (ensure "Idle" checkbox is checked)
  - Idle row visible as separate line item
  
- [ ] **C8**: Savings (http://localhost:9090/savings)
  - Any recommendations visible
  
- [ ] **C9**: Budget alerts (Settings → Alerts → Budget Alerts)
  - 4 alerts configured

### Group D: Integration (7 minutes)
- [ ] **D10**: Label mapping (Settings → Label Mapping)
  - All 5 labels mapped
  
- [ ] **D11**: Composite (side-by-side Argo CD + Kubecost)
  - Use browser split screen or two windows

---

## Keyboard Shortcuts

| Action | Windows | Mac |
|--------|---------|-----|
| Full screenshot | `Win + Shift + S` | `Cmd + Shift + 4` |
| Browser dev tools | `F12` | `Cmd + Option + I` |
| Zoom in | `Ctrl + +` | `Cmd + +` |
| Refresh | `Ctrl + R` | `Cmd + R` |

---

## Troubleshooting

### Kubecost shows no data
```bash
# Check Prometheus is scraping
curl http://localhost:9090/model/allocation?window=1d

# Check node-exporter
curl http://localhost:9090/metrics
```

### Labels not visible in Kubecost
```bash
# Verify pod labels exist
kubectl get pods -n sample-app-dev -o jsonpath='{.items[0].metadata.labels}'

# Check label mapping config
kubectl get configmap -n kubecost kubecost-cost-analyzer -o yaml | grep -A 10 labelMapping
```

### Idle costs not showing
1. Check `defaultIdle: separate` in values.yaml
2. Wait for node-exporter metrics (may take 5-10 min after startup)
3. Verify node-exporter pods: `kubectl get pods -n kubecost | grep node-exporter`

---

## Post-Capture

```bash
# Rename screenshots to match convention
# Move to docs/proof-artifacts/
# Update README.md with capture date
# Commit to git
git add docs/proof-artifacts/
git commit -m "docs: Add Phase 5 proof artifacts screenshots

- Argo CD GitOps workflow (3 screenshots)
- Kubecost cost allocation (3 screenshots)
- Idle costs & budget alerts (3 screenshots)
- GitOps-FinOps integration (2 screenshots)

Retention window: [DATE]"
```

---

## Emergency Fallback

If UI capture fails, use API evidence:

```bash
# Save API responses as JSON
curl "http://localhost:9090/model/allocation?window=7d&aggregate=namespace" > kubecost-namespace-api.json
curl "http://localhost:9090/model/allocation?window=7d&aggregate=label:environment" > kubecost-env-label-api.json

# Argo CD CLI
argocd app list > argocd-apps-list.txt
argocd app get sample-app-dev -o yaml > sample-app-dev-details.yaml
```
