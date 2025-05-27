resource "azurerm_resource_group" "main" {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.primary_location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.application_name}-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.base_address_space]
}

/*cidrsubnet takes 3 argments
argument 1: the base_address space that we want to dice up which here is the address space of the vnet
argument 2:assuming base adress space is /22 as is in this case , and we want to use /24 for the subnets then the value is 2 because we are going 2 decimals upwards. 
argument 3: The index. As we know /24 gives you 256 addresses and 256 * 4 gives you 1024 addresses which equals /22. So /24 will effectively split the address space into 4 segments of indexes 0,1,2,3
*/
locals {
  main1_addr_space = cidrsubnet(var.base_address_space, 2, 0)
  main2_addr_space = cidrsubnet(var.base_address_space, 2, 1)
  main3_addr_space = cidrsubnet(var.base_address_space, 2, 2)
  main4_addr_space = cidrsubnet(var.base_address_space, 2, 3)
}
#  10.37.0.0/24
resource "azurerm_subnet" "main1" {
  name                 = "snet-${var.application_name}-${var.environment_name}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.main1_addr_space]
}
#  10.37.1.0/24
resource "azurerm_subnet" "main2" {
  name                 = "snet-${var.application_name}-${var.environment_name}-1"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.main2_addr_space]
}
#  10.37.2.0/24
resource "azurerm_subnet" "main3" {
  name                 = "snet-${var.application_name}-${var.environment_name}-2"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.main3_addr_space]
}
#  10.37.3.0/24
resource "azurerm_subnet" "main4" {
  name                 = "snet-${var.application_name}-${var.environment_name}-3"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.main4_addr_space]
}


resource "azurerm_network_security_group" "remote_access" {
  name                = "nsg-${var.application_name}-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                   = "ssh"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "22"
    #source_address_prefix      = chomp(data.http.my_pub_ip.body)
    source_address_prefix      = "81.106.32.169"
    destination_address_prefix = "*"
  }
}

#link NSG with subnet
resource "azurerm_subnet_network_security_group_association" "nsg_asscociate_main1" {
  subnet_id                 = azurerm_subnet.main1.id
  network_security_group_id = azurerm_network_security_group.remote_access.id
}


#if we don't want to hardcode our public IP so we use the  data resource http below. 
#but since my plan now runs in HCP the public IP will be that of HCP infrastructure and not my local pc.
#so switch to using static iP
data "http" "my_pub_ip" {
  url = "https://ifconfig.me/ip"
}

resource "azurerm_network_interface" "main" {
  count               = 2
  name                = "nic-${var.application_name}-${var.environment_name}-${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "oravm-${count.index + 1}"
    subnet_id                     = azurerm_subnet.main1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main[count.index].id
  }
}
resource "azurerm_public_ip" "main" {
  count               = 2
  name                = "pip-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    environment = "dev"
  }
}
resource "azurerm_virtual_machine" "main" {
  count                 = 2
  name                  = "vm-${var.application_name}-${count.index + 1}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  vm_size               = "Standard_D2s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "oracle"
    offer     = "oracle-database"
    sku       = "oracle_db_12_2_0_1_ee"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 64
  }
  # Add your data disk
  storage_data_disk {
    name              = "datadisk-${count.index + 1}"
    lun               = 0
    disk_size_gb      = 128
    caching           = "None"
    create_option     = "Empty"
    managed_disk_type = "StandardSSD_LRS"
  }
  os_profile {
    computer_name  = "dev-${count.index + 1}"
    admin_username = "azureuser"
    #admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    # Add the SSH key block
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys" # Default path for azureuser
      key_data = file("jenkins_ansible_key.pub")        # <--- Path to your PUBLIC SSH key file
    }
  }
  tags = {
    environment = "dev"
  }
}
