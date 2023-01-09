variable "tags" {
  description = "Key value list of Azure resource tags"
  type = map
}

variable "location" {
  type        = string
  description = "The Azure location where all resources in this example should be created."
  default     = "usgovvirginia"
}

variable "existing_resourceGroup" {
  description = "options to use an existing resource group"
  type = object({
    use_existing_resourceGroup  = optional(bool, false)
    resource_group_name         = optional(string)
  })
}

variable "virtualNetwork" {
  description = "Virtual network configuration"
  type = object({
    address_space= optional(list(string)) # List of IPv4 address space(s) to configure on the virtual network 
  })
}

variable "existing_network" {
  description = "Options to use an existing virtual network/subnets"
  type = object({
    use_existing_network          = optional(bool, false)
    vnet_name                     = optional(string)
    vnet_resourceGroup            = optional(string)
    subnet_private_services_name  = optional(string)
    subnet_appService_name        = optional(string)
  })
}

variable "subnets" {
  description = "Subnets"
  type = list(object(
    {
      name                      = optional(string, "prvtsvcs") # Subnet Name
      address_prefix            = optional(list(string))       # Subnet IPv4 prefix
      delegation                = optional(string, null)       # Azure service delegation (optional)
      enable_service_endpoints  = optional(bool, false)        # Enable service endpoints (optional)(bool)
      service_endpoints         = optional(set(string))        # List of service endpoints (optional)
    }
  ))
}

variable "databricks_workspace" {
  description = "Azure Databricks workspace configuration"
  type = object({
    name      = string
    sku_name  = optional(string, "standard")
    sku_tier  = optional(string, "standard")
  })
}