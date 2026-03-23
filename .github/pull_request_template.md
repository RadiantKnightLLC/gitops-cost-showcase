# Pull Request

## Summary
<!-- Provide a brief summary of changes -->

## Type of Change
<!-- Check all that apply -->
- [ ] Bug fix
- [ ] New feature
- [ ] Configuration change
- [ ] Documentation update
- [ ] Infrastructure change

## FinOps Cost Impact Assessment
<!-- Required for infrastructure/resource changes -->

### Resource Changes
| Resource | Before | After | Cost Impact |
|----------|--------|-------|-------------|
| Replicas | <!-- e.g., 1 --> | <!-- e.g., 2 --> | <!-- $X/month --> |
| CPU | <!-- e.g., 100m --> | <!-- e.g., 200m --> | <!-- $Y/month --> |
| Memory | <!-- e.g., 128Mi --> | <!-- e.g., 256Mi --> | <!-- $Z/month --> |
| Storage | <!-- e.g., 1Gi --> | <!-- e.g., 2Gi --> | <!-- $W/month --> |

**Estimated Monthly Cost Change:** $<!-- amount --> (increase/decrease/neutral)

### Cost Justification
<!-- Explain why this cost change is necessary -->

## GitOps Compliance Checklist
<!-- All items must be checked before merge -->

### Labels (Required for FinOps)
- [ ] `environment` label present in pod-template (dev/prod/staging)
- [ ] `team` label present in pod-template (platform/backend/frontend)
- [ ] `cost-center` label present in pod-template (agency-rnd/agency-ops)
- [ ] `owner` label present in pod-template (agency-internal)
- [ ] Kubernetes recommended labels present (`app.kubernetes.io/name`, etc.)

### Sync Waves (Required for Ordered Deployment)
- [ ] Namespace resources use sync-wave: -2
- [ ] Config/Secret resources use sync-wave: -1 (if applicable)
- [ ] Application resources use sync-wave: 0, 1, or 2
- [ ] Sync wave is within valid range [-2, 2]

### Security
- [ ] No hardcoded secrets in manifests
- [ ] Images use specific tags (not `latest`)
- [ ] Resource requests and limits defined
- [ ] Security context configured (runAsNonRoot, readOnlyRootFilesystem)

### Validation
- [ ] `kustomize build overlays/dev` succeeds
- [ ] `kustomize build overlays/prod` succeeds
- [ ] All pre-commit hooks pass locally
- [ ] YAML syntax is valid

## Testing
<!-- Describe how this was tested -->
- [ ] Local kustomize build test
- [ ] Dry-run against dev cluster: `kubectl apply --dry-run=client -f -`
- [ ] Argo CD diff review completed
- [ ] Kubecost cost impact verified (if applicable)

## Deployment Plan
<!-- Required for prod changes -->

### Dev Environment
- Deployment: <!-- Auto/Manual -->
- Expected time: <!-- X minutes -->
- Rollback plan: <!-- How to revert if issues -->

### Prod Environment (if applicable)
- Deployment strategy: <!-- Direct/Canary/Blue-Green -->
- Approval required: <!-- Yes/No -->
- Monitoring period: <!-- X minutes/hours -->
- Rollback time: <!-- ETA to rollback -->

## Related Issues
<!-- Link to related GitHub issues -->
Fixes #<!-- issue number -->
Relates to #<!-- issue number -->

## Additional Notes
<!-- Any other context for reviewers -->

---

**Reviewers:** Please verify:
1. Cost impact is reasonable and documented
2. All required labels are present
3. Security best practices are followed
4. Rollback plan is clear and executable
