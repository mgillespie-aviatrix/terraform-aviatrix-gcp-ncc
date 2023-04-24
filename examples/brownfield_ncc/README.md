### Usage Example connect existing NCC deployment to Aviatrix Transit.

In this example, the module connects Aviatrix Transit to an existing NCC Hub.

```hcl
module "avx_ncc" {
  source  = "terraform-aviatrix-modules/gcp-ncc/aviatrix"

  account              = "GCP"
  ncc_hub_name         = "avx-mgmt"
  create_ncc_hub       = false
  transit_gateway      = "my-gcp-transit"
  bgp_interface_index  = 0
  cr_asn               = 64701
}
```