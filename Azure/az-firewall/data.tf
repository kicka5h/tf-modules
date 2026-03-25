data "http" "hosts_blacklist" {
  count = var.fqdn_blocklist_max > 0 ? 1 : 0
  url   = "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts0"
}

data "http" "custom_fqdn_blocklist" {
  url = "https://raw.githubusercontent.com/<org>/blocked-hosts/main/fqdn-blocklist.txt"
}

data "http" "spamhaus_drop" {
  url = "https://www.spamhaus.org/drop/drop.txt"
}

data "http" "spamhaus_edrop" {
  url = "https://www.spamhaus.org/drop/edrop.txt"
}

data "http" "custom_ip_blocklist" {
  url = "https://raw.githubusercontent.com/<org>/blocked-hosts/main/ip-blocklist.txt"
}
