# GitOps-FinOps Showcase - Proof Artifacts

> **Captured**: [YYYY-MM-DD]  
> **Captured by**: [Agent/User Name]  
> **Retention Window**: Within 15-day Kubecost free tier limit

---

## Overview

This directory contains screenshot evidence demonstrating a fully operational GitOps-FinOps integration with Argo CD and Kubecost.

---

## Artifact Index

### Group A: Argo CD GitOps Workflow

| File | Description | Verification Points |
|------|-------------|---------------------|
| `01-argocd-apps-list.png` | Argo CD Applications grid view | ✅ App-of-Apps, sample-app-dev, sample-app-prod all healthy |
| `02-argocd-app-of-apps-detail.png` | App-of-Apps tree view with sync waves | ✅ Sync waves (-2 to +2) visible, child apps healthy |
| `03-argocd-sample-app-dev-detail.png` | Sample app dev detailed view | ✅ Auto-sync enabled, Image Updater annotations, sync-wave on Deployment |

### Group B: Kubecost Cost Allocation

| File | Description | Verification Points |
|------|-------------|---------------------|
| `04-kubecost-namespace-view.png` | Cost allocation by namespace | ✅ sample-app-dev, sample-app-prod, kubecost, argocd visible |
| `05-kubecost-by-environment-label.png` | Cost allocation by environment label | ✅ dev/prod breakdown, idle costs separate |
| `06-kubecost-all-four-labels.png` | All required labels verified | ✅ environment, team, cost-center, owner all mapped |

### Group C: Idle Costs & Budget Alerts

| File | Description | Verification Points |
|------|-------------|---------------------|
| `07-kubecost-idle-separate-mode.png` | Idle costs in separate mode | ✅ Idle row visible (proves `defaultIdle: separate` config) |
| `08-kubecost-savings-recommendations.png` | Savings recommendations view | ✅ Efficiency insights available |
| `09-kubecost-budget-alerts-config.png` | Budget alerts configuration | ✅ 4 alerts: Dev 80%, Prod 90%, Shared 25%, Efficiency 50% |

### Group D: GitOps-FinOps Integration

| File | Description | Verification Points |
|------|-------------|---------------------|
| `10-kubecost-label-mapping-config.png` | Kubecost label mapping settings | ✅ environment, owner, team, cost-center, product labels mapped |
| `11-gitops-finops-dashboard-composite.png` | Side-by-side GitOps + FinOps view | ✅ Complete integration demonstrated |

---

## Key Configurations Demonstrated

### Argo CD

```yaml
# Sync Wave Configuration
app-of-apps:        sync-wave: "1"
sample-app-dev:     sync-wave: "2"
sample-app-prod:    sync-wave: "2"

# Image Updater (Dev)
argocd-image-updater.argoproj.io/image-list: sample-app=ghcr.io/RadiantKnightLLC/sample-app
argocd-image-updater.argoproj.io/sample-app.update-strategy: newest-build

# Image Updater (Prod)
argocd-image-updater.argoproj.io/sample-app.update-strategy: semver
```

### Kubecost

```yaml
# Idle Cost Mode
kubecostProductConfigs:
  defaultIdle: separate  # Makes waste visible

# Label Mapping
kubecostProductConfigs:
  labelMappingConfigs:
    enabled: true
    owner_label: owner
    team_label: team
    department_label: cost-center
    environment_label: environment
```

### Required Labels (All Present)

| Label | Value (Dev) | Value (Prod) |
|-------|-------------|--------------|
| environment | dev | prod |
| team | platform | platform |
| cost-center | agency-rnd | agency-rnd |
| owner | agency-internal | agency-internal |

---

## Validation Commands

```bash
# Verify Argo CD health
argocd app list

# Verify Kubecost data
curl "http://localhost:9090/model/allocation?window=7d&aggregate=namespace"

# Verify pod labels
kubectl get pods -n sample-app-dev --show-labels
kubectl get pods -n sample-app-prod --show-labels

# Verify budget alerts
kubectl get configmap kubecost-budget-alerts -n kubecost
```

---

## Retention Notice

> ⚠️ **Kubecost Free Tier**: Data retention is limited to 15 days.
> These screenshots must be re-captured if the deployment age exceeds this window.

---

## Related Documentation

- [Cost Model](../cost-model.md)
- [Labels Policy](../labels-policy.md)
- [Sync Wave Validation](../sync-wave-validation.md)
- [Cloud Billing Setup](../cloud-billing-setup.md)

