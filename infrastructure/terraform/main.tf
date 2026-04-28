provider "azurerm" {
  features {}
}

provider "aws" {
  region = var.aws_region
}

resource "azurerm_resource_group" "factory" {
  name     = "rg-${var.project_name}-factory-${var.environment}"
  location = var.location
}

# --- Migration Foundation Control Plane (AKS) ---

resource "azurerm_kubernetes_cluster" "migration_k8s" {
  name                = "aks-mig-factory-${var.environment}"
  location            = azurerm_resource_group.factory.location
  resource_group_name = azurerm_resource_group.factory.name
  dns_prefix          = "mig-k8s"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D4s_v3" # Larger nodes for data processing
  }

  identity {
    type = "SystemAssigned"
  }
}

# --- Multi-Cloud Ingestion Storage (Azure Blob + AWS S3) ---

resource "azurerm_storage_account" "migration_stage" {
  name                     = "stmigstage${var.environment}"
  resource_group_name      = azurerm_resource_group.factory.name
  location                 = azurerm_resource_group.factory.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "aws_s3_bucket" "migration_stage_aws" {
  bucket = "mig-factory-stage-${var.environment}"
}

# --- Migration Metadata Store (Postgres) ---

resource "azurerm_postgresql_flexible_server" "metadata" {
  name                   = "psql-mig-metadata-${var.environment}"
  resource_group_name    = azurerm_resource_group.factory.name
  location               = azurerm_resource_group.factory.location
  version                = "13"
  administrator_login    = "migadmin"
  administrator_password = var.db_password
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2ds_v4"
}
