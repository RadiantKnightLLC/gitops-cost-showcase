# GitOps Cost Showcase

GitOps-driven Kubernetes configuration with FinOps cost allocation.

## Repository Structure

```
.
├── argocd/                 # Argo CD Applications and RBAC
│   ├── applications/       # Application manifests
│   └── rbac/              # RBAC configuration
├── apps/                   # Application configurations
│   └── sample-app/        # Sample application
│       ├── base/          # Base Kustomize resources
│       └── overlays/      # Environment-specific patches
│           ├── dev/       # Development environment
│           └── prod/      # Production environment
├── platform/              # Platform services
│   ├── namespaces/        # Namespace definitions
│   ├── kubecost/          # Kubecost configuration
│   ├── image-updater/     # Argo CD Image Updater
│   └── shared/            # Shared platform services
└── docs/                  # Documentation
    └── labels-policy.md   # Labeling requirements for FinOps
```

## Quick Start

### Prerequisites

- kubectl configured with cluster access
- kustomize installed
- Argo CD CLI installed

### Validate Kustomize Builds

```bash
# Dev overlay
cd apps/sample-app
kustomize build overlays/dev

# Prod overlay
kustomize build overlays/prod
```

### Apply with Argo CD

```bash
# Login to Argo CD
argocd login <argocd-server>

# Apply app-of-apps
kubectl apply -f argocd/app-of-apps.yaml

# Sync applications
argocd app sync -l app.kubernetes.io/part-of=gitops-finops-showcase
```

## Key Principles

### 1. GitOps-First

All changes go through Git. No manual `kubectl apply` to production.

### 2. Environment per Folder

Environments are Kustomize overlays, not Git branches.

```
overlays/
├── dev/          # Development
└── prod/         # Production
```

### 3. Pod-Template Labels (CRITICAL)

For Kubecost to allocate costs correctly, labels MUST be in `spec.template.metadata.labels`:

```yaml
spec:
  template:
    metadata:
      labels:
        environment: dev|prod      # REQUIRED
        team: platform             # REQUIRED
        cost-center: agency-rnd    # REQUIRED
        owner: agency-internal     # REQUIRED
```

See `docs/labels-policy.md` for full details.

### 4. Sync Waves

Resources deploy in wave order:

| Wave | Resources |
|------|-----------|
| -2 | Namespaces |
| -1 | CRDs, RBAC |
| 0 | Argo CD, Kubecost |
| 1 | Ingress, Monitoring |
| 2 | Applications |

### 5. Automated Image Promotion

- **Dev**: Automatic updates on new image tag
- **Prod**: PR-gated, requires approval

## Cost Allocation

This showcase demonstrates:

- **Namespace-level**: Costs by namespace
- **Label-level**: Costs by environment, team, cost-center
- **Idle costs**: Shown separately (visible waste)
- **Cloud billing**: Reconciled with actual cloud invoices
- **Budget alerts**: Proactive cost governance

## Documentation

- [Labels Policy](docs/labels-policy.md) - Required labels for FinOps
- [Architecture](docs/architecture.md) - System design
- [Cost Model](docs/cost-model.md) - Allocation strategy
- [RBAC Policy](docs/rbac-policy.md) - Access control
- [Image Promotion](docs/image-promotion.md) - Promotion workflow

## Development

### Testing Kustomize Builds

```bash
# Validate dev
kustomize build apps/sample-app/overlays/dev | kubectl apply --dry-run=server -f -

# Validate prod
kustomize build apps/sample-app/overlays/prod | kubectl apply --dry-run=server -f -
```

### CI/CD

This repository includes GitHub Actions for:

- Label validation
- Sync wave validation
- Security scanning

## License

MIT
