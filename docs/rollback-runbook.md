# Rollback Runbook

> **Purpose**: Disaster recovery procedures for the GitOps-FinOps Showcase
> 
> **Scope**: Application failures, infrastructure issues, cluster emergencies
> 
> **Owner**: Platform Engineering Team
> 
> **Last Updated**: 2026-03-23

---

## Emergency Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| Platform Lead | <!-- Add contact --> | +1 level |
| FinOps Lead | <!-- Add contact --> | +1 level |
| Security Team | <!-- Add contact --> | Immediate |

---

## Quick Decision Matrix

| Scenario | Severity | First Action | ETA to Restore |
|----------|----------|--------------|----------------|
| App deployment failure | Medium | Argo CD sync rollback | 5 min |
| Bad image in production | High | Image rollback + sync | 5 min |
| Argo CD unavailable | High | CLI rollback | 10 min |
| Kubecost data loss | Medium | PVC restore from backup | 30 min |
| Full cluster failure | Critical | Cluster rebuild | 2 hours |

---

## Scenario 1: Application Deployment Failure

### Symptoms
- Argo CD shows app as `Degraded` or `Progressing` with errors
- Pods in `CrashLoopBackOff` or `Error` state
- Service returning 5xx errors

### Diagnosis
```bash
# Check pod status
kubectl get pods -n <namespace>

# Check logs
kubectl logs -n <namespace> -l app.kubernetes.io/name=<app-name> --tail=100

# Check Argo CD app status
argocd app get <app-name>
```

### Rollback Procedure (Argo CD UI)
1. Open Argo CD UI → Applications → `<app-name>`
2. Click **"History and rollback"** button
3. Select last known good revision
4. Click **"Rollback"**
5. Confirm sync

### Rollback Procedure (CLI)
```bash
# List application history
argocd app history <app-name>

# Rollback to specific revision
argocd app rollback <app-name> <revision-id>

# Or sync to specific git commit
argocd app sync <app-name> --revision <commit-sha>
```

### Verification
```bash
# Wait for rollback
argocd app wait <app-name> --health

# Verify pod health
kubectl get pods -n <namespace> -w

# Check service health
curl -s http://<service-url>/health
```

---

## Scenario 2: Bad Image in Production

### Symptoms
- New image causes crashes or errors
- Rollback via Argo CD not working (image already pushed)

### Rollback Procedure
```bash
# Option 1: Re-tag previous image as latest
docker pull ghcr.io/radiantknightllc/showcase-app-p1:<previous-tag>
docker tag ghcr.io/radiantknightllc/showcase-app-p1:<previous-tag> ghcr.io/radiantknightllc/showcase-app-p1:latest
docker push ghcr.io/radiantknightllc/showcase-app-p1:latest

# Option 2: Update kustomization to use specific previous tag
# Edit apps/sample-app/overlays/prod/kustomization.yaml
images:
  - name: showcase-app-p1
    newTag: "<known-good-tag>"

# Apply changes
git add . && git commit -m "ROLLBACK: Revert to image <known-good-tag>"
git push origin main

# Sync Argo CD
argocd app sync sample-app-prod
```

### Verification
```bash
# Verify image tag
kubectl get deployment -n sample-app-prod -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'

# Wait for rollout
kubectl rollout status deployment/prod-sample-app -n sample-app-prod
```

---

## Scenario 3: Argo CD Unavailable

### Symptoms
- Argo CD UI not loading
- `argocd` CLI commands failing
- Cannot sync applications

### Diagnosis
```bash
# Check Argo CD pods
kubectl get pods -n argocd

# Check for resource issues
kubectl top pods -n argocd

# Check logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50
```

### Recovery Procedure
```bash
# Restart Argo CD components
kubectl rollout restart deployment/argocd-server -n argocd
kubectl rollout restart deployment/argocd-repo-server -n argocd
kubectl rollout restart deployment/argocd-application-controller -n argocd

# Wait for restart
kubectl rollout status deployment/argocd-server -n argocd

# Re-login
argocd login localhost:8080 --username admin --password $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
```

### Direct kubectl Rollback (if Argo CD still down)
```bash
# Manually rollback deployment
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Or apply previous manifest from git
git show <previous-commit>:apps/sample-app/overlays/prod/ | kubectl apply -f -
```

---

## Scenario 4: Kubecost Data Loss

### Symptoms
- Kubecost UI showing no data
- "No metrics available" errors
- Prometheus PVC issues

### Diagnosis
```bash
# Check Kubecost pods
kubectl get pods -n kubecost

# Check PVC status
kubectl get pvc -n kubecost

# Check Prometheus logs
kubectl logs -n kubecost -l app=prometheus --tail=50
```

### Recovery Procedure
```bash
# Restart Kubecost components
kubectl rollout restart deployment/kubecost-cost-analyzer -n kubecost

# If PVC is lost, redeploy
helm upgrade --install kubecost kubecost/cost-analyzer -n kubecost -f platform/kubecost/values.yaml

# Note: Historical data >15 days will be lost (Free tier limitation)
```

### Data Restoration
> **Note**: Kubecost Free tier has 15-day retention. Data older than 15 days cannot be recovered.

If using external storage (AWS S3/Azure Blob/GCS):
```bash
# Restore from backup (if configured)
# Follow cloud-specific restore procedures
```

---

## Scenario 5: Full Cluster Failure

### Symptoms
- All services down
- Control plane unreachable
- kubectl connection failures

### Recovery Procedure

#### Step 1: Assess
```bash
# Check cluster status
kubectl cluster-info

# If Kind cluster:
docker ps | grep gitops-finops
```

#### Step 2: Kind Cluster Rebuild
```bash
# Delete and recreate cluster
kind delete cluster --name gitops-finops
kind create cluster --name gitops-finops --config kind-network-config.yaml

# Reinstall Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Restore applications from git
kubectl apply -f argocd/app-of-apps.yaml

# Reinstall Kubecost
helm upgrade --install kubecost kubecost/cost-analyzer -n kubecost --create-namespace -f platform/kubecost/values.yaml
```

#### Step 3: Verify
```bash
# Check all pods
kubectl get pods --all-namespaces

# Check applications
argocd app list

# Check Kubecost
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090
```

---

## Cost Impact Verification

After any rollback, verify cost allocation is working:

```bash
# Port-forward Kubecost
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090 &

# Query cost allocation
curl "http://localhost:9090/model/allocation?window=1d&aggregate=namespace"

# Verify labels are present
kubectl get pods --all-namespaces --show-labels | grep -E "environment|team|cost-center|owner"
```

---

## Post-Incident Actions

1. **Document the incident** in `tasks/incidents/YYYY-MM-DD-incident-summary.md`
2. **Update this runbook** if new failure modes discovered
3. **Review cost impact** in Kubecost
4. **Schedule post-mortem** for high/critical severity incidents
5. **Update lessons learned** in `tasks/lessons.md`

---

## Related Documentation

- [Argo CD Rollback Docs](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_rollback/)
- [Kubectl Rollout Docs](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)
- [Image Promotion Guide](./image-promotion.md)
