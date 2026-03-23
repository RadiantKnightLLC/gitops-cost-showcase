#!/bin/bash
# Validate Kubernetes labels for GitOps-FinOps Showcase
# Checks that Deployments have required pod-template labels

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Required pod-template labels for FinOps cost allocation
REQUIRED_LABELS=("environment" "team" "cost-center" "owner")

# Valid values for each label
declare -A VALID_VALUES
VALID_VALUES["environment"]="dev prod staging"
VALID_VALUES["team"]="platform backend frontend"
VALID_VALUES["cost-center"]="agency-rnd agency-ops"
VALID_VALUES["owner"]="agency-internal"

ERRORS=0
WARNINGS=0

echo "🔍 Validating Kubernetes labels..."
echo ""

# Find all Deployment YAML files
DEPLOYMENT_FILES=$(find apps/ platform/ -name "*.yaml" -o -name "*.yml" 2>/dev/null | xargs grep -l "kind: Deployment" 2>/dev/null || true)

if [ -z "$DEPLOYMENT_FILES" ]; then
    echo -e "${YELLOW}⚠️  No Deployment files found${NC}"
    exit 0
fi

for file in $DEPLOYMENT_FILES; do
    echo "📄 Checking: $file"
    
    # Check if file has spec.template.metadata.labels
    HAS_POD_TEMPLATE=$(yq eval 'has("spec") and .spec | has("template") and .spec.template | has("metadata") and .spec.template.metadata | has("labels")' "$file" 2>/dev/null || echo "false")
    
    if [ "$HAS_POD_TEMPLATE" != "true" ]; then
        echo -e "  ${RED}❌ Missing spec.template.metadata.labels${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    fi
    
    # Get pod-template labels
    POD_LABELS=$(yq eval '.spec.template.metadata.labels' "$file" 2>/dev/null || echo "")
    
    # Check each required label
    for label in "${REQUIRED_LABELS[@]}"; do
        LABEL_VALUE=$(echo "$POD_LABELS" | yq eval ".$label" 2>/dev/null || echo "")
        
        if [ -z "$LABEL_VALUE" ] || [ "$LABEL_VALUE" == "null" ]; then
            echo -e "  ${RED}❌ Missing required label: $label${NC}"
            ERRORS=$((ERRORS + 1))
        else
            # Validate label value
            VALID_VALUES_LIST=${VALID_VALUES[$label]}
            if [[ " $VALID_VALUES_LIST " =~ " $LABEL_VALUE " ]]; then
                echo -e "  ${GREEN}✅ $label=$LABEL_VALUE${NC}"
            else
                echo -e "  ${YELLOW}⚠️  $label=$LABEL_VALUE (unexpected value, expected: $VALID_VALUES_LIST)${NC}"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done
    
    # Check for recommended Kubernetes labels
    K8S_NAME=$(echo "$POD_LABELS" | yq eval '."app.kubernetes.io/name"' 2>/dev/null || echo "")
    if [ -z "$K8S_NAME" ] || [ "$K8S_NAME" == "null" ]; then
        echo -e "  ${YELLOW}⚠️  Missing recommended label: app.kubernetes.io/name${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "  ${GREEN}✅ app.kubernetes.io/name=$K8S_NAME${NC}"
    fi
    
    echo ""
done

# Summary
echo "========================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All labels validated successfully${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Validation passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Required pod-template labels for FinOps cost allocation:"
    echo "  - environment: dev | prod | staging"
    echo "  - team: platform | backend | frontend"
    echo "  - cost-center: agency-rnd | agency-ops"
    echo "  - owner: agency-internal"
    echo ""
    echo "Fix: Add labels to spec.template.metadata.labels in your Deployment"
    exit 1
fi
