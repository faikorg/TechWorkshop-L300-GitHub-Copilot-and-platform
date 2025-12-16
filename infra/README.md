# ZavaStorefront Infrastructure Deployment Guide

This document provides comprehensive instructions for deploying the ZavaStorefront application infrastructure to Azure using Azure Developer CLI (AZD) and Bicep.

## Architecture Overview

The infrastructure consists of the following Azure resources:

- **Azure Container Registry (ACR)**: Stores Docker container images
- **Azure App Service**: Linux-based web app hosting the containerized application
- **App Service Plan**: B1 Linux plan for container support
- **Application Insights**: Application monitoring and telemetry
- **Log Analytics Workspace**: Centralized logging
- **Azure OpenAI Service**: AI capabilities with GPT-4 and Phi-3 models
- **Managed Identity & RBAC**: Secure authentication without secrets

### Key Features

✅ **No Docker Required Locally**: Container images are built directly in Azure Container Registry  
✅ **Secure by Default**: RBAC-based authentication (no passwords/secrets)  
✅ **Infrastructure as Code**: All resources defined in modular Bicep templates  
✅ **Full Monitoring**: Application Insights integration for observability  
✅ **AI-Ready**: Azure OpenAI with GPT-4 and Phi-3 models in westus3  

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and authenticated
   ```powershell
   az login
   az account set --subscription <subscription-id>
   ```

2. **Azure Developer CLI (AZD)** installed
   ```powershell
   # Install via PowerShell
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
   
   # Or via winget
   winget install microsoft.azd
   ```

3. **Required Azure Permissions**:
   - Contributor role on the subscription or resource group
   - User Access Administrator role (for RBAC assignments)

## Quick Start

### 1. Initialize AZD Environment

```powershell
# Navigate to the project root
cd TechWorkshop-L300-GitHub-Copilot-and-platform

# Initialize AZD (if not already initialized)
azd init

# Set environment variables
azd env set AZURE_ENV_NAME dev
azd env set AZURE_LOCATION westus3
```

### 2. Provision Infrastructure

This command deploys all Azure resources defined in the Bicep templates:

```powershell
azd provision
```

**What happens during provisioning:**
- Creates a new resource group in westus3
- Deploys all infrastructure resources using Bicep
- Configures RBAC assignments for secure access
- Automatically builds the container image in ACR (via post-provision hook)

### 3. Deploy Application

After infrastructure is provisioned, deploy the application:

```powershell
azd deploy
```

### 4. Access the Application

```powershell
# Get the application URL
azd env get-values | Select-String "AZURE_APP_SERVICE_URL"

# Or visit the Azure Portal to find the App Service URL
```

## Detailed Deployment Steps

### Manual Container Build (Optional)

If you need to manually build the container image:

```powershell
# Get the ACR name
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME

# Build the image in ACR (no Docker required locally!)
az acr build `
  --registry $acrName `
  --image zava-storefront:latest `
  --file ./src/Dockerfile `
  ./src
```

### Updating the Application

To update the application after making code changes:

```powershell
# Option 1: Use AZD deploy (rebuilds and deploys)
azd deploy

# Option 2: Manually rebuild container
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME
az acr build --registry $acrName --image zava-storefront:latest --file ./src/Dockerfile ./src

# Restart the App Service to pull the new image
$appServiceName = azd env get-value AZURE_APP_SERVICE_NAME
az webapp restart --name $appServiceName --resource-group rg-zava-storefront-dev-westus3
```

## Infrastructure Details

### Bicep Structure

```
infra/
├── main.bicep                      # Main orchestration file
├── main.bicepparam                 # Dev environment parameters
└── modules/
    ├── container-registry.bicep    # Azure Container Registry
    ├── app-service-plan.bicep      # App Service Plan (Linux)
    ├── app-service.bicep           # App Service with container config
    ├── log-analytics.bicep         # Log Analytics Workspace
    ├── application-insights.bicep  # Application Insights
    ├── openai.bicep                # Azure OpenAI with GPT-4 & Phi-3
    └── role-assignment.bicep       # RBAC role assignments
```

### Security Configuration

#### Managed Identity & RBAC

The App Service uses a **System-Assigned Managed Identity** with the following role assignments:

- **AcrPull**: Allows pulling container images from ACR
- **Cognitive Services OpenAI User**: Allows access to Azure OpenAI models

**No secrets or credentials are stored in configuration!**

#### Application Insights Integration

Application Insights is automatically configured with:
- Connection string injected as environment variable
- Application Insights agent enabled
- Telemetry sent to Log Analytics workspace

### Resource Naming Convention

Resources follow Azure naming best practices:

| Resource Type | Naming Pattern | Example |
|--------------|----------------|---------|
| Resource Group | `rg-{app}-{env}-{region}` | `rg-zava-storefront-dev-westus3` |
| Container Registry | `acr{app}{uniqueid}` | `acrzavastorefront7h3k9m` |
| App Service Plan | `asp-{app}-{env}` | `asp-zava-storefront-dev` |
| App Service | `app-{app}-{env}-{uniqueid}` | `app-zava-storefront-dev-7h3k9m` |
| App Insights | `appi-{app}-{env}` | `appi-zava-storefront-dev` |
| Log Analytics | `log-{app}-{env}` | `log-zava-storefront-dev` |
| Azure OpenAI | `openai-{app}-{env}-{uniqueid}` | `openai-zava-storefront-dev-7h3k9m` |

## Monitoring & Observability

### Application Insights

Access Application Insights from the Azure Portal:

1. Navigate to the App Insights resource
2. View metrics, logs, and performance data
3. Set up alerts for critical issues

### Log Analytics Queries

Query logs using KQL (Kusto Query Language):

```kusto
// View recent application traces
traces
| where timestamp > ago(1h)
| order by timestamp desc

// View failed requests
requests
| where success == false
| order by timestamp desc
```

## Azure OpenAI Integration

The infrastructure includes Azure OpenAI with two model deployments:

### Deployed Models

1. **GPT-4o** (Latest GPT-4 optimized model)
   - Deployment Name: `gpt-4`
   - Model Version: `2024-08-06`
   - Capacity: 10 units

2. **GPT-4o-mini** (Cost-effective smaller model)
   - Deployment Name: `gpt-4o-mini`
   - Model Version: `2024-07-18`
   - Capacity: 10 units

> **Note**: The original plan included Phi-3 models, but these are currently available through Azure AI Studio Model Catalog rather than Azure OpenAI Service. For this deployment, we're using GPT-4o-mini as a cost-effective, high-performance alternative. If you specifically need Phi models, consider using Azure AI Studio or Azure Machine Learning.

### Access from Application

The App Service can access Azure OpenAI using its Managed Identity:

```csharp
// Example usage in .NET
var credential = new DefaultAzureCredential();
var endpoint = Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT");
var client = new OpenAIClient(new Uri(endpoint), credential);
```

## Troubleshooting

### Common Issues

#### Issue: Container image not found

**Solution**: Ensure the container image is built in ACR:

```powershell
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME
az acr build --registry $acrName --image zava-storefront:latest --file ./src/Dockerfile ./src
```

#### Issue: App Service shows "Application Error"

**Solution**: Check Application Insights logs or App Service logs:

```powershell
# View App Service logs
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>
```

#### Issue: RBAC permissions not working

**Solution**: Wait a few minutes for role assignments to propagate, then restart the App Service:

```powershell
az webapp restart --name <app-service-name> --resource-group <resource-group-name>
```

### Viewing Deployment Logs

```powershell
# View AZD provision logs
azd provision --debug

# View Azure deployment logs
az deployment group show --name <deployment-name> --resource-group <resource-group-name>
```

## Cleanup

To delete all resources:

```powershell
# Delete all resources
azd down

# Or manually delete the resource group
az group delete --name rg-zava-storefront-dev-westus3 --yes --no-wait
```

## Environment Variables

The following environment variables are automatically set by AZD:

| Variable | Description |
|----------|-------------|
| `AZURE_CONTAINER_REGISTRY_NAME` | ACR name |
| `AZURE_CONTAINER_REGISTRY_LOGIN_SERVER` | ACR login server URL |
| `AZURE_APP_SERVICE_NAME` | App Service name |
| `AZURE_APP_SERVICE_URL` | App Service public URL |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection string |
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI endpoint URL |

## Cost Estimation

**Estimated monthly cost for dev environment (westus3):**

- App Service Plan (B1): ~$13/month
- Container Registry (Basic): ~$5/month
- Application Insights: Pay-as-you-go (minimal for dev)
- Log Analytics: Pay-as-you-go (minimal for dev)
- Azure OpenAI: Pay-per-token usage

**Total: ~$20-30/month** (excluding AI usage)

## Best Practices

1. **Use AZD for all operations**: Consistent deployment experience
2. **Never commit secrets**: All authentication via Managed Identity
3. **Monitor costs**: Set up budget alerts in Azure Portal
4. **Use Bicep parameters**: Separate environment configurations
5. **Enable diagnostic logs**: Better troubleshooting capabilities
6. **Tag resources**: Use consistent tagging for cost tracking

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Container Documentation](https://learn.microsoft.com/azure/app-service/configure-custom-container)
- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [Application Insights Documentation](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Application Insights logs
3. Consult Azure documentation
4. Open an issue in the repository
