# GitOps-FinOps Showcase

> A complete production-ready GitOps and FinOps implementation demonstrating modern Kubernetes deployment patterns with cost visibility and governance.

[![CI](https://github.com/RadiantKnightLLC/gitops-cost-showcase/actions/workflows/validate-labels.yaml/badge.svg)](https://github.com/RadiantKnightLLC/gitops-cost-showcase/actions)
[![Security Scan](https://github.com/RadiantKnightLLC/gitops-cost-showcase/actions/workflows/security-scan.yaml/badge.svg)](https://github.com/RadiantKnightLLC/gitops-cost-showcase/actions)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Phases](#phases)
- [Documentation](#documentation)
- [Security](#security)
- [Production Deployment](#production-deployment)
- [License](#license)

---

## Overview

This showcase demonstrates a complete GitOps workflow with integrated FinOps cost management:

- **GitOps**: Argo CD for declarative Kubernetes deployments with automated sync
- **FinOps**: Kubecost for real-time cost allocation and optimization
- **DevOps**: CI/CD pipelines, security scanning, and governance
- **Best Practices**: Sync waves, RBAC, label governance, image promotion

### Key Features

| Feature | Implementation |
|---------|----------------|
| GitOps Controller | Argo CD v3.3.4 with App-of-Apps pattern |
| Cost Management | Kubecost with namespace + label-based allocation |
| Image Promotion | Argo CD Image Updater (auto for dev, PR-gated for prod) |
| Security | Trivy/Grype scanning, pre-commit hooks, RBAC |
| Governance | Label policies, sync waves, budget alerts |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repositories                       │
├─────────────────────────────────────────────────────────────────┤
│  sample-app (Source)        gitops-cost-showcase (Config)       │
│  ├── src/                   ├── apps/                           │
│  ├── Dockerfile             ├── platform/                       │
│  └── .github/workflows/     └── argocd/                         │
└──────────┬──────────────────────────┬───────────────────────────┘
           │                          │
           ▼                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Argo CD                                  │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────┐           │
│  │ sample-app   │  │ sample-app  │  │  Kubecost    │           │
│  │    -dev      │  │   -prod     │  │              │           │
│  │  (auto-sync) │  │  (manual)   │  │              │           │
│  └──────┬───────┘  └──────┬──────┘  └──────┬───────┘           │
└─────────┼──────────────────┼─────────────────┼──────────────────┘
          │                  │                 │
          ▼                  ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │sample-app-  │  │sample-app-  │  │        Kubecost         │ │
│  │    dev      │  │    prod     │  │  ┌─────────────────┐    │ │
│  │  (1 replica)│  │  (2 replica)│  │  │ Cost Allocation │    │ │
│  └─────────────┘  └─────────────┘  │  │ Budget Alerts   │    │ │
│                                    │  │ Savings Recs    │    │ │
│  Labels: environment, team,        │  └─────────────────┘    │ │
│  cost-center, owner               └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Prerequisites

```bash
# Required tools
kubectl version --client
argocd version --client
kustomize version
docker version
kind version

# Verify cluster access
kubectl cluster-info
```

### 1. Create Kind Cluster

```bash
kind create cluster --name gitops-finops --config kind-network-config.yaml
```

### 2. Install Argo CD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 3. Install Kubecost

```bash
helm upgrade --install kubecost kubecost/cost-analyzer \
  --namespace kubecost --create-namespace \
  --version 2.8.2 \
  -f platform/kubecost/values.yaml
```

### 4. Deploy Applications

```bash
# Option A: Via Argo CD (if cluster has GitHub access)
kubectl apply -f argocd/app-of-apps.yaml

# Option B: Direct kubectl (for Kind/local development)
kustomize build apps/sample-app/overlays/dev | kubectl apply -f -
kustomize build apps/sample-app/overlays/prod | kubectl apply -f -
```

### 5. Access Services

```bash
# Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Login: admin / $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)

# Kubecost
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090:9090
# URL: http://localhost:9090

# Sample App (dev)
kubectl port-forward svc/dev-sample-app -n sample-app-dev 8082:80
# URL: http://localhost:8082
```

---

## Project Structure

```
gitops-cost-showcase/
├── apps/                          # Application manifests
│   └── sample-app/
│       ├── base/                  # Base kustomization
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── kustomization.yaml
│       └── overlays/
│           ├── dev/               # Dev environment
│           │   ├── kustomization.yaml
│           │   ├── namespace.yaml
│           │   └── labels.yaml
│           └── prod/              # Production environment
│               ├── kustomization.yaml
│               ├── namespace.yaml
│               └── labels.yaml
├── argocd/                        # Argo CD configuration
│   ├── app-of-apps.yaml           # Root Application
│   └── applications/              # Individual Applications
│       ├── sample-app-dev.yaml
│       ├── sample-app-prod.yaml
│       └── kubecost.yaml
├── docs/                          # Documentation
│   ├── cluster-setup/             # Cluster setup guides
│   ├── cloud-billing-setup.md     # Cloud billing integration
│   ├── cost-model.md              # Cost allocation model
│   ├── image-promotion.md         # Image promotion workflow
│   ├── labels-policy.md           # Label governance
│   ├── rollback-runbook.md        # Disaster recovery
│   ├── security-audit-2026-03.md  # Security audit report
│   └── sync-wave-validation.md    # Sync wave docs
├── platform/                      # Platform services
│   ├── argocd/                    # Argo CD config (RBAC, etc.)
│   ├── kubecost/                  # Kubecost configuration
│   ├── namespaces/                # Namespace definitions
│   └── shared/                    # Shared resources
├── scripts/                       # Utility scripts
│   ├── start-showcase.sh          # Quick start script
│   └── verify-labels.sh           # Label validation
├── .github/
│   ├── pull_request_template.md   # PR template
│   └── workflows/                 # CI/CD workflows
│       ├── validate-labels.yaml
│       ├── validate-sync-waves.yaml
│       └── security-scan.yaml
├── .pre-commit-config.yaml        # Pre-commit hooks
└── README.md                      # This file
```

---

## Phases

This project was implemented in 6 phases following the [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md):

| Phase | Focus | Status | Key Deliverables |
|-------|-------|--------|------------------|
| 1 | Foundation | ✅ Complete | Source repo, config repo, label policy |
| 2 | GitOps Core | ✅ Complete | Argo CD, RBAC, Applications, Image Updater |
| 3 | Platform Services | ✅ Complete | Kubecost, ingress, monitoring |
| 4 | FinOps Configuration | ✅ Complete | Cost model, cloud billing guide |
| 5 | Proof Artifacts | ✅ Complete | Screenshots, verification evidence |
| 6 | Hardening | ✅ Complete | CI workflows, security audit, rollback runbook |

See [COMPLETION-REPORT.md](COMPLETION-REPORT.md) for detailed phase summaries.

---

## Documentation

### Core Documentation

| Document | Purpose |
|----------|---------|
| [AGENTS.md](AGENTS.md) | Agent configuration and protocol |
| [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md) | Detailed execution plan |
| [PROTOCOL-QUICKSTART.md](PROTOCOL-QUICKSTART.md) | Protocol quick reference |

### Operational Documentation

| Document | Purpose |
|----------|---------|
| [docs/image-promotion.md](docs/image-promotion.md) | Image promotion workflow (dev auto, prod PR-gated) |
| [docs/rollback-runbook.md](docs/rollback-runbook.md) | Disaster recovery procedures |
| [docs/labels-policy.md](docs/labels-policy.md) | Label governance requirements |
| [docs/security-audit-2026-03.md](docs/security-audit-2026-03.md) | Security audit with score cards |

### Setup Documentation

| Document | Purpose |
|----------|---------|
| [docs/cluster-setup/README.md](docs/cluster-setup/README.md) | Cluster setup guides |
| [docs/cloud-billing-setup.md](docs/cloud-billing-setup.md) | Cloud billing integration |
| [docs/cost-model.md](docs/cost-model.md) | Cost allocation model |

---

## Security

### Security Audit Results

**Overall Score: 8.4/10** ✅ (Meets ≥8/10 threshold)

| Category | Score | Status |
|----------|-------|--------|
| Repository Security | 9/10 | 🟢 |
| Kubernetes Security | 8/10 | 🟢 |
| Argo CD Security | 8/10 | 🟢 |
| Image Security | 9/10 | 🟢 |
| Access Control | 8/10 | 🟢 |

### Security Features

- **Secret Detection**: Gitleaks + TruffleHog pre-commit hooks
- **Vulnerability Scanning**: Trivy + Grype for images and manifests
- **Misconfiguration Detection**: Checkov for Kubernetes manifests
- **RBAC**: Role-based access control in Argo CD
- **Image Security**: Multi-stage builds, minimal base images, specific tags

See [docs/security-audit-2026-03.md](docs/security-audit-2026-03.md) for full details.

---

## Production Deployment

### Current Status

This showcase is currently configured for **Kind (local) deployment**. The Kind cluster has a network limitation that prevents Argo CD from syncing directly from GitHub.

### To Deploy to Production (EKS/GKE/AKS)

1. **Prerequisites**:
   - Cloud account with billing enabled
   - Domain name (for TLS certificates)
   - kubectl configured for cloud cluster

2. **Deploy**:
   ```bash
   # Create managed cluster
   eksctl create cluster --name gitops-finops --region us-east-1
   # or
   gcloud container clusters create gitops-finops
   # or
   az aks create --name gitops-finops --resource-group my-rg
   
   # Install Argo CD with proper TLS
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   
   # Configure GitHub repository credentials
   kubectl create secret generic gitops-repo-creds \
     -n argocd \
     --from-literal=url=https://github.com/RadiantKnightLLC/gitops-cost-showcase.git \
     --from-literal=username=$GITHUB_USERNAME \
     --from-literal=password=$GITHUB_TOKEN
   
   # Install Kubecost with cloud billing
   helm upgrade --install kubecost kubecost/cost-analyzer \
     --namespace kubecost --create-namespace \
     -f platform/kubecost/values.yaml \
     --set kubecostProductConfigs.cloudIntegrationJSON="$CLOUD_INTEGRATION_JSON"
   
   # Deploy applications via Argo CD
   kubectl apply -f argocd/app-of-apps.yaml
   ```

3. **Verify**:
   - Argo CD syncs applications from GitHub
   - Kubecost shows cost allocation by namespace and labels
   - CI workflows pass on pull requests

See [docs/cloud-billing-setup.md](docs/cloud-billing-setup.md) for cloud billing integration details.

---

## Known Limitations

### Kind Cluster

- **Network Isolation**: Kind clusters run inside Docker and cannot reach external GitHub URLs
- **Workaround**: Deploy manifests directly via `kubectl apply -k` or `kustomize build | kubectl apply`
- **Production**: This limitation does not exist in EKS/GKE/AKS

### Kubecost Free Tier

- **Data Retention**: 15 days (metrics older than 15 days are purged)
- **Workaround**: Export data regularly or upgrade to paid tier
- **Production**: Consider Kubecost Enterprise or cloud-native cost tools

---

## Contributing

### Development Workflow

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and validate: `kustomize build apps/sample-app/overlays/dev | kubectl apply --dry-run=client -f -`
3. Run pre-commit hooks: `pre-commit run --all-files`
4. Commit and push: `git commit -m "feat: ..." && git push origin feature/my-feature`
5. Create Pull Request using the [PR template](.github/pull_request_template.md)

### Label Requirements

All deployments must include these labels in `spec.template.metadata.labels`:

```yaml
environment: dev|prod|staging
team: platform|backend|frontend
cost-center: agency-rnd|agency-ops
owner: agency-internal
```

See [docs/labels-policy.md](docs/labels-policy.md) for details.

---

## License

This project is for demonstration purposes. See individual component licenses:
- Argo CD: Apache 2.0
- Kubecost: See [Kubecost licensing](https://www.kubecost.com/pricing)

---

## Acknowledgments

- Argo CD community for the excellent GitOps tooling
- Kubecost team for cost visibility solutions
- Kubernetes community for the platform that makes this possible

---

## Support

For questions or issues:
1. Check the [documentation](docs/)
2. Review [troubleshooting guides](docs/rollback-runbook.md)
3. Open an issue in this repository

---

**Project Status**: ✅ Complete (All 6 phases finished)

**Last Updated**: 2026-03-23
