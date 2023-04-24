module "my_gcp_transit" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "2.4.2"

  cloud               = "gcp"
  name                = "my-gcp-transit"
  region              = "us-east4"
  cidr                = "10.39.0.0/24"
  account             = "GCP"
  local_as_number     = 64700
  enable_bgp_over_lan = true

  bgp_lan_interfaces = [{
    subnet = "10.40.254.32/28"
  }]
  ha_bgp_lan_interfaces = [{
    subnet = "10.40.254.32/28"
  }]
}

module "avx_ncc" {
  source = "terraform-aviatrix-modules/gcp-ncc/aviatrix"

  account         = "GCP"
  ncc_hub_name    = "avx-mgmt"
  transit_gateway = module.my_gcp_transit.transit_gateway.gw_name
  cr_asn          = 64701
}