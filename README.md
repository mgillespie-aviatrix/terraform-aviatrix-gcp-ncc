# terraform-aviatrix-gcp-ncc

### Description
Connects Google Cloud's Network Connectivity Center to an Aviatrix Transit Gateway.

#### Use cases
- Cloud Interconnect: Use Cloud Interconnect without Overlay such as IPsec.
- SDWAN: SDWAN devices and Aviatrix connect to NCC for route exchange. Useful with multiple distinct SDWAN devices in a VPC.
- Regional aware routing in a Global VPC for SaaS such as Apigee X.

### Compatibility
Module version | Terraform version | Controller version | Terraform provider version
:--- | :--- | :--- | :---
v1.0.0 | 1.4.0 | 7.0 | 3.00

### Usage Example
See [examples](https://github.com/terraform-aviatrix-modules/terraform-aviatrix-gcp-ncc/tree/main/examples)

### Variables
The following variables are required:

key | value
:--- | :---
[account](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_vpc#account_name) | The account name as known by the Aviatrix controller.
[ncc_hub_name](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_connectivity_hub#name) | The name of the NCC hub for the BGP over LAN VPC. A new hub is created by default.
[transit_gateway](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_transit_gateway) | The Transit Gateway object, either from the resource/module or from data.
[cr_asn](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router#asn) | ASN to use for the Cloud Router.

The following variables are optional:

key | default | value 
:---|:---|:---
create_ncc_hub | true | Set to false to use an existing NCC Hub.
[bgp_interface_index](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_transit_gateway#bgp_lan_interfaces) | 0 | Index number of the BGP over LAN interface.
[transit_asn](hhttps://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_transit_gateway#local_as_number) | null | If ASN is specified on the Transit Gateway, this value is not used.
[network_domain](https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_segmentation_network_domain_association#network_domain_name) | null | If Aviatrix Network Domains/segmentation are required, specify this value.

### Outputs
This module will return the following outputs:

key | description
:---|:---
external_device_conn | The Aviatrix Transit external device connection object.
gcp_peer | The GCP Cloud Router BGP peers.