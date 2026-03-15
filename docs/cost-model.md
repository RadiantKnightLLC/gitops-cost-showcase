# Cost Allocation Model

## Philosophy

This showcase demonstrates proactive cost governance through:

- **Visible waste**: Idle costs shown separately (not hidden in blended rates)
- **Explicit ownership**: Every workload has namespace + label attribution
- **Proactive alerts**: Budget thresholds trigger before overspend
- **Business alignment**: Labels map to organizational structure (team, cost-center)

## Idle Cost Mode: Separate

We configure Kubecost with `defaultIdle: separate` because:

1. **Transparency**: Stakeholders see exactly how much compute is paid for but unused
2. **Optimization signal**: High idle cost drives rightsizing conversations
3. **Education**: Easier to explain "unused capacity" vs "hidden in blended rates"
4. **Showcase value**: Demonstrates FinOps capability to identify waste

### Comparison

| Mode | Idle Cost Display | Use Case |
|------|-------------------|----------|
| **Separate** | Distinct category | Showcase, optimization focus |
| **Share** | Distributed to workloads | Production, chargeback accuracy |
| **Hide** | Not shown | Avoid (hides waste) |

## Shared Cost Model

Platform services are handled explicitly:

### Shared Namespaces
- `argocd` - GitOps control plane
- `kubecost` - Cost monitoring
- `ingress-system` - Ingress controller
- `monitoring` - Observability stack

### Allocation Strategy
1. Show as separate line items in allocation views
2. Distribute as overhead percentage if needed
3. Track as percentage of total spend (alert at >25%)

### Why Not Hide?
- Platform overhead is real cost
- Teams should understand total cost of delivery
- Capacity planning requires visibility

## Label-Based Allocation

### Required Labels

All workloads must have these labels in `spec.template.metadata.labels`:

| Label | Purpose | Example Values |
|-------|---------|----------------|
| `environment` | Environment comparison | dev, prod, staging |
| `team` | Team ownership | platform, backend, frontend |
| `cost-center` | Business unit charging | agency-rnd, agency-ops |
| `owner` | Accountability | agency-internal |

### Allocation Views Enabled

1. **Namespace**: Default ownership lens
   - Groups by Kubernetes namespace
   - Shows dev/prod separation

2. **Label: environment**
   - Aggregates dev vs prod costs
   - Enables environment comparison

3. **Label: team**
   - Shows costs by team
   - Supports team chargeback

4. **Label: cost-center**
   - Business unit perspective
   - Financial reporting alignment

## Cloud Billing Integration

### Current Status
- In-cluster estimates only (initial deployment)
- Cloud billing integration pending (Phase 4.2)

### Required for Production Showcase
Cloud billing reconciliation is **required** before presenting to technical prospects.

Without cloud billing:
- Network egress costs not captured
- Storage costs not captured
- Actual invoice reconciliation impossible

See `docs/cloud-billing-setup.md` for integration steps.

## Budget Alerts

### Alert Thresholds

| Scope | Threshold | Window | Recipient |
|-------|-----------|--------|-----------|
| sample-app-dev | 80% | Daily | platform-team |
| sample-app-prod | 90% | Daily | platform-team |
| Shared overhead | 25% | Daily | finops-team |
| Dev efficiency | <50% | 7-day | platform-team |

### Alert Types

1. **Budget alerts**: Cost exceeds threshold
2. **Efficiency alerts**: Resource utilization low
3. **Anomaly alerts**: Unusual spending patterns (requires historical data)

## Retention Warning

**Kubecost Free**: 15-day retention

- Capture screenshots within 15 days of first deployment
- Early data expires after retention window
- For persistent data, export via API or use Kubecost Enterprise

## Optimization Workflow

1. **Identify**: Use allocation views to find high-cost areas
2. **Analyze**: Check idle costs and efficiency scores
3. **Recommend**: Rightsizing, spot instances, or workload consolidation
4. **Implement**: Update manifests, Argo CD syncs automatically
5. **Measure**: Compare before/after in Kubecost

## Cost Attribution Example

```
Total Cluster Cost: $1000/month

By Namespace:
├── sample-app-dev: $200 (20%)
├── sample-app-prod: $400 (40%)
├── kubecost: $100 (10%)
├── argocd: $50 (5%)
├── ingress-system: $100 (10%)
└── monitoring: $150 (15%)

By Label (environment):
├── dev: $250 (25%)
├── prod: $450 (45%)
└── platform: $300 (30%)

Idle Cost: $150 (15% - shown separately)
```

## Key Metrics to Track

1. **Cost per namespace** - Ownership attribution
2. **Cost per environment** - Dev/prod comparison
3. **Idle cost percentage** - Waste visibility
4. **Shared overhead percentage** - Platform cost transparency
5. **Budget alert frequency** - Governance effectiveness

## References

- Kubecost allocation documentation
- FinOps Foundation best practices
- Cloud provider billing integration guides
