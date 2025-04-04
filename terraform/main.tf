resource "azurerm_resource_group" "default" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create a storage account
resource "azurerm_storage_account" "default" {
  name                     = var.storage_name
  resource_group_name      = azurerm_resource_group.default.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = var.tags
}

# Create a container registry
resource "azurerm_container_registry" "default" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.default.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
  tags                = var.tags
}

resource "random_id" "always_trigger" {
  byte_length = 8
}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = <<-EOT
    docker build --platform linux/amd64 -f mlflow-tracking-docker/Dockerfile -t ${azurerm_container_registry.default.name}.azurecr.io/mlflowserver-azure .
    az acr login -n ${azurerm_container_registry.default.name}.azurecr.io/mlflowserver-azure --resource-group ${azurerm_resource_group.default.name}
    docker push ${azurerm_container_registry.default.name}.azurecr.io/mlflowserver-azure
  EOT
  }

  triggers = {
    always_trigger = random_id.always_trigger.hex
  }

  depends_on = [azurerm_container_registry.default]
}

resource "azurerm_storage_share" "default" {
  name               = var.file_share_name_mlflow
  storage_account_id = azurerm_storage_account.default.id
  quota              = 5000
  depends_on         = [azurerm_storage_account.default]
}

resource "azurerm_storage_container" "default" {
  name                  = var.blob_container_name_mlflow
  storage_account_id    = azurerm_storage_account.default.id
  container_access_type = "private"
}

resource "azurerm_container_group" "default" {
  name                = var.container_instance_name
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  ip_address_type     = "Public"
  dns_name_label      = "azure-mlflow-dns"
  os_type             = "Linux"
  image_registry_credential {
    username = azurerm_container_registry.default.admin_username
    password = azurerm_container_registry.default.admin_password
    server   = "${azurerm_container_registry.default.name}.azurecr.io"
  }
  container {
    name   = var.container_instance_name
    image  = "${azurerm_container_registry.default.name}.azurecr.io/mlflowserver-azure:latest"
    cpu    = "1"
    memory = "2"
    volume {
      name                 = azurerm_storage_account.default.name
      mount_path           = "/mnt/azfiles"
      storage_account_key  = azurerm_storage_account.default.primary_access_key
      storage_account_name = azurerm_storage_account.default.name
      share_name           = "mlflowshare"
    }
    environment_variables = {
      "MLFLOW_SERVER_FILE_STORE"            = "/mnt/azfiles/mlruns"
      "MLFLOW_SERVER_HOST"                  = "0.0.0.0"
      "MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT" = "wasbs://${azurerm_storage_container.default.name}@${azurerm_storage_account.default.name}.blob.core.windows.net/mlartefacts"
    }
    secure_environment_variables = {
      "AZURE_STORAGE_ACCESS_KEY"        = azurerm_storage_account.default.primary_access_key
      "AZURE_STORAGE_CONNECTION_STRING" = azurerm_storage_account.default.primary_connection_string
    }
    ports {
      port     = 5000
      protocol = "TCP"
    }
  }

  tags       = var.tags
  depends_on = [null_resource.docker_push]
}
