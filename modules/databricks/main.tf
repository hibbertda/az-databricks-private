# Deploy Azure  Databricks workspace
#
# This module deploys an Azure Databricks workspace

# azure network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-adb-${var.random}"
  location            = var.resourcegroup.location
  resource_group_name = var.resourcegroup.name
  tags                = var.tags
}

data "azurerm_subnet" "subnets" {
  for_each = {
		for index, subnet in var.subnets:
		subnet.name => subnet
	}
  name                 = each.value.name
  virtual_network_name = var.virtualnetwork.name
  resource_group_name  = var.resourcegroup.name
}

#azure network security group association
resource "azurerm_subnet_network_security_group_association" "nsg" {
  	for_each = {
		for index, subnet in var.subnets:
		subnet.name => subnet
	}
  subnet_id                 = data.azurerm_subnet.subnets[each.value.name].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Azure nat gateway subnet associate
resource "azurerm_subnet_nat_gateway_association" "nat_gateway" {
    for_each = {
		for index, subnet in var.subnets:
		subnet.name => subnet
	}
  subnet_id      = data.azurerm_subnet.subnets[each.value.name].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

# azure public ip
resource "azurerm_public_ip" "nat_gateway_public_ip" {
  name                = "nat-gateway-public-ip-${var.random}"
  location            = var.resourcegroup.location
  resource_group_name = var.resourcegroup.name
  tags                = var.tags

  allocation_method = "Static"
  sku               = "Standard"
}

# azure nat gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "nat-gateway-${var.random}"
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
  #tier                = var.databricks_workspace.sku_tier

  public_network_access_enabled = true
  network_security_group_rules_required = "NoAzureDatabricksRules"

  custom_parameters {
    no_public_ip        = true
    virtual_network_id  = var.virtualnetwork.id
    public_subnet_name  = "public-subnet"
    private_subnet_name = "private-subnet"
    nat_gateway_name    = azurerm_nat_gateway.nat_gateway.name
    #vnet_address_prefix = var.vnet_prefix

    public_subnet_network_security_group_association_id = azurerm_network_security_group.nsg.id
    private_subnet_network_security_group_association_id = azurerm_network_security_group.nsg.id

  }
}



