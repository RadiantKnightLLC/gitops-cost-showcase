# Cloud Billing Integration Setup

## Overview

This guide configures Kubecost to reconcile in-cluster costs with actual cloud provider invoices.

**Status**: Optional for development, **required** for production showcase

## Why Cloud Billing Matters

| Without Cloud Billing | With Cloud Billing |
|----------------------|-------------------|
| In-cluster estimates only | Actual invoice reconciliation |
| Missing network egress | Full network cost attribution |
| Missing storage costs | Storage cost visibility |
| Missing cloud discounts | RI/Spot discount visibility |
| Cannot prove ROI | Credible FinOps story |

---

## AWS Cost and Usage Report (CUR)

### Step 1: Enable CUR in AWS Billing Console

1. Go to AWS Billing Console → Cost & Usage Reports
2. Click "Create report"
3. Configure:
   - **Report name**: `kubecost-cur`
   - **Time unit**: Hourly
   - **Report versioning**: Overwrite existing
   - **Compression**: Parquet
   - **Format**: Parquet

### Step 2: Create S3 Bucket

```bash
aws s3 mb s3://my-kubecost-cur-bucket
```

### Step 3: Configure Athena

Kubecost uses Athena to query CUR data:

```bash
# Athena outputs query results to S3
aws s3 mb s3://my-athena-query-results-bucket

# Note the Athena database and table names
# Database: athenacurcfn_kubecost
# Table: kubecost_cur
```

### Step 4: Update Kubecost Values

```yaml
# platform/kubecost/values.yaml
kubecostProductConfigs:
  # AWS configuration
  cloudIntegrationSecret: cloud-integration
  
  # Spot data feed (optional but recommended)
  awsSpotDataBucket: my-spot-data-feed-bucket
  awsSpotDataRegion: us-east-1
  
  # Athena configuration for CUR
  athenaBucketName: my-athena-query-results-bucket
  athenaRegion: us-east-1
  athenaDatabase: athenacurcfn_kubecost
  athenaTable: kubecost_cur
  athenaWorkgroup: primary
  
  # AWS Account ID
  projectID: "123456789012"
```

### Step 5: Create Cloud Integration Secret

```bash
# Create AWS credentials secret
cat > aws-cloud-integration.json <<EOF
{
  "aws_access_key_id": "AKIA...",
  "aws_secret_access_key": "...",
  "athena_bucket_name": "my-athena-query-results-bucket",
  "athena_region": "us-east-1",
  "athena_database": "athenacurcfn_kubecost",
  "athena_table": "kubecost_cur",
  "master_payer_arn": "arn:aws:iam::123456789012:role/KubecostRole"
}
EOF

kubectl create secret generic cloud-integration \
  --from-file=aws-cloud-integration.json \
  -n kubecost
```

### Step 6: Verify Integration

```bash
# Port forward to Kubecost
kubectl port-forward svc/kubecost-cost-analyzer -n kubecost 9090

# Check cloud cost endpoint
curl http://localhost:9090/model/cloudCost?window=7d
```

---

## Azure Cost Export

### Step 1: Create Cost Export

1. Azure Portal → Cost Management + Billing → Exports
2. Create daily export to Storage Account
3. Format: CSV

### Step 2: Configure Service Principal

```bash
# Create app registration
az ad sp create-for-rbac \
  --name "kubecost" \
  --role "Cost Management Reader" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID"
```

### Step 3: Update Kubecost Values

```yaml
kubecostProductConfigs:
  azureSubscriptionID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  azureClientID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  azureClientSecret: "..."
  azureTenantID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  azureBillingRegion: "US"
```

---

## GCP BigQuery Billing Export

### Step 1: Enable Billing Export

1. Cloud Console → Billing → Billing Export
2. Enable BigQuery export
3. Dataset: `billing_data`

### Step 2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create kubecost \
  --display-name="Kubecost Billing Reader"

# Grant BigQuery Data Viewer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:kubecost@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"

# Download key
gcloud iam service-accounts keys create key.json \
  --iam-account=kubecost@$PROJECT_ID.iam.gserviceaccount.com
```

### Step 3: Update Kubecost Values

```yaml
kubecostProductConfigs:
  gcpSecretName: gcp-billing-key
  bigQueryBillingDataDataset: billing_data
```

### Step 4: Create Secret

```bash
kubectl create secret generic gcp-billing-key \
  --from-file=key.json \
  -n kubecost
```

---

## Verification

After configuration:

1. **Wait 24-48 hours** for billing data to populate
2. Check Kubecost UI → Cloud Costs
3. Verify costs match cloud console invoices
4. Compare in-cluster vs cloud-billing reconciled costs

## Troubleshooting

### No cloud cost data showing

1. Check secret exists: `kubectl get secrets -n kubecost`
2. Verify credentials: `kubectl logs -n kubecost deployment/kubecost-cost-analyzer | grep -i cloud`
3. Check Athena queries are succeeding in AWS Console

### Costs don't match invoice

1. Verify CUR includes all accounts (payer account setup)
2. Check for tax line items (may be excluded)
3. Ensure discounts/credits are configured correctly

## Security Considerations

- Store credentials as Kubernetes secrets
- Use IAM roles (AWS) / Service Principals (Azure) with minimal permissions
- Rotate credentials regularly
- Audit secret access

## References

- [Kubecost AWS Cloud Integration](https://docs.kubecost.com/install-and-configure/install/cloud-integration/aws-cloud-integrations)
- [Kubecost Azure Cloud Integration](https://docs.kubecost.com/install-and-configure/install/cloud-integration/azure-out-of-cluster)
- [Kubecost GCP Cloud Integration](https://docs.kubecost.com/install-and-configure/install/cloud-integration/gcp-out-of-cluster)
