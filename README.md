---
name: LiteralAI on Azure
description: Deploy LiteralAI to Azure Container Apps using the Azure Developer CLI.
languages:
  - bicep
  - azdeveloper
products:
  - azure-database-postgresql
  - azure-container-apps
  - azure
page_type: sample
urlFragment: literalai-azure
---

# LiteralAI on Azure

Use the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview) to deploy [LiteralAI](https://getliteral.ai) to Azure Container Apps with PostgreSQL Flexible server.

## Register on LiteralAI

To self-host LiteralAI you will need to be registered as described in [the documentation](https://docs.getliteral.ai/self-hosting/get-started). Depending on the option you select, you will receive either :

* A Literal Client ID and Authorization Token to run the public image
* Or a Docker PAT to run the private image

## Setup

1. Install the required tools:

   - [Azure Developer CLI](https://aka.ms/azure-dev/install)
   - [Python 3.9, 3.10, or 3.11](https://www.python.org/downloads/) (Only necessary if you want to enable authentication)

2. Create a new folder and switch to it in the terminal.
3. Run this command to download the project code:

   ```shell
   azd init -t literalai-azure
   ```

   Note that this command will initialize a git repository, so you do not need to clone this repository.

4. Create a Python virtual environment and install the required packages:

   ```shell
   pip install -r requirements.txt
   ```

5. Open a terminal window inside the project folder.

## Deploying to Azure

Follow these steps to deploy LiteralAI to Azure:

1. Login to your Azure account:

   ```shell
   azd auth login
   ```

2. Create a new azd environment:

   ```shell
   azd env new
   ```

   Enter a name that will be used for the resource group.
   This will create a new folder in the `.azure` folder, and set it as the active environment for any calls to `azd` going forward.

3. Enter your Literal AI credentials

This step depends on the option you selected when registering on LiteralAI :

If you opted for the public image, you need to provide the Literal Client ID and Authorization Token you received by mail :

   ```shell
   azd env set LITERAL_CLIENT_ID your-client-id
   azd env set LITERAL_AUTH_TOKEN 3a28db.....
   ```

If you opted for the private image, you need to provide the Docker PAT you have received :

   ```shell
   azd env set LITERAL_DOCKER_PAT your-docker-pat
   ```

4. (Optional) By default, the deployed Azure Container App will use the credentials authentication system, meaning anyone with routable network access to the web app can attempt to login to it. To enable Entra-based authentication, set the `AZURE_USE_AUTHENTICATION` environment variable to `true`:

   ```shell
   azd env set AZURE_USE_AUTHENTICATION true
   ```

   Then set the `AZURE_AD_TENANT_ID` environment variable to your tenant ID:

   ```shell
   azd env set AZURE_AD_TENANT_ID your-tenant-id
   ```

5. Run this command to provision all the resources (you will be prompted for your LiteralAI docker PAT):

   ```shell
   azd provision
   ```

   This will create a new resource group, and create:

   - An Azure Container App (based on the latest LiteralAI docker image available)
   - A PostgreSQL Flexible server
   - A Redis cache inside that group
   - A storage account as well as a storage container

   If you enabled authentication, it will set up the necessary resources for Entra-based authentication, and pass the necessary environment variables to the Azure Container App.

Once the deployment is complete, you will see the URL for the Azure Container App in the output. You can open this URL in your browser to see the LiteralAI platform.

## Update LiteralAI

Re running the `azd provision` command will update the LiteralAI deployment to the latest image.

## Reverting to a specific version

To revert to a specific version, set the `LITERAL_DOCKER_IMAGE_VERSION` env variable. For instance if you want to revert to the version `0.0.602-beta` run:

```shell
azd env set LITERAL_DOCKER_IMAGE_VERSION 0.0.602-beta
azd provision
```

## Disclaimer

LiteralAI is an external project and is not affiliated with Microsoft.
