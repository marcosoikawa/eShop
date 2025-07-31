# eShop Development Box

This directory contains the configuration files needed to create an Azure Dev Box image for the eShop reference application. The Dev Box image provides a fully configured development environment with all the tools and dependencies required to develop, build, and run the eShop application.

## Included Tools and Components

The Dev Box image includes:

- **Windows 11 Enterprise** - Base operating system
- **Visual Studio 2022 Enterprise** - Full-featured IDE with the following workloads:
  - ASP.NET and web development
  - .NET Multi-platform App UI development (MAUI)
  - Azure development
  - .NET Aspire SDK component
- **.NET 9 SDK** - Latest version of the .NET development platform
- **Docker Desktop** - Container platform for running services and dependencies
- **Git** - Source control management
- **Visual Studio Code** - Lightweight code editor with C# extensions
- **Azure CLI** - Command-line tools for Azure
- **Azure Developer CLI (azd)** - Streamlined CLI for Azure application development
- **PostgreSQL** - Database engine
- **WinGet Configuration Module** - For automated environment setup

## Creating the Dev Box Image

### Prerequisites

To create and deploy the Dev Box image, you'll need:

1. An Azure subscription
2. Azure CLI installed locally
3. PowerShell 7.0 or higher

### Deployment Steps

1. Clone this repository to your local machine:

```powershell
git clone https://github.com/dotnet/eshop.git
cd eshop/.devbox
```

2. Run the deployment script:

```powershell
./deploy-devbox-image.ps1 -resourceGroupName "eShop-DevBox-RG" -location "eastus"
```

You can customize the deployment by specifying additional parameters:
- `-galleryName` - Name of the Compute Gallery (default: "eShopDevBoxGallery")
- `-imageDefName` - Name of the Image Definition (default: "eShop-Dev-Environment")

3. The script will:
   - Create a resource group (if it doesn't exist)
   - Register required Azure providers
   - Create an Azure Compute Gallery
   - Create an Image Definition
   - Deploy the Dev Box image template
   - Start the image build process

4. The build process typically takes 1-2 hours to complete. You can check the status with:

```powershell
az image builder show --name eShop-DevBox-Image --resource-group eShop-DevBox-RG --query lastRunStatus -o table
```

## Setting Up a Dev Box Project

After creating the image, you'll need to set up a Dev Box project to use it:

1. Go to the [Microsoft Dev Box portal](https://devbox.microsoft.com/)
2. Create a new Dev Box project
3. Create a Dev Box pool within your project
4. When configuring the pool, select your custom image:
   - Choose "Shared Image Gallery" as the image source
   - Select your subscription
   - Select the Compute Gallery you created ("eShopDevBoxGallery")
   - Choose the Image Definition ("eShop-Dev-Environment")

5. Complete the configuration with appropriate compute size, network settings, etc.

## Using the Dev Box

Once your Dev Box is provisioned and you connect to it:

1. A setup shortcut will be available on the desktop ("eShop Setup")
2. Run this setup script to:
   - Clone the eShop repository (if not already present)
   - Install HTTPS development certificates
   - Configure any remaining environment settings

3. Open Visual Studio and load the `eShop.Web.slnf` solution file
4. Make sure Docker Desktop is running
5. Set `eShop.AppHost.csproj` as the startup project and press F5 to run the application

## Troubleshooting

If you encounter issues with the Dev Box deployment:

1. Check the image build logs:
```powershell
az image builder log show --resource-group eShop-DevBox-RG --name eShop-DevBox-Image
```

2. Ensure all required Azure providers are registered in your subscription
3. Verify that your user account or service principal has sufficient permissions to create resources

## Additional Resources

- [Azure Dev Box documentation](https://learn.microsoft.com/en-us/azure/dev-box/)
- [eShop reference application documentation](https://github.com/dotnet/eshop)
- [.NET Aspire documentation](https://learn.microsoft.com/dotnet/aspire/)