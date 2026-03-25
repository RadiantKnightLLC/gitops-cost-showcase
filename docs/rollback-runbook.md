# Rollback Runbook

Quick recovery procedures for common issues.

---

## Quick Decision Matrix

| Scenario | Severity | Action | ETA |
|----------|----------|--------|-----|
| App deployment failure | Medium | Argo CD rollback | 5 min |
| Bad image in prod | High | Image rollback | 5 min |
| Argo CD down | High | CLI/kubectl rollback | 10 min |
| Full cluster failure | Critical | Cluster rebuild | 2 hours |

---

## Scenario 1: App Deployment Failure

**Symptoms**: Argo CD shows `Degraded`, pods in `CrashLoopBackOff`

**Rollback**:

```bash
# Via Argo CD CLI
argocd app history sample-app-dev
argocd app rollback sample-app-dev <revision-id>

# Or sync to specific commit
argocd app sync sample-app-dev --revision <commit-sha>
```

**Verify**:

```bash
argocd app wait sample-app-dev --health
kubectl get pods -n sample-app-dev
```

---

## Scenario 2: Bad Image in Production

**Rollback**:

```bash
# Option 1: Update kustomization to previous tag
# Edit apps/sample-app/overlays/prod/kustomization.yaml
images:
  - name: showcase-app-p1
    newTag: "<known-good-tag>"

# Apply
git add . && git commit -m "ROLLBACK: Revert image"
git push
argocd app sync sample-app-prod

# Option 2: Direct kubectl rollback
kubectl rollout undo deployment/prod-sample-app -n sample-app-prod
```

---

## Scenario 3: Argo CD Unavailable

**Diagnose**:

```bash
kubectl get pods -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

**Recovery**:

```bash
# Restart Argo CD
kubectl rollout restart deployment/argocd-server -n argocd
kubectl rollout restart deployment/argocd-application-controller -n argocd

# Or use kubectl directly
kubectl rollout undo deployment/<app> -n <namespace>
```

---

## Scenario 4: Full Cluster Failure (Kind)

**Rebuild**:

```bash
# Delete and recreate
kind delete cluster --name gitops-finops
kind create cluster --name gitops-finops

# Reinstall components
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy apps
kustomize build apps/sample-app/overlays/dev | kubectl apply -f -
kustomize build apps/sample-app/overlays/prod | kubectl apply -f -
```

---

## Post-Incident

1. Document in `tasks/incidents/`
2. Update this runbook if needed
3. Review cost impact in Kubecost

---

## References

- [Argo CD Rollback Docs](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_rollback/)
- [Kubectl Rollout](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)
