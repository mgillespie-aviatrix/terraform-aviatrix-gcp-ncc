data "aviatrix_account" "this" {
  account_name = var.account
}

# data "aviatrix_transit_gateway" "this" {
#   gw_name = var.transit_gateway_name
# }

data "google_compute_instance" "gateways" {
  for_each = local.avx_peers

  project = data.aviatrix_account.this.gcloud_project_id
  name    = each.value["name"]
  zone    = each.value["zone"]
}

data "google_compute_subnetwork" "bgp" {
  project   = data.aviatrix_account.this.gcloud_project_id
  self_link = one([for v in data.google_compute_instance.gateways["pri"].network_interface : v.subnetwork if v.network_ip == local.avx_peers["pri"]["ip"]])
}