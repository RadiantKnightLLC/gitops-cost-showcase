# GitOps-FinOps Showcase Documentation

Quick reference guide for all documentation in this repository.

## Quick Start

| If you want to... | See this document |
|-------------------|-------------------|
| Deploy the showcase | [Main README](../README.md) |
| Understand the architecture | [Architecture Diagram](#architecture) below |
| Fix a failed deployment | [Rollback Runbook](./rollback-runbook.md) |
| Rebuild the app | [sample-app/REBUILD.md](../../sample-app/REBUILD.md) |

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   GitHub Repo   │────▶│   Argo CD        │────▶│  Kubernetes     │
│   (Manifests)   │     │   (GitOps)       │     │  (Workloads)    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │                           │
                               ▼                           ▼
                        ┌──────────────┐           ┌──────────────┐
                        │ Image Updater│           │  Kubecost    │
                        │ (Auto-promo) │           │  (FinOps)    │
                        └──────────────┘           └──────────────┘
```

## Documentation Index

### Core Operations

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [labels-policy.md](./labels-policy.md) | Required labels for cost allocation | Adding new workloads |
| [rollback-runbook.md](./rollback-runbook.md) | Disaster recovery procedures | Something is broken |
| [image-promotion.md](./image-promotion.md) | How images move dev → prod | Setting up CI/CD |

### FinOps & Cost Management

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [cost-model.md](./cost-model.md) | Cost allocation philosophy | Understanding cost breakdown |
| [cloud-billing-setup.md](./cloud-billing-setup.md) | Connect to AWS/Azure/GCP billing | Production cloud deployment |

### Reference

| Document | Purpose |
|----------|---------|
| [sync-wave-validation.md](./sync-wave-validation.md) | Deployment ordering |
| [security-audit-2026-03.md](./security-audit-2026-03.md) | Security assessment |
| [proof-artifacts/](./proof-artifacts/) | Verification screenshots |

## Critical Quick References

### Required Labels (for Kubecost)

Every workload must have these in `spec.template.metadata.labels`:

```yaml
environment: dev|prod|staging
team: platform|backend|frontend
cost-center: agency-rnd|agency-ops
owner: agency-internal
```

### Access URLs (Local Development)

| Service | URL | Credentials |
|---------|-----|-------------|
| Argo CD | https://localhost:8080 | admin / finops@p1 |
| Kubecost | http://localhost:9090 | - |
| Sample App | http://localhost:8082 | - |

### Essential Commands

```bash
# Check everything is running
kubectl get pods --all-namespaces

# View Argo CD apps
argocd app list

# Check Kubecost costs
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090
# Then open http://localhost:9090

# Rebuild and deploy
yarn build
docker build -t showcase-app-p1:local .
kind load docker-image showcase-app-p1:local --name gitops-finops
kubectl rollout restart deployment dev-sample-app -n sample-app-dev
```

## Status

- **GitOps**: ✅ Argo CD managing applications
- **FinOps**: ✅ Kubecost tracking costs by namespace/label
- **Security**: ✅ 8.4/10 audit score
- **Documentation**: ✅ All phases complete

---

*Last updated: 2026-03-24*
