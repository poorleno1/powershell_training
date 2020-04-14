
#==============================================================================================
#                                           PUBLIC IP SETUP
#==============================================================================================

resource "azurerm_public_ip" "lbpip-dc" {
  name                = "${var.prefix}-pip-inbound"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  allocation_method   = "Dynamic"
  domain_name_label   = "pwsh-training-dc"
  sku                 = "Basic"
  tags                = "${var.tags}"
}

output "Public_IP_DC" {
  value = "${azurerm_public_ip.lbpip-dc.ip_address}"
}

#==============================================================================================
#                                           NETWORK INTERFACE SETUP
#==============================================================================================


# create a network interface
resource "azurerm_network_interface" "dcnic" {
  name                = "${var.prefix}dc${count.index}t-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  count               = "${local.dc_virtual_machine_count}"

  ip_configuration {
    name                          = "ipconfiguration${count.index}"
    subnet_id                     = "${azurerm_subnet.network_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.lbpip-dc.id}"
  }

  tags = "${var.tags}"
}



#==============================================================================================
#
#                  VIRTUAL MACHINE CONFIGURATION ON NEW RESOURCE GROUP
#
#==============================================================================================


resource "azurerm_virtual_machine" "dc" {
  name                  = "${local.virtual_machine_name}dc${count.index}t"
  location              = "${azurerm_resource_group.resource_group.location}"
  resource_group_name   = "${azurerm_resource_group.resource_group.name}"
  network_interface_ids = ["${element(azurerm_network_interface.dcnic.*.id, count.index)}"]
  vm_size               = "Standard_B1ms"
  count                 = "${local.dc_virtual_machine_count}"

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
    sku     = "2012-R2-Datacenter"
    version = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}dc${count.index}t-osdisk"
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



resource "azurerm_virtual_machine_extension" "antimalware-dc" {
  name                       = "IaaSAntimalware"
  virtual_machine_id         = "${element(azurerm_virtual_machine.dc.*.id, count.index)}"
  publisher                  = "Microsoft.Azure.Security"
  type                       = "IaaSAntimalware"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = "true"
  count                      = "${local.dc_virtual_machine_count}"

  #Require implicit dependency
  depends_on = ["azurerm_virtual_machine.dc"]

  settings = <<SETTINGS
    {
        "AntimalwareEnabled": true,
        "ReaieimeProtectionEnabled": "true",
        "ScheduledScanSettings": {
            "isEnabled": "false",
            "day": "1",
            "time": "120",
            "scanType": "Quick"
            },
        "Exclusions": {
            "Extensions": "",
            "Paths": "",
            "Processes": ""
            }
    }
SETTINGS

  tags = "${var.tags}"
}


resource "azurerm_virtual_machine_extension" "dsc-dc" {
  name                       = "DSC"
  virtual_machine_id         = "${element(azurerm_virtual_machine.dc.*.id, count.index)}"
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.76"
  auto_upgrade_minor_version = "true"
  count                      = "${local.dc_virtual_machine_count}"

  #Require implicit dependency
  depends_on = [
    "azurerm_automation_account.AutomationAccount",
    "azurerm_virtual_machine.dc"
  ]

  settings           = <<SETTINGS
    {
            "WmfVersion": "latest",
            "ModulesUrl": "https://eus2oaasibizamarketprod1.blob.core.windows.net/automationdscpreview/RegistrationMetaConfigV2.zip",
            "ConfigurationFunction": "RegistrationMetaConfigV2.ps1\\RegistrationMetaConfigV2",
            "Privacy": {
                "DataCollection": ""
            },
            "Properties": {
                "RegistrationKey": {
                  "UserName": "PLACEHOLDER_DONOTUSE",
                  "Password": "PrivateSettingsRef:registrationKeyPrivate"
                },
                "RegistrationUrl": "${azurerm_automation_account.AutomationAccount.dsc_server_endpoint}",
                "NodeConfigurationName": "",
                "ConfigurationMode": "applyAndMonitor",
                "ConfigurationModeFrequencyMins": 15,
                "RefreshFrequencyMins": 30,
                "RebootNodeIfNeeded": false,
                "ActionAfterReboot": "continueConfiguration",
                "AllowModuleOverwrite": false
            }
        }
SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
      "Items": {
        "registrationKeyPrivate" : "${azurerm_automation_account.AutomationAccount.dsc_primary_access_key}"
      }
    }
PROTECTED_SETTINGS
  tags               = "${var.tags}"
}
