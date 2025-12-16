# GitHub Actions Deployment Setup

This guide explains how to configure GitHub Actions to automatically build and deploy the ZavaStorefront application to Azure App Service.

## Prerequisites

- Azure infrastructure already provisioned (via `azd provision`)
- GitHub repository with this code
- Azure CLI installed locally

## Configuration Steps

### 1. Create Azure Service Principal

Create a service principal with Contributor access to your resource group:

```bash
# Get your subscription ID
az account show --query id -o tsv

# Create service principal (replace placeholders)
az ad sp create-for-rbac \
  --name "github-actions-zava-storefront" \
  --role Contributor \
  --scopes /subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP_NAME} \
  --sdk-auth
```

**Copy the entire JSON output** - you'll need it for the next step.

### 2. Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

#### Add Secret:

| Name | Value | Description |
|------|-------|-------------|
| `AZURE_CREDENTIALS` | *JSON output from step 1* | Service principal credentials for Azure login |

### 3. Configure GitHub Variables

In the same **Actions** page, go to the **Variables** tab:

| Name | Value | How to Get |
|------|-------|-----------|
| `AZURE_CONTAINER_REGISTRY_NAME` | `acrzavastorefront...` | `azd env get-value AZURE_CONTAINER_REGISTRY_NAME` |
| `AZURE_CONTAINER_REGISTRY_LOGIN_SERVER` | `acrzavastorefront....azurecr.io` | `azd env get-value AZURE_CONTAINER_REGISTRY_LOGIN_SERVER` |
| `AZURE_APP_SERVICE_NAME` | `app-zava-storefront-dev-...` | `azd env get-value AZURE_APP_SERVICE_NAME` |

### 4. Grant ACR Permissions to Service Principal

The service principal needs permissions to push images to ACR:

```bash
# Get the service principal's object ID
SP_ID=$(az ad sp list --display-name "github-actions-zava-storefront" --query "[0].id" -o tsv)

# Get the ACR resource ID
ACR_ID=$(az acr show --name {ACR_NAME} --query id -o tsv)

# Assign AcrPush role
az role assignment create \
  --assignee $SP_ID \
  --role AcrPush \
  --scope $ACR_ID
```

## Workflow Trigger

The workflow automatically runs when:
- Code is pushed to the `main` branch in the `src/` directory
- Manually triggered via **Actions** tab → **Run workflow**

## Workflow Steps

1. **Checkout code** - Gets the latest code from the repository
2. **Log in to Azure** - Authenticates using service principal credentials
3. **Log in to ACR** - Authenticates to Azure Container Registry
4. **Build and push** - Builds Docker image in ACR and tags with commit SHA + latest
5. **Deploy to App Service** - Updates App Service to use the new container image
6. **Logout** - Cleans up Azure session

## Monitoring Deployments

- View workflow runs: **Actions** tab in GitHub repository
- View App Service logs: Azure Portal → App Service → Log stream
- View Application Insights: Azure Portal → Application Insights resource

## Troubleshooting

### Issue: "unauthorized: authentication required"

**Solution**: Ensure the service principal has `AcrPush` role on ACR (see step 4).

### Issue: "ResourceNotFound" for App Service

**Solution**: Verify `AZURE_APP_SERVICE_NAME` variable matches the actual App Service name.

### Issue: Workflow fails with authentication error

**Solution**: Regenerate the service principal credentials and update `AZURE_CREDENTIALS` secret.

## Security Best Practices

✅ Service principal scoped to specific resource group  
✅ Secrets never exposed in logs  
✅ Variables used for non-sensitive configuration  
✅ Azure logout step ensures session cleanup  
✅ Container images tagged with commit SHA for traceability  

## Next Steps

After setup, simply push code changes to trigger automatic deployment:

```bash
git add .
git commit -m "Update application"
git push origin main
```

The workflow will automatically build and deploy your changes to Azure App Service.
