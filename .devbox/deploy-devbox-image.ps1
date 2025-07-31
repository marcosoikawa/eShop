# eShop Dev Box Image Deployment Script
# This script helps deploy the eShop Dev Box image definition to Azure

param (
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$location,
    
    [Parameter(Mandatory=$false)]
    [string]$galleryName = "eShopDevBoxGallery",
    
    [Parameter(Mandatory=$false)]
    [string]$imageDefName = "eShop-Dev-Environment"
)

# Login to Azure
Write-Host "Please login to your Azure account..." -ForegroundColor Yellow
az login

# Check if resource group exists, create if not
$rgCheck = az group show --name $resourceGroupName --query name -o tsv 2>$null
if (-not $rgCheck) {
    Write-Host "Creating resource group '$resourceGroupName'..." -ForegroundColor Cyan
    az group create --name $resourceGroupName --location $location
}

# Register required providers
Write-Host "Registering required resource providers..." -ForegroundColor Cyan
az provider register --namespace Microsoft.VirtualMachineImages
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network

# Wait for providers to register
Write-Host "Waiting for providers to register..." -ForegroundColor Cyan
az provider show -n Microsoft.VirtualMachineImages -o table
az provider show -n Microsoft.Compute -o table
az provider show -n Microsoft.KeyVault -o table
az provider show -n Microsoft.Storage -o table
az provider show -n Microsoft.Network -o table

# Create Shared Image Gallery
Write-Host "Creating Shared Image Gallery '$galleryName'..." -ForegroundColor Cyan
$galleryExists = az sig show --gallery-name $galleryName --resource-group $resourceGroupName --query name -o tsv 2>$null
if (-not $galleryExists) {
    az sig create --resource-group $resourceGroupName --gallery-name $galleryName
}

# Create image definition
Write-Host "Creating image definition '$imageDefName'..." -ForegroundColor Cyan
$imageDefExists = az sig image-definition show --gallery-name $galleryName --resource-group $resourceGroupName --gallery-image-definition $imageDefName --query name -o tsv 2>$null
if (-not $imageDefExists) {
    az sig image-definition create \
        --resource-group $resourceGroupName \
        --gallery-name $galleryName \
        --gallery-image-definition $imageDefName \
        --publisher "eShopOnAspire" \
        --offer "eShopDevBox" \
        --sku "Windows11" \
        --os-type Windows \
        --hyper-v-generation V2 \
        --os-state generalized
}

# Get current user identity
$userId = az ad signed-in-user show --query id -o tsv

# Assign roles
Write-Host "Assigning required roles..." -ForegroundColor Cyan
az role assignment create \
    --assignee $userId \
    --role "Contributor" \
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroupName"

az role assignment create \
    --assignee $userId \
    --role "User Access Administrator" \
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroupName"

# Create identity for image builder
$identityName = "eShopImageBuilderIdentity"
Write-Host "Creating managed identity '$identityName'..." -ForegroundColor Cyan
$identityExists = az identity show --name $identityName --resource-group $resourceGroupName --query name -o tsv 2>$null
if (-not $identityExists) {
    az identity create --name $identityName --resource-group $resourceGroupName
}

$identityId = az identity show --name $identityName --resource-group $resourceGroupName --query id -o tsv
$identityPrincipalId = az identity show --name $identityName --resource-group $resourceGroupName --query principalId -o tsv

# Assign roles to the identity
Write-Host "Assigning roles to the managed identity..." -ForegroundColor Cyan
az role assignment create \
    --assignee $identityPrincipalId \
    --role "Contributor" \
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroupName"

# Deploy the image template
Write-Host "Deploying the image template..." -ForegroundColor Cyan
az deployment group create \
    --resource-group $resourceGroupName \
    --template-file "./.devbox/devbox-image.json" \
    --parameters imageGalleryName=$galleryName imageDefinitionName=$imageDefName

# Get the image template name from the output
$imageTemplateName = az deployment group show \
    --resource-group $resourceGroupName \
    --name devbox-image \
    --query properties.outputs.imageTemplateName.value \
    -o tsv

# Build the image
Write-Host "Building the image (this may take 1-2 hours)..." -ForegroundColor Yellow
az resource invoke-action \
    --resource-group $resourceGroupName \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    --name $imageTemplateName \
    --action Run

Write-Host @"

=============================================
Dev Box Image Build Started!
=============================================

The build process has been started and may take 1-2 hours to complete.
You can check the status with:

az image builder show --name $imageTemplateName --resource-group $resourceGroupName --query lastRunStatus -o table

Once completed, you can use this image in your Dev Box project by referencing:
- Gallery: $galleryName
- Image Definition: $imageDefName

"@ -ForegroundColor Green