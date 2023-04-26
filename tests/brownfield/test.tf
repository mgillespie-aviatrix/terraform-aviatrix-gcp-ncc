
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

data "aviatrix_transit_gateway" "my_gcp_transit" {
  gw_name = "my-gcp-ha-transit"
}

#The module will determine HA based on the transit gateway object put in.
module "avx_ncc" {
  source = "../.."

  account         = "GCP"
  ncc_hub_name    = "my_hub"
  transit_gateway = data.aviatrix_transit_gateway.my_gcp_transit
  cr_asn          = 64777
}

resource "test_assertions" "ncc" {
  component = "transit_ncc_connection"

  check "asn_match_primary" {
    description = "The GCP and Aviatrix ASNs match where expected"
    condition   = tonumber(module.avx_ncc.external_device_conn.bgp_local_as_num) == module.avx_ncc.gcp_peer["cr-pri-to-avx-pri"].peer_asn
  }

  check "asn_match_ha" {
    description = "The GCP and Aviatrix ASNs match where expected"
    condition   = tonumber(module.avx_ncc.external_device_conn.bgp_local_as_num) == module.avx_ncc.gcp_peer["cr-ha-to-avx-ha"].peer_asn
  }
}

output "test_assertions" {
  value = test_assertions.ncc.check
}