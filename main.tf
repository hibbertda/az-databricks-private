resource "random_string" "random" {
  length = 8
  special = false
  lower = true
  upper = false
}

# Create Resource Group (optional)
resource "azurerm_resource_group" "core" {
  count       = var.existing_resourceGroup.use_existing_resourceGroup == false ? 1 : 0
	name        = "rg-adb-${var.location}-${random_string.random.result}"
	location    = var.location
  tags        = var.tags 
}

# Data for existing resource group (Optional)
data "azurerm_resource_group" "core" {
  count       = var.existing_resourceGroup.use_existing_resourceGroup == true ? 1 : 0
  name        = var.existing_resourceGroup.resource_group_name
}

module "network" {
  source          = "./modules/network"
  count           = var.existing_network.use_existing_network  == false ? 1 : 0
  resourcegroup   = azurerm_resource_group.core[0]
  tags            = var.tags
  random          = random_string.random.result
  virtualnetwork  = var.virtualNetwork
  subnets         = var.subnets
}

module "databricks" {
  source                = "./modules/databricks"
  depends_on = [
    module.network
  ]
  resourcegroup         = azurerm_resource_group.core[0]
  databricks_workspace  = var.databricks_workspace
  tags                  = var.tags
  resource_names        = var.resource_names
  random                = random_string.random.result
  virtualnetwork        = module.network[0].vnet
  vnet_prefix           = var.virtualNetwork.address_space[0]
  subnets               = module.network[0].subnets
  nsg_name              = var.virtualNetwork.nsg_name
}
