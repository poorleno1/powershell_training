
variable SUBSCRIPTION_ID {}
variable ADMIN_USERNAME {}
variable ADMIN_PASSWORD {}
variable ACTIVE_DIRECTORY_USERNAME {}
variable ACTIVE_DIRECTORY_PASSWORD {}

#Local values
locals {
  virtual_machine_name = "${var.prefix}"
  subscription_id       = "${var.SUBSCRIPTION_ID}"
  admin_username       = "${var.ADMIN_USERNAME}"
  admin_password       = "${var.ADMIN_PASSWORD}"
  active_directory_username = "${var.ACTIVE_DIRECTORY_USERNAME}"
  active_directory_password = "${var.ACTIVE_DIRECTORY_PASSWORD}"
  dc_virtual_machine_count = 1
  training_virtual_machine_count = 5
  
}

#For Windows machines
#locals {
  #custom_data_params  = "Param($ComputerName = \"${local.virtual_machine_name}\")"
  #custom_data_content = "${local.custom_data_params} ${file("./files/winrm.ps1")}"
#}

#==============================================================================================
#
#                      AZURE PROVIDER AND SUBSCRIPTION DEFINITION
#
#==============================================================================================

provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  #version = "=1.29.0"
  subscription_id = "${local.subscription_id}"
}
data "azurerm_subscription" "current" {}
output "current_subscription_display_name" {
  value = "${data.azurerm_subscription.current.display_name}"
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group}"
  location = "${var.location}"
  tags     = "${var.tags}"
}

#==============================================================================================
#                                           STORAGE ACCOUNT SETUP
#==============================================================================================

resource "azurerm_storage_account" "diagnosticstorageaccount" {
    name                = "${var.prefix}diagacc"
    resource_group_name = "${azurerm_resource_group.resource_group.name}"
    location            = "${var.location}"
    account_replication_type = "LRS"
    account_tier = "Standard"
    account_kind = "StorageV2"
    
    
    network_rules {
    ip_rules                   = ["127.0.0.1","185.192.235.0/24","185.192.232.0/24"]
    virtual_network_subnet_ids = ["${azurerm_subnet.network_subnet.id}"]
    default_action= "Deny"
  }
    
    tags = "${var.tags}"
}

#==============================================================================================
#                                           NETWORK SETUP
#==============================================================================================


resource "azurerm_virtual_network" "test" {
  name                = "production"
  address_space       = [ "10.0.0.0/8" ] 
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
}

output "virtual_network_id" {
  value = "${azurerm_virtual_network.test.name}"
}


resource "azurerm_subnet" "network_subnet" {
  name                 = "${var.network_subnet}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  resource_group_name  = "${azurerm_resource_group.resource_group.name}"
  address_prefix       = "10.0.1.0/24"
  service_endpoints    = ["Microsoft.KeyVault","Microsoft.Storage","Microsoft.EventHub"]
}
output "subnet_name" {
  value = "${azurerm_subnet.network_subnet.name}"
}


#==============================================================================================
#                                           LOAD BALANCER SETUP
#==============================================================================================

# resource "azurerm_public_ip" "lbpip-publicIP" {
#   name                         = "${var.prefix}-pip-inbound"
#   location                     = "${var.location}"
#   resource_group_name          = "${azurerm_resource_group.resource_group.name}"
#   allocation_method            = "Dynamic"
#   domain_name_label            = "pwsh-training"
#   sku                          = "Basic"

#   tags = "${var.tags}"
# }

# output "External_LB_IP" {
#   value = "${azurerm_public_ip.lbpip-publicIP.ip_address}"
# }

# resource "azurerm_lb" "lb-ext" {
#   resource_group_name = "${azurerm_resource_group.resource_group.name}"
#   name                = "${var.prefix}-lbint"
#   location            = "${var.location}"
#   sku                 = "Basic"

#   frontend_ip_configuration {
#     name                 = "LoadBalancerFrontEndIP"
#     #subnet_id            = "${azurerm_subnet.network_subnet.id}"
#     public_ip_address_id = "${azurerm_public_ip.lbpip-publicIP.id}"
#   }

#   tags = "${var.tags}"
# }


# resource "azurerm_lb_backend_address_pool" "backend_pool_int_dc" {
#   resource_group_name = "${azurerm_resource_group.resource_group.name}"
#   loadbalancer_id     = "${azurerm_lb.lb-ext.id}"
#   name                = "backend-pool-dc"
# }



# resource "azurerm_lb_rule" "lb_rule-ext-1000-tcp" {
#   resource_group_name            = "${azurerm_resource_group.resource_group.name}"
#   loadbalancer_id                = "${azurerm_lb.lb-ext.id}"
#   name                           = "LBRule-ext-1000-tcp"
#   protocol                       = "tcp"
#   frontend_port                  = 1000
#   backend_port                   = 3389
#   frontend_ip_configuration_name = "LoadBalancerFrontEndIP"
#   enable_floating_ip             = false
#   backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool_int_dc.id}"
#   idle_timeout_in_minutes        = 5
#   probe_id                       = "${azurerm_lb_probe.lb_probe-ext-3389-tcp.id}"
#   depends_on                     = ["azurerm_lb_probe.lb_probe-ext-3389-tcp"]
#   load_distribution              = "SourceIP"
#   disable_outbound_snat          = true
  
# }


# resource "azurerm_lb_probe" "lb_probe-ext-3389-tcp" {
#   resource_group_name = "${azurerm_resource_group.resource_group.name}"
#   loadbalancer_id     = "${azurerm_lb.lb-ext.id}"
#   name                = "tcpProbe-3389-tcp"
#   protocol            = "tcp"
#   port                = 3389
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }


# resource "azurerm_network_interface_backend_address_pool_association" "ext-dc" {
#   network_interface_id    = "${element(azurerm_network_interface.vmnic.*.id,count.index)}"
#   ip_configuration_name   = "ipconfiguration${count.index}"
#   backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool_int_dc.id}"
#   count = "${local.dc_virtual_machine_count}"
# }
