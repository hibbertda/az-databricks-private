
# Create Virtual Network (VNET)
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtualnetwork.name
  location            = var.resourcegroup.location
  resource_group_name = var.resourcegroup.name
  address_space       = var.virtualnetwork["address_space"]
  tags                = var.tags
}

/*
Loop through all of the subnets defined in the 'subnets' variable. 
*/
resource "azurerm_subnet" "subnets" {
  depends_on = [
      azurerm_virtual_network.vnet
    ]
	for_each = {
		for index, subnet in var.subnets:
		subnet.name => subnet
	}
  name                  = each.value.name
  resource_group_name   = var.resourcegroup.name
  virtual_network_name  = azurerm_virtual_network.vnet.name
  address_prefixes      = each.value.address_prefix 

  private_endpoint_network_policies_enabled     = false
  private_link_service_network_policies_enabled = false

  /*
  Service endpoints will be added to the subnet configuration when the 'enable_service_endpoint'
  variable in Subnets is set to 'TRUE'. The 'service_endpoints' variable will contain a set of service
  endpoint names that will be added. If enable_service_endpoints is set to 'FALSE' no service endpoints
  are added.
  */
  service_endpoints = each.value.enable_service_endpoints == true ? flatten(each.value.service_endpoints): null

  /*
  If a subnet delegation is needed use the 'delegation' variable. If this variable has a value it will
  be configured on the subnet. If there is no delegation nothing will be configured on the subnet. 
  */
  dynamic "delegation" {
    for_each = toset(each.value.delegation != null ? ["fake"] : [])
    content {
      name = "databricks-${each.value.name}"
      service_delegation {
        name = "Microsoft.Databricks/workspaces"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
          "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
        ]         
      }  
    }
  }
}