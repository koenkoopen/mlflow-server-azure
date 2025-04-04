variable "resource_group_name" {
  default = "rg-mlflow-terraform"
  type    = string
}

variable "subscription_id" {
  type = string
}

variable "tags" {
  default = {
    "Team"        = "DevOps"
    "Environment" = "Terraform Getting Started"
  }
  type = map(any)
}

variable "location" {
  default = "westeurope"
  type    = string
}
variable "storage_name" {
  default = "storagemlflowterraform"
  type    = string
}

variable "container_registry_name" {
  default = "acrmlflowterraform"
  type    = string
}

variable "file_share_name_mlflow" {
  default = "mlflowshare"
  type    = string
}

variable "blob_container_name_mlflow" {
  default = "mlflowcontainer"
  type    = string
}

variable "container_instance_name" {
  default = "containermlflowterraform"
  type    = string
}
