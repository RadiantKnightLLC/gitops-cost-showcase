# Cost Allocation Model

## Philosophy

This showcase demonstrates proactive cost governance:

- **Visible waste**: Idle costs shown separately (not hidden)
- **Explicit ownership**: Every workload has labels
- **Proactive alerts**: Budget thresholds before overspend
- **Business alignment**: Labels map to org structure

## Idle Cost Mode

We use `defaultIdle: separate` for transparency:

| Mode | Display | Use Case |
|------|---------|----------|
| **Separate** | Distinct category | Showcase, optimization |
| **Share** | Distributed | Production chargeback |
| **Hide** | Not shown | Avoid (hides waste) |

## Required Labels

All workloads must have these in `spec.template.metadata.labels`:

| Label | Purpose | Example |
|-------|---------|---------|
| `environment` | Env comparison | dev, prod |
| `team` | Ownership | platform |
| `cost-center` | Business unit | agency-rnd |
| `owner` | Accountability | agency-internal |

## Allocation Views

Kubecost aggregates costs by:
1. **Namespace** - Default ownership
2. **Label: environment** - Dev vs prod
3. **Label: team** - Team chargeback
4. **Label: cost-center** - Business unit

## Budget Alerts

| Scope | Threshold | Recipient |
|-------|-----------|-----------|
| sample-app-dev | 80% | platform-team |
| sample-app-prod | 90% | platform-team |
| Shared overhead | 25% | finops-team |

## Cost Attribution Example

```
Total: $1000/month
├── sample-app-dev: $200 (20%)
├── sample-app-prod: $400 (40%)
├── kubecost: $100 (10%)
├── argocd: $50 (5%)
└── Idle: $150 (15%)
```

## Retention Notice

**Kubecost Free**: 15-day retention

- Capture screenshots within 15 days
- Export via API for persistent data
- Consider Enterprise for longer retention

## Optimization Workflow

1. **Identify** - Find high-cost areas in Kubecost
2. **Analyze** - Check idle costs and efficiency
3. **Recommend** - Rightsizing, spot instances
4. **Implement** - Update manifests
5. **Measure** - Compare before/after
