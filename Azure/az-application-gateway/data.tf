data "azurerm_client_config" "current" {}

data "http" "spamhaus_drop" {
  url = "https://www.spamhaus.org/drop/drop.txt"
}

data "http" "spamhaus_edrop" {
  url = "https://www.spamhaus.org/drop/edrop.txt"
}

data "http" "custom_ip_blocklist" {
  url = "https://raw.githubusercontent.com/<org>/blocked-hosts/main/ip-blocklist.txt"
}
