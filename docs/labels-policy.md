# Labels Policy

**Critical**: Labels must be in `spec.template.metadata.labels` (NOT just `metadata.labels`) for Kubecost to see them.

## The Problem

Labels on a `Deployment` are **NOT** inherited by pods. Kubecost reads labels from **running pods**.

## Required Labels

All workloads must have these in `spec.template.metadata.labels`:

| Label | Example | Purpose |
|-------|---------|---------|
| `environment` | dev, prod | Cost comparison |
| `team` | platform | Ownership |
| `cost-center` | agency-rnd | Business unit |
| `owner` | agency-internal | Accountability |

## Correct Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  labels:
    environment: dev          # Deployment-level only
spec:
  template:
    metadata:
      labels:
        environment: dev      # ✓ REQUIRED for Kubecost
        team: platform        # ✓ REQUIRED
        cost-center: agency-rnd  # ✓ REQUIRED
        owner: agency-internal   # ✓ REQUIRED
```

## Kustomize Pattern

Create `labels.yaml` in each overlay:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  template:
    metadata:
      labels:
        environment: dev
        team: platform
        cost-center: agency-rnd
        owner: agency-internal
```

Reference in `kustomization.yaml`:

```yaml
patchesStrategicMerge:
  - labels.yaml
```

## Verification

```bash
# Check pod labels
kubectl get pods -n sample-app-dev --show-labels

# Check Kubecost detection
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090
curl "http://localhost:9090/model/allocation?window=1d&aggregate=label:environment"
```

## Common Mistakes

### ❌ Wrong: Only metadata.labels

```yaml
metadata:
  labels:
    environment: dev  # Kubecost won't see this!
spec:
  template:
    metadata:
      labels: {}  # Missing!
```

### ✅ Right: Both places

```yaml
metadata:
  labels:
    environment: dev
spec:
  template:
    metadata:
      labels:
        environment: dev    # ✓ Kubecost sees this
        team: platform      # ✓
        cost-center: agency-rnd  # ✓
        owner: agency-internal   # ✓
```

## Enforcement

- **Pre-commit hooks**: Validate label presence
- **CI checks**: Block PRs with missing labels (`.github/workflows/validate-labels.yaml`)
- **Kubecost mapping**: Labels mapped in `values.yaml`

```yaml
kubecostProductConfigs:
  labelMappingConfigs:
    enabled: true
    owner_label: owner
    team_label: team
    department_label: cost-center
    environment_label: environment
```
