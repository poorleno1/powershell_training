resource "azurerm_automation_account" "AutomationAccount" {
  name                = "${local.virtual_machine_name}automationacc"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  sku_name            = "Basic"
}

# resource "azurerm_automation_dsc_configuration" "dc_dsc" {
#   name                    = "${local.virtual_machine_name}dcdsc"
#   location                = "${azurerm_resource_group.resource_group.location}"
#   resource_group_name     = "${azurerm_resource_group.resource_group.name}"
#   automation_account_name = "${local.virtual_machine_name}automationacc"
#   content_embedded        = "configuration test {}"
# }

# resource "azurerm_automation_dsc_nodeconfiguration" "dc-node-dsc" {
#   name                    = "test.localhost"
#   resource_group_name     = "${azurerm_resource_group.resource_group.name}"
#   automation_account_name = "${local.virtual_machine_name}automationacc"
#   depends_on              = [azurerm_automation_dsc_configuration.dc_dsc]

#   content_embedded = <<mofcontent
# instance of MSFT_FileDirectoryConfiguration as $MSFT_FileDirectoryConfiguration1ref
# {
#   ResourceID = "[File]bla";
#   Ensure = "Present";
#   Contents = "bogus Content";
#   DestinationPath = "c:\\bogus.txt";
#   ModuleName = "PSDesiredStateConfiguration";
#   SourceInfo = "::3::9::file";
#   ModuleVersion = "1.0";
#   ConfigurationName = "bla";
# };
# instance of OMI_ConfigurationDocument
# {
#   Version="2.0.0";
#   MinimumCompatibleVersion = "1.0.0";
#   CompatibleVersionAdditionalProperties= {"Omi_BaseResource:ConfigurationName"};
#   Author="bogusAuthor";
#   GenerationDate="06/15/2018 14:06:24";
#   GenerationHost="bogusComputer";
#   Name="test";
# };
# mofcontent

# }
