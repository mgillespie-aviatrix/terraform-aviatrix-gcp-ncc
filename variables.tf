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

# variable "transit_gateway_name" {
#   description = "Transit Gateway resource."
#   type        = string
# }

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

# variable "transit_gateway_ha" {
#   description = "Transit Gateway in HA."
#   type        = bool
#   default     = true
# }

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
  ncc_hub_id         = "projects/${data.aviatrix_account.this.gcloud_project_id}/locations/global/hubs/${var.ncc_hub_name}"
  transit_gateway_ha = coalesce(var.transit_gateway.ha_zone, "none") == "none" ? false : true

  #URI is built here because the Google Terraform provider throws an inconsistent plan error if I use the self_link from the google_compute_instance data for the gateways.
  avx_peer_pri = {
    pri = {
      i    = 0,
      name = var.transit_gateway.gw_name,
      ip   = var.transit_gateway.bgp_lan_ip_list[var.bgp_interface_index]
      zone = var.transit_gateway.vpc_reg
      uri  = "projects/${data.aviatrix_account.this.gcloud_project_id}/zones/${var.transit_gateway.vpc_reg}/instances/${var.transit_gateway.gw_name}"
    }
  }
  avx_peer_ha = local.transit_gateway_ha ? {
    ha = {
      i    = 1,
      name = var.transit_gateway.ha_gw_name
      ip   = var.transit_gateway.ha_bgp_lan_ip_list[var.bgp_interface_index],
      zone = var.transit_gateway.ha_zone
      uri  = "projects/${data.aviatrix_account.this.gcloud_project_id}/zones/${var.transit_gateway.ha_zone}/instances/${var.transit_gateway.ha_gw_name}"
    }
  } : {}

  avx_peers = merge(local.avx_peer_pri, local.avx_peer_ha)

  cr_peers = ["pri", "ha"]
  cr_peer_map = merge([for k in local.cr_peers :
    {
      for k2 in keys(local.avx_peers) : "cr-${k}-to-avx-${k2}" =>
      {
        cr  = k,
        avx = k2
      }
    }
  ]...)
}