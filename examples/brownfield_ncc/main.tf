module "avx_ncc" {
  source = "terraform-aviatrix-modules/gcp-ncc/aviatrix"

  account         = "GCP"
  ncc_hub_name    = "avx-mgmt"
  create_ncc_hub  = false
  transit_gateway = "my-gcp-transit"
  cr_asn          = 64701
}