variable "account" {
  description = "GCP account as it appears in the controller."
  type        = string
}

variable "create_ncc_hub" {
  description = "Create the NCC hub."
  type        = bool
  default     = true
}

variable "ncc_hub_name" {
  description = "Name of NCC hub."
  type        = string
}

variable "transit_gateway_name" {
  description = "Transit Gateway resource."
  type        = string
}

variable "bgp_interface_index" {
  description = "Number of the BGP LAN/LANHA interface."
  type        = number
  default     = 0
}

variable "transit_asn" {
  description = "ASN of Aviatrix Gateway"
  type        = number
  default     = null
}

variable "cr_asn" {
  description = "ASN of Cloud Router"
  type        = number
}

variable "network_domain" {
  description = "Aviatrix network domain"
  type        = string
  default     = null
}

locals {
  ncc_hub_id = "projects/${data.aviatrix_account.this.gcloud_project_id}/locations/global/hubs/${var.ncc_hub_name}"

  transit_vpc_id     = data.aviatrix_transit_gateway.this.vpc_id
  transit_pri_name   = data.aviatrix_transit_gateway.this.gw_name
  transit_pri_ip     = data.aviatrix_transit_gateway.this.private_ip
  transit_pri_bgp_ip = data.aviatrix_transit_gateway.this.bgp_lan_ip_list[var.bgp_interface_index]
  transit_pri_zone   = data.aviatrix_transit_gateway.this.vpc_reg
  transit_ha_name    = data.aviatrix_transit_gateway.this.ha_gw_name
  transit_ha_ip      = data.aviatrix_transit_gateway.this.ha_private_ip
  transit_ha_bgp_ip  = data.aviatrix_transit_gateway.this.ha_bgp_lan_ip_list[var.bgp_interface_index]
  transit_ha_zone    = data.aviatrix_transit_gateway.this.ha_zone
  transit_asn        = coalesce(data.aviatrix_transit_gateway.this.local_as_number, var.transit_asn)

  region              = regex("[a-z]+-[a-z0-9]+", local.transit_pri_zone)
  ncc_vpc_name        = data.aviatrix_transit_gateway.this.bgp_lan_interfaces[var.bgp_interface_index].vpc_id
  bgp_subnet_cidr     = data.aviatrix_transit_gateway.this.bgp_lan_interfaces[var.bgp_interface_index].subnet
  bgp_subnet_selflink = one([for k, v in data.google_compute_subnetwork.ncc : k if v.ip_cidr_range == local.bgp_subnet_cidr])
}