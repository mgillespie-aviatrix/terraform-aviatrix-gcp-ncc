variable "avx_gcp_account_name" {
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

variable "transit_gateway" {
  description = "Transit Gateway resource."
  type = object(
    {
      vpc_id             = string,
      gw_name            = string,
      private_ip         = string,
      bgp_lan_interfaces = list(any)
      bgp_lan_ip_list    = list(string),
      vpc_reg            = string,
      ha_gw_name         = string,
      ha_private_ip      = string,
      ha_bgp_lan_ip_list = list(string),
      ha_zone            = string,
      local_as_number    = optional(string)
    }
  )
}

variable "bgp_interface_index" {
  description = "Number of the BGP LAN/LANHA interface."
  type        = number
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

  #transit_pri_self_link = "${data.aviatrix_account.this.gcloud_project_id}/zones/${local.transit_pri_zone}/instances/${local.transit_pri_name}"
  #transit_ha_self_link  = "${data.aviatrix_account.this.gcloud_project_id}/zones/${local.transit_ha_zone}/instances/${local.transit_ha_name}"

  transit_vpc_id     = var.transit_gateway.vpc_id
  transit_pri_name   = var.transit_gateway.gw_name
  transit_pri_ip     = var.transit_gateway.private_ip
  transit_pri_bgp_ip = var.transit_gateway.bgp_lan_ip_list[var.bgp_interface_index]
  transit_pri_zone   = var.transit_gateway.vpc_reg
  transit_ha_name    = var.transit_gateway.ha_gw_name
  transit_ha_ip      = var.transit_gateway.ha_private_ip
  transit_ha_bgp_ip  = var.transit_gateway.ha_bgp_lan_ip_list[var.bgp_interface_index]
  transit_ha_zone    = var.transit_gateway.ha_zone
  transit_asn        = coalesce(var.transit_gateway.local_as_number, var.transit_asn)

  region              = regex("[a-z]+-[a-z0-9]+", local.transit_pri_zone)
  ncc_vpc_name        = var.transit_gateway.bgp_lan_interfaces[var.bgp_interface_index].vpc_id
  bgp_subnet_cidr     = var.transit_gateway.bgp_lan_interfaces[var.bgp_interface_index].subnet
  bgp_subnet_selflink = one([for k, v in data.google_compute_subnetwork.ncc : k if v.ip_cidr_range == local.bgp_subnet_cidr])
}