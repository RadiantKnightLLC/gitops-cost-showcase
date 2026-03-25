# Proof Artifacts

Screenshot evidence of GitOps-FinOps showcase.

---

## Artifact Index

### Argo CD GitOps

| File | Description | Verification |
|------|-------------|--------------|
| `01-argocd-apps-list.png` | Applications dashboard | All apps healthy and synced |
| `02-argocd-sample-app-detail.png` | App detail with resources | Tree view showing deployment flow |

### Kubecost FinOps

| File | Description | Verification |
|------|-------------|--------------|
| `03-kubecost-overview.png` | Cost overview | Namespace costs visible |
| `04-kubecost-allocations.png` | Allocation by namespace | dev/prod breakdown |
| `05-kubecost-savings.png` | Savings recommendations | Potential savings identified |

### Working Application

| File | Description |
|------|-------------|
| `06-tictactoe-app.png` | Tic-Tac-Toe game running |

---

## Key Configurations

### Argo CD

```yaml
# Sync waves ensure ordering
sync-wave: "-2"  # Namespaces
sync-wave: "2"   # Applications

# Auto-sync for dev
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

### Kubecost

```yaml
# Idle costs visible (not hidden)
defaultIdle: separate

# Labels mapped
labelMappingConfigs:
  environment_label: environment
  team_label: team
  cost-center_label: cost-center
  owner_label: owner
```

### Required Labels

| Label | Dev Value | Prod Value |
|-------|-----------|------------|
| environment | dev | prod |
| team | platform | platform |
| cost-center | agency-rnd | agency-rnd |
| owner | agency-internal | agency-internal |

---

## Verification

```bash
# Argo CD
argocd app list

# Kubecost
curl "http://localhost:9090/model/allocation?window=7d&aggregate=namespace"

# Labels
kubectl get pods -n sample-app-dev --show-labels
```

---

## Retention

> ⚠️ Kubecost Free tier: 15-day retention. Re-capture if deployment age exceeds this window.

---

## Related

- [Capture Guide](./CAPTURE-GUIDE.md)
- [Cost Model](../cost-model.md)
- [Labels Policy](../labels-policy.md)
