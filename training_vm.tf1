
#==============================================================================================
#                                           PUBLIC IP SETUP
#==============================================================================================

resource "azurerm_public_ip" "lbpip-vm" {
  name                         = "${var.prefix}vm${count.index}-pip-inbound"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resource_group.name}"
  allocation_method            = "Dynamic"
  domain_name_label            = "pwsh-training-vm${count.index}"
  sku                          = "Basic"
  tags                         = "${var.tags}"
  count                        = "${local.training_virtual_machine_count}"
}


#==============================================================================================
#                                           NETWORK INTERFACE SETUP
#==============================================================================================


# create a network interface
resource "azurerm_network_interface" "vmnic" {
  name                = "${var.prefix}vm${count.index}t-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  count               = "${local.training_virtual_machine_count}"

  ip_configuration {
    name                          = "ipconfiguration${count.index}"
    subnet_id                     = "${azurerm_subnet.network_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.lbpip-vm.*.id,count.index)}"
  }
  
  tags = "${var.tags}"
}



#==============================================================================================
#
#                  VIRTUAL MACHINE CONFIGURATION ON NEW RESOURCE GROUP
#
#==============================================================================================


resource "azurerm_virtual_machine" "vm" {
  name                  = "${local.virtual_machine_name}vm${count.index}t"
  location              = "${azurerm_resource_group.resource_group.location}"
  resource_group_name   = "${azurerm_resource_group.resource_group.name}"
  network_interface_ids = ["${element(azurerm_network_interface.vmnic.*.id, count.index)}"]
  vm_size               = "Standard_B1ms"
  count                 = "${local.training_virtual_machine_count}"
  
  # This means the OS Disk will be deleted when Terraform destroys the Virtual Machine
  # NOTE: This may not be optimal in all cases.
  delete_os_disk_on_termination = true

  # This means the Data Disk Disk will be deleted when Terraform destroys the Virtual Machine
  # NOTE: This may not be optimal in all cases.
  delete_data_disks_on_termination = true

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        #sku       = "2016-Datacenter-Server-Core"
        sku       = "2012-R2-Datacenter"
        version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}vm${count.index}t-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  #Add data disk if required
#   storage_data_disk {
#     name              = "${var.prefix}${count.index}t-datadisk"
#     caching           = "None"
#     disk_size_gb      = 128
#     create_option     = "Empty"
#     lun               = 1
#     managed_disk_type = "Premium_LRS"
#   }

  #Add data disk if required
  
  os_profile {
    computer_name  = "${local.virtual_machine_name}dc${count.index}t"
    admin_username = "${local.admin_username}"
    admin_password = "${local.admin_password}"
    #custom_data    = "${local.custom_data_content}"
  }

 os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

 boot_diagnostics {
        enabled     = "false"
        storage_uri = "${azurerm_storage_account.diagnosticstorageaccount.primary_blob_endpoint}"
 }
tags = "${var.tags}"

}