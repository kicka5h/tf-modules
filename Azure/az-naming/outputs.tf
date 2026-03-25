output "base_name" {
  description = "Base name without resource-type prefix, for building custom names"
  value       = local.base_name
}

output "base_name_nosep" {
  description = "Base name with no separators, for resources that disallow special characters"
  value       = local.base_name_nosep
}

output "resource_group" {
  description = "Name for an Azure Resource Group"
  value       = local.all_names["resource_group"]
}

output "virtual_network" {
  description = "Name for an Azure Virtual Network"
  value       = local.all_names["virtual_network"]
}

output "subnet" {
  description = "Name for an Azure Subnet"
  value       = local.all_names["subnet"]
}

output "network_security_group" {
  description = "Name for an Azure Network Security Group"
  value       = local.all_names["network_security_group"]
}

output "route_table" {
  description = "Name for an Azure Route Table"
  value       = local.all_names["route_table"]
}

output "public_ip" {
  description = "Name for an Azure Public IP"
  value       = local.all_names["public_ip"]
}

output "nat_gateway" {
  description = "Name for an Azure NAT Gateway"
  value       = local.all_names["nat_gateway"]
}

output "firewall" {
  description = "Name for an Azure Firewall"
  value       = local.all_names["firewall"]
}

output "firewall_policy" {
  description = "Name for an Azure Firewall Policy"
  value       = local.all_names["firewall_policy"]
}

output "application_gateway" {
  description = "Name for an Azure Application Gateway"
  value       = local.all_names["application_gateway"]
}

output "load_balancer" {
  description = "Name for an Azure Load Balancer"
  value       = local.all_names["load_balancer"]
}

output "private_endpoint" {
  description = "Name for an Azure Private Endpoint"
  value       = local.all_names["private_endpoint"]
}

output "front_door" {
  description = "Name for an Azure Front Door"
  value       = local.all_names["front_door"]
}

output "vpn_gateway" {
  description = "Name for an Azure VPN Gateway"
  value       = local.all_names["vpn_gateway"]
}

output "express_route" {
  description = "Name for an Azure ExpressRoute Circuit"
  value       = local.all_names["express_route"]
}

output "virtual_machine" {
  description = "Name for an Azure Virtual Machine"
  value       = local.all_names["virtual_machine"]
}

output "vmss" {
  description = "Name for an Azure Virtual Machine Scale Set"
  value       = local.all_names["vmss"]
}

output "aks_cluster" {
  description = "Name for an Azure Kubernetes Service cluster"
  value       = local.all_names["aks_cluster"]
}

output "container_instance" {
  description = "Name for an Azure Container Instance"
  value       = local.all_names["container_instance"]
}

output "container_registry" {
  description = "Name for an Azure Container Registry (no hyphens, max 50 chars)"
  value       = local.all_names["container_registry"]
}

output "storage_account" {
  description = "Name for an Azure Storage Account (no hyphens, max 24 chars)"
  value       = local.all_names["storage_account"]
}

output "key_vault" {
  description = "Name for an Azure Key Vault (max 24 chars)"
  value       = local.all_names["key_vault"]
}

output "app_service_plan" {
  description = "Name for an Azure App Service Plan"
  value       = local.all_names["app_service_plan"]
}

output "app_service" {
  description = "Name for an Azure App Service"
  value       = local.all_names["app_service"]
}

output "dns_zone" {
  description = "Name for an Azure DNS Zone (base name only, no prefix)"
  value       = local.all_names["dns_zone"]
}

output "log_analytics" {
  description = "Name for an Azure Log Analytics Workspace"
  value       = local.all_names["log_analytics"]
}

output "names" {
  description = "Map of all resource type names (resource_type => generated name)"
  value       = local.all_names
}
