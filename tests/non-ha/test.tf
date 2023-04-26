
terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
    aviatrix = {
      source = "aviatrixsystems/aviatrix"
    }
  }
}

provider "aviatrix" {}

module "my_gcp_transit" {
  # source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  # version = "2.4.2"
  source = "github.com/MatthewKazmar/terraform-aviatrix-mc-transit"

  cloud               = "gcp"
  name                = "my-gcp-ha-transit"
  region              = "us-central1"
  cidr                = "10.39.0.0/24"
  account             = "GCP"
  ha_gw               = false
  local_as_number     = 64774
  enable_bgp_over_lan = true

  bgp_lan_interfaces = [{
    subnet = "10.40.254.32/28"
  }]
  # ha_bgp_lan_interfaces = [{
  #   subnet = "10.40.254.32/28"
  # }]
}

#The module will determine HA based on the transit gateway object put in.
module "avx_ncc" {
  source = "../.."

  account         = "GCP"
  ncc_hub_name    = "test-hub"
  transit_gateway = module.my_gcp_transit.transit_gateway
  cr_asn          = 64777

  depends_on = [
    module.my_gcp_transit
  ]
}

resource "test_assertions" "ncc" {
  component = "transit_ncc_connection"

  check "asn_match_primary" {
    description = "The GCP and Aviatrix ASNs match where expected"
    condition   = tonumber(module.avx_ncc.external_device_conn.bgp_local_as_num) == module.avx_ncc.gcp_peer["cr-pri-to-avx-pri"].peer_asn
  }

  # check "asn_match_ha" {
  #   description = "The GCP and Aviatrix ASNs match where expected"
  #   condition   = tonumber(module.avx_ncc.external_device_conn.bgp_local_as_num) == module.avx_ncc.gcp_peer["cr-ha-to-avx-ha"].peer_asn
  # }
}

output "test_assertions" {
  value = test_assertions.ncc.check
}