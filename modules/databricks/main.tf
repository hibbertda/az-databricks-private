# Deploy Azure  Databricks workspace
# This module deploys an Azure Databricks workspace

# azure network security group
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.resourcegroup.location
  resource_group_name = var.resourcegroup.name
  tags                = var.tags
}

#azure network security group association
resource "azurerm_subnet_network_security_group_association" "nsg" {
  	for_each = {
		for index, subnet in var.subnets:
		subnet.name => subnet
	}
  subnet_id                 = var.subnets[each.value.name].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Azure nat gateway subnet associate
resource "azurerm_subnet_nat_gateway_association" "nat_gateway" {
    for_each = {
		for index, subnet in var.subnets:
		subnet.name => subnet
	}
  subnet_id      = var.subnets[each.value.name].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

# azure public ip for nat gateway
resource "azurerm_public_ip" "nat_gateway_public_ip" {
  name                = "pip-${var.resource_names.nat_gateway_name}-${var.random}"
  location            = var.resourcegroup.location
  resource_group_name = var.resourcegroup.name
  tags                = var.tags

  allocation_method = "Static"
  sku               = "Standard"
}

# azure nat gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "${var.resource_names.nat_gateway_name}-${var.random}"
  location            = var.resourcegroup.location
  resource_group_name = var.resourcegroup.name
  tags                = var.tags

  sku_name = "Standard"
}

# azure nat gateway ip association
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_public_ip_association" {
  nat_gateway_id        = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id  = azurerm_public_ip.nat_gateway_public_ip.id
}

resource "azurerm_databricks_workspace" "adb_workspace" {
  name                = var.databricks_workspace.name
  resource_group_name = var.resourcegroup.name
  location            = var.resourcegroup.location
  tags                = var.tags

  sku                 = var.databricks_workspace.sku_name
  public_network_access_enabled = false
  network_security_group_rules_required = "NoAzureDatabricksRules"
  managed_resource_group_name = "${var.databricks_workspace.managed_resource_group_name}-${var.random}"

  custom_parameters {
    no_public_ip        = true
    virtual_network_id  = var.virtualnetwork.id
    public_subnet_name  = "public-subnet"
    private_subnet_name = "private-subnet"
    nat_gateway_name    = azurerm_nat_gateway.nat_gateway.name

    public_subnet_network_security_group_association_id   = azurerm_network_security_group.nsg.id
    private_subnet_network_security_group_association_id  = azurerm_network_security_group.nsg.id
  }
}

resource "azurerm_private_endpoint" "adb" {
  name = "pe-${var.databricks_workspace.name}-${var.random}"
  resource_group_name = var.resourcegroup.name
  location            = var.resourcegroup.location
  subnet_id           = var.subnets["private-endpoint"].id

  custom_network_interface_name = "nic-pe-${var.databricks_workspace.name}-${var.random}"

  private_service_connection {
    name                           = "adb-private-service-connection"
    private_connection_resource_id = azurerm_databricks_workspace.adb_workspace.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }  
}

