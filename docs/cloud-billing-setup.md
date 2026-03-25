# Cloud Billing Integration

Connect Kubecost to your cloud provider for invoice reconciliation.

**Status**: Optional for local development, **required** for production

## Why Cloud Billing?

| Without | With |
|---------|------|
| In-cluster estimates only | Actual invoice reconciliation |
| Missing network/storage costs | Full cost visibility |
| No cloud discounts visible | RI/Spot discount tracking |

---

## AWS Setup

### 1. Enable CUR (Cost and Usage Report)

AWS Billing Console → Cost & Usage Reports → Create report:
- **Name**: `kubecost-cur`
- **Time unit**: Hourly
- **Format**: Parquet

### 2. Create S3 Buckets

```bash
aws s3 mb s3://my-kubecost-cur-bucket
aws s3 mb s3://my-athena-query-results-bucket
```

### 3. Configure Kubecost

```yaml
# platform/kubecost/values.yaml
kubecostProductConfigs:
  cloudIntegrationSecret: cloud-integration
  athenaBucketName: my-athena-query-results-bucket
  athenaRegion: us-east-1
  athenaDatabase: athenacurcfn_kubecost
  athenaTable: kubecost_cur
  projectID: "123456789012"
```

### 4. Create Secret

```bash
cat > aws-cloud-integration.json <<EOF
{
  "aws_access_key_id": "AKIA...",
  "aws_secret_access_key": "...",
  "athena_bucket_name": "my-athena-query-results-bucket",
  "athena_region": "us-east-1",
  "athena_database": "athenacurcfn_kubecost",
  "athena_table": "kubecost_cur"
}
EOF

kubectl create secret generic cloud-integration \
  --from-file=aws-cloud-integration.json -n kubecost
```

---

## Azure Setup

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "kubecost" \
  --role "Cost Management Reader" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID"
```

```yaml
# values.yaml
kubecostProductConfigs:
  azureSubscriptionID: "xxx"
  azureClientID: "xxx"
  azureClientSecret: "..."
  azureTenantID: "xxx"
```

---

## GCP Setup

```bash
# Create service account
gcloud iam service-accounts create kubecost

# Grant BigQuery viewer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:kubecost@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"

# Download key
gcloud iam service-accounts keys create key.json \
  --iam-account=kubecost@$PROJECT_ID.iam.gserviceaccount.com
```

```bash
kubectl create secret generic gcp-billing-key \
  --from-file=key.json -n kubecost
```

```yaml
# values.yaml
kubecostProductConfigs:
  gcpSecretName: gcp-billing-key
  bigQueryBillingDataDataset: billing_data
```

---

## Verification

```bash
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090

# Check cloud cost endpoint
curl http://localhost:9090/model/cloudCost?window=7d
```

**Note**: Wait 24-48 hours for billing data to populate.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No cloud data | Check secret exists: `kubectl get secrets -n kubecost` |
| Costs don't match | Verify CUR includes all accounts |
| Athena errors | Check queries in AWS Athena console |

## References

- [Kubecost AWS Integration](https://docs.kubecost.com/install-and-configure/install/cloud-integration/aws-cloud-integrations)
- [Kubecost Azure Integration](https://docs.kubecost.com/install-and-configure/install/cloud-integration/azure-out-of-cluster)
- [Kubecost GCP Integration](https://docs.kubecost.com/install-and-configure/install/cloud-integration/gcp-out-of-cluster)
