# Azure Databricks Private Deployment

Example for tfvars to run the deployment to Azure Government

```yaml
tags = {
  owner       = "Daniel Hibbert"
  projectName = "ADB Private Network" 
}

location = "usgovvirginia"

virtualNetwork = {
  address_space = ["10.105.0.0/16"]
}

subnets = [ 
  {
    address_prefix  = ["10.105.1.0/24"]
    name            = "public-subnet"
  },
  {
    address_prefix  = ["10.105.2.0/24"]
    name            = "private-subnet"
  }  
]

existing_network = {
  use_existing_network = false
}

existing_resourceGroup = {
  use_existing_resourceGroup = false
}

databricks_workspace = {
  name = "adb-demo"
  sku_name = "trial"
  sku_tier = "standard"
}

```