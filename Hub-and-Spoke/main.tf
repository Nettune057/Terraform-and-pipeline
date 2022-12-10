resource "azurerm_resource_group" "rg" {
  name     = "HubandSpoke"
  location = "EastAsia"
}
resource "azurerm_virtual_network" "VnetHub" {
  name                = "Hub"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "hubsubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VnetHub.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_subnet" "GWsub" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VnetHub.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_virtual_network" "VnetSpoke1" {
  name                = "Spoke1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.1.0.0/16"]
}
resource "azurerm_subnet" "default1" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VnetSpoke1.name
  address_prefixes     = ["10.1.0.0/24"]
}
resource "azurerm_virtual_network" "VnetSpoke2" {
  name                = "Spoke2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.2.0.0/16"]
}
resource "azurerm_subnet" "default2" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VnetSpoke2.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_public_ip" "PIP" {
  name                = "PIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
resource "azurerm_public_ip" "Firewallpip" {
  name                = "testpip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_virtual_network_gateway" "Gw" {
  name                = "Hub-Gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.PIP.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.GWsub.id
  }

  vpn_client_configuration {
    address_space = ["10.3.0.0/24"]

    root_certificate {
      name = "RootCert"

      public_cert_data = <<EOF
MIIC5zCCAc+gAwIBAgIQOiFPxUhpHa9C2UuEAxDOxzANBgkqhkiG9w0BAQsFADAW
MRQwEgYDVQQDDAtQMlNSb290Q2VydDAeFw0yMjExMjgxNDQyNDdaFw0yMzExMjgx
NTAyNDdaMBYxFDASBgNVBAMMC1AyU1Jvb3RDZXJ0MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEAzdFpE8131+7a7EQRTQ/kywY26YVjU9ViUu2xjNEBrMn8
QruVfZXqyh2pnf/vmjNP0ZmYoR+TjKwWJhcSOdDvTYqxudcMfIqLBaFjYARYN2GH
yYQ8zCU4ttTrC/VYLYG5vqqtocK3PolcduDmU5jXe+HL8JQCaUckQwLgruHa3BeV
RCp3ltH53W6B7LAuYd2ZrZgcGQpFX7mDnaUiIzXVnjVf1VWNUE/wyRIdTwYH0mZJ
PPPorO0OPj0Ij1MKlyimnuXew35uw9jovyaKod7m28RQlJ0AwjegqrceXV0hVFbB
dJaoDj0lZcyzLcrmFnscWvH8AdOZrdPbX3Y0NzUGsQIDAQABozEwLzAOBgNVHQ8B
Af8EBAMCAgQwHQYDVR0OBBYEFDbqRMuVjbziLQgJBFmHkGNOPWaFMA0GCSqGSIb3
DQEBCwUAA4IBAQBc8aNCIpV6VC8r5ipwuVEzZwYP9vREnGg+cf1c/jvuHF8ueakj
wJk1lHTRbCLD4HWHGWPaLfcw2I+4mp59jQ7i9eifKSwtV7VQYauwuWqntikPJ0If
nqv/HeSE/4mmN12r6G4LJjXGshCEIg4SwDgVWSoFLpIwHgEhdlQckDDTaUdyqdhg
Y4aB8NEpak8lj1KXEuzN5/aYeUgD+cZ8Qbm4I9uX40wveAco3r5T+2JrLrCisbcv
la4kJWrJnwvGNWJJWtn6X0ApyXq0h3r2gqbBf23F8jjgEaZt66tztr1oVrnFmRG7
KIwioeCIfPV+6maZ64HNZad/NQvSfjnaBsUN
EOF

    }
  }
}

module "Hub-Spoke1" {
  depends_on           = [azurerm_virtual_network_gateway.Gw]
  source               = "aztfm/virtual-network-peering/azurerm"
  version              = ">=1.0.0"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VnetHub.name
  peerings = [
    { 
      name                      = azurerm_virtual_network.VnetSpoke1.name
      remote_virtual_network_id = azurerm_virtual_network.VnetSpoke1.id
      allow_gateway_transit     = true
    },
    {
      name                      = azurerm_virtual_network.VnetSpoke2.name
      remote_virtual_network_id = azurerm_virtual_network.VnetSpoke2.id
      allow_gateway_transit     = true
    }
  ]
}

module "Spoke1-Hub" {
  source               = "aztfm/virtual-network-peering/azurerm"
  version              = ">=1.0.0"
  resource_group_name  = azurerm_virtual_network.VnetSpoke1.resource_group_name
  virtual_network_name = azurerm_virtual_network.VnetSpoke1.name
  peerings = [
    {
      name                      = module.Hub-Spoke1.peerings[azurerm_virtual_network.VnetSpoke1.name].virtual_network_name
      remote_virtual_network_id = azurerm_virtual_network.VnetHub.id
      use_remote_gateways       = true
    }
  ]
}
module "Spoke2-Hub" {
  source               = "aztfm/virtual-network-peering/azurerm"
  version              = ">=1.0.0"
  resource_group_name  = azurerm_virtual_network.VnetSpoke2.resource_group_name
  virtual_network_name = azurerm_virtual_network.VnetSpoke2.name
  peerings = [
    {
      name                      = module.Hub-Spoke1.peerings[azurerm_virtual_network.VnetSpoke2.name].virtual_network_name
      remote_virtual_network_id = azurerm_virtual_network.VnetHub.id
      use_remote_gateways       = true
    }
  ]
}

resource "azurerm_firewall" "Firewall" {
  name                = "Hub-Firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hubsubnet.id
    public_ip_address_id = azurerm_public_ip.Firewallpip.id
  }
}

resource "azurerm_firewall_network_rule_collection" "netrule" {
  name                = "Allow"
  azure_firewall_name = azurerm_firewall.Firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "AllowAll"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "22",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "TCP",
      "UDP",
      "ICMP",
    ]
  }
}

resource "azurerm_route_table" "RT" {
  name                = "HubRT"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "Hub-Gw"
    address_prefix         = "10.1.0.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }
  route {
    name                   = "Hub-Gw2"
    address_prefix         = "10.2.0.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }
}

resource "azurerm_subnet_route_table_association" "RTAssociate" {
  subnet_id      = azurerm_subnet.GWsub.id
  route_table_id = azurerm_route_table.RT.id
}

resource "azurerm_route_table" "Sp1RT" {
  name                = "Spoke1RT"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = true
  route {
    name                   = "Spoke1-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }
}

resource "azurerm_subnet_route_table_association" "RTAssociate1" {
  subnet_id      = azurerm_subnet.default1.id
  route_table_id = azurerm_route_table.Sp1RT.id
}

resource "azurerm_route_table" "Sp2RT" {
  name                = "Spoke2RT"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = true
  route {
    name                   = "Spoke2-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }
}

resource "azurerm_subnet_route_table_association" "RTAssociate2" {
  subnet_id      = azurerm_subnet.default2.id
  route_table_id = azurerm_route_table.Sp2RT.id
}

resource "azurerm_network_interface" "NIC1" {
  name                = "Spoke1-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "configuration1"
    subnet_id                     = azurerm_subnet.default1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "NIC2" {
  name                = "Spoke2-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "configuration2"
    subnet_id                     = azurerm_subnet.default2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "associate1" {
  network_interface_id      = azurerm_network_interface.NIC1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "associate2" {
  network_interface_id      = azurerm_network_interface.NIC2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_virtual_machine" "main1" {
  name                  = "VM-Spoke1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.NIC1.id]
  vm_size               = "Standard_B1ls"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "azure"
    admin_username = "azure"
    admin_password = "Azureuser_123"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_virtual_machine" "main2" {
  name                  = "VM-Spoke2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.NIC2.id]
  vm_size               = "Standard_B1ls"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "azure1"
    admin_username = "azure"
    admin_password = "Azureuser_123"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}