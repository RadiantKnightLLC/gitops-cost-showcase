# Labels Policy for GitOps-FinOps Showcase

## Overview

This document defines the labeling requirements for the GitOps-FinOps showcase. Proper labeling is **critical** for accurate cost allocation in Kubecost.

## The Critical Distinction: Pod-Template Labels

### The Problem

Labels on a Kubernetes `Deployment` resource are **NOT automatically inherited** by the pods it creates. Kubecost reads labels from **running pods**, not from the Deployment object itself.

### The Solution

Every Deployment must have labels in **TWO places**:

1. **Deployment metadata** (`metadata.labels`) - For resource identification
2. **Pod template** (`spec.template.metadata.labels`) - For Kubecost cost allocation

### Visual Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  labels:                          # ✓ Deployment-level labels
    environment: dev
    app.kubernetes.io/name: sample-app
spec:
  template:
    metadata:
      labels:                      # ✓ CRITICAL: Pod-template labels
        environment: dev          # REQUIRED for Kubecost
        team: platform            # REQUIRED for Kubecost
        cost-center: agency-rnd   # REQUIRED for Kubecost
        owner: agency-internal    # REQUIRED for Kubecost
```

## Required Labels

All workloads MUST have these labels in **spec.template.metadata.labels**:

| Label | Example Values | Purpose |
|-------|---------------|---------|
| `environment` | `dev`, `prod`, `staging` | Environment-based cost comparison |
| `team` | `platform`, `backend`, `frontend` | Team ownership and showback |
| `cost-center` | `agency-rnd`, `agency-ops` | Business unit charging |
| `owner` | `agency-internal` | Accountability and contact |

## Kubernetes Recommended Labels

In addition to required labels, use these standard labels:

| Label | Example | Description |
|-------|---------|-------------|
| `app.kubernetes.io/name` | `sample-app` | Application name |
| `app.kubernetes.io/instance` | `sample-app-dev` | Unique instance name |
| `app.kubernetes.io/version` | `1.0.0` | Application version |
| `app.kubernetes.io/component` | `api` | Component within architecture |
| `app.kubernetes.io/part-of` | `gitops-finops-showcase` | Larger system this belongs to |
| `app.kubernetes.io/managed-by` | `argocd` | Tool managing the resource |

**Note**: `app.kubernetes.io/managed-by` is auto-applied by Argo CD. Do not set manually.

## Kustomize Implementation

### Pattern: labels.yaml Patch

Create a `labels.yaml` file in each overlay:

```yaml
# overlays/dev/labels.yaml
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

Reference it in `kustomization.yaml`:

```yaml
patchesStrategicMerge:
  - labels.yaml  # CRITICAL: Adds pod-template labels
```

## Verification Commands

### Check Pod Labels

```bash
# Verify labels on running pods
kubectl get pods -n sample-app-dev --show-labels

# Expected output shows:
# environment, team, cost-center, owner labels
```

### Check Kubecost Detection

```bash
# Port forward to Kubecost
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090

# Query allocation API
curl "http://localhost:9090/model/allocation?window=1d&aggregate=label:environment"

# Should return cost breakdown by environment label
```

### Validate Kustomize Output

```bash
# Build and check for pod-template labels
cd apps/sample-app
kustomize build overlays/dev | grep -A 20 "spec:" | grep -A 10 "template:"

# Look for required labels under spec.template.metadata.labels
```

## Common Mistakes

### ❌ Wrong: Labels only in metadata

```yaml
metadata:
  labels:
    environment: dev  # Deployment level only!
spec:
  template:
    metadata:
      labels:
        app: sample-app  # Missing cost labels!
```

**Result**: Kubecost shows namespace costs but no label-based allocation.

### ❌ Wrong: Labels in metadata AND selector only

```yaml
metadata:
  labels:
    environment: dev
spec:
  selector:
    matchLabels:
      environment: dev  # Selector only, not pod labels!
```

**Result**: Pods don't inherit selector labels. Kubecost won't see them.

### ✅ Right: Labels in BOTH places

```yaml
metadata:
  labels:
    environment: dev
    app.kubernetes.io/name: sample-app
spec:
  template:
    metadata:
      labels:
        environment: dev          # ✓ REQUIRED
        team: platform            # ✓ REQUIRED
        cost-center: agency-rnd   # ✓ REQUIRED
        owner: agency-internal    # ✓ REQUIRED
        app.kubernetes.io/name: sample-app
```

**Result**: Full cost attribution by namespace AND labels.

## CI Validation

This repository includes CI checks that will FAIL if pod-template labels are missing.

See `.github/workflows/validate-labels.yaml` for the validation logic.

## Kubecost Label Mapping

Kubecost is configured to map these labels to its allocation model:

```yaml
kubecostProductConfigs:
  labelMappingConfigs:
    enabled: true
    owner_label: owner
    team_label: team
    department_label: cost-center
    environment_label: environment
    product_label: app.kubernetes.io/part-of
```

## Enforcement

- **Pre-commit hooks**: Validate label presence before commit
- **CI checks**: Block PRs with missing pod-template labels
- **Argo CD sync**: Resources will deploy but Kubecost won't allocate correctly

## Questions?

If you're unsure about label placement:

1. Check this policy document
2. Review existing overlays in `apps/sample-app/overlays/`
3. Run: `kubectl get pods -n <namespace> --show-labels`
4. Verify in Kubecost UI: Allocation → Aggregate by label
