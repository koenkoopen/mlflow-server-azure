# MLFlow Tracking Server on Azure

This repository contains code which can be used to deploy an [MLflow server](https://mlflow.org/docs/latest/index.html) on Azure using either [Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) or [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/).

## Infrastructure as Code

Deployment of the MLFlow server is done using IaC. This repository provides 2 options: Bicep and Terraform.
For both options the necessary files & descriptions are provided in the `terraform` and `bicep` folders respectively.

The setup in both cases is very similar.
We want the MLFlow server to be hosted in Azure, so we need to configure the following:

- Create an Azure resource group
- Create an Azure container registry
- Create an Azure storage account with a container & a file share
- Create an Azure container instance

You might want to put your resources in a virtual network for security purposes so that it can only accessed from certain IP addresses.

In the next sections we will go through each step for both the Terraform and Bicep options.

### Terraform

Terraform keeps track of it's state in a `terraform.tfstate` file.
When you are deploying your Terraform code from your local computer this file will be automatically created for you and stored in your repository.
However, if you are running your Terraform code from within a CI/CD pipeline, you will need a place to store your state file and retreive it from in future runs.

#### Running the deployment with Terraform from local

You must `cd` to the directory of your `main.tf` file and run the following commands:

```
terraform init
terraform plan
terraform apply
```

You must enter `yes` when asked if you want to continue.
This will first initialize the Terraform state, show the planned changes to be made and will then create the infrastructure.
First some resources such as a storage account and a container registry will be created. Next, an Docker image will be build in which the MLFlow server will run. Finally, an Azure container instance will be created to run the Docker image and so host the MLFlow server.

#### Using a CI/CD pipeline

If you wish to deploy using a CI/CD pipeline, it is recommended to create a Azure storage account and store the state file in it.
You can refer to this storage account by configuring the `backend "azurerm"` block in your `main.tf` file in the following way:

```
backend "azurerm" {
      resource_group_name  = "rg-terraform-state"
      storage_account_name = "tfstate"
      container_name       = "tfstate"
  }
```

### Bicep

Bicep unfortunately does not have the option to build & push a Docker image using Bicep code, as we have done with Terraform.
Therefore, with Bicep, we need to do 2 seperate runs to create the resources in Azure.
First we need to create at least the resource group & container registr so that the docker image can be built and pushed to the registry.
During this first Bicep deployment run we also create the storage account.

Next we need to build and push the docker image manually.
After that we need to create the container instance which will host the MLFlow server.
This can be done both from your local computer as well as in a CI/CD pipeline.

### Local Deployment

You can also deploy the MLFlow server on a own machine in Docker. Therefore you need a database as a backend for MLFlow where it can store its metadata.
You can find the code to run MLFlow in a Docker container in the `local` directory.
