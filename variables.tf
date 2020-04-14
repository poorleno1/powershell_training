variable "resource_group" {
  description = "The Azure Resource group"
  default="powershell-training-rg"
}


# variable "resource_group_update_mgmt" {
#   description="This is a resource group where update management is setup"
#   default="eur-infra-dev-rg"
# }

# variable "aa_name" {
#   default = "eur-infra-dev-automation-account"
# }

variable "prefix" {
  description = "The Prefix used for all resources in this example.In case of VM it can be VM Name"
  default="pwsh"
}

#Location where resource will be created
variable "location" {
  description = "The Azure Region in which the resources in this example should exist"
  default="westeurope"
}

# #Name of resource group with virtual network
# variable "network_resource_group" {
#   description = "The Azure Network Resource group"
#   default="eur-infra-net-rg"
# }
# #Name of virtual network
# variable "network_name" {
#   description = "The Azure Netowrk name"
#   default="eur-infra-dev-test-vnet"
# }

#Name of virtual network subnet
variable "network_subnet" {
  description = "The Azure Network subnet"
  default="pwsh_subnet"
}

#Global tags which will be assigned to all resources
variable "tags" {
  type        = "map"
  default = {
      Project = "Powershell training"
      Application = "PWSH"
      Environment="Development"
    }
  description = "Any tags which should be assigned to the resources in this example"
}