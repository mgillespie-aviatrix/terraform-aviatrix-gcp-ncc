data "aviatrix_account" "this" {
  account_name = var.avx_gcp_account_name
}

data "google_compute_network" "ncc" {
  project = data.aviatrix_account.this.gcloud_project_id
  name    = local.ncc_vpc_name
}

data "google_compute_subnetwork" "ncc" {
  for_each  = toset(data.google_compute_network.ncc.subnetworks_self_links)
  self_link = each.value
}

resource "google_network_connectivity_hub" "this" {
  count = var.create_ncc_hub ? 1 : 0

  project     = data.aviatrix_account.this.gcloud_project_id
  name        = var.ncc_hub_name
  description = "Created by terraform-aviatrix-gcp-ncc module."
}

resource "google_compute_router" "this" {
  project = data.aviatrix_account.this.gcloud_project_id
  region  = local.region
  name    = "${local.ncc_vpc_name}-cr"
  network = local.ncc_vpc_name
  bgp {
    asn = var.cr_asn
  }
}

resource "google_compute_address" "this" {
  project  = data.aviatrix_account.this.gcloud_project_id
  for_each = toset(["pri", "ha"])

  name         = "${local.ncc_vpc_name}-cr-address-${each.value}"
  region       = local.region
  subnetwork   = local.bgp_subnet_selflink
  address_type = "INTERNAL"
}


resource "google_compute_router_interface" "pri" {
  project             = data.aviatrix_account.this.gcloud_project_id
  name                = "${local.ncc_vpc_name}-cr-int-pri"
  router              = google_compute_router.this.name
  region              = local.region
  subnetwork          = local.bgp_subnet_selflink
  private_ip_address  = google_compute_address.this["pri"].address
  redundant_interface = google_compute_router_interface.ha.name
}


resource "google_compute_router_interface" "ha" {
  project            = data.aviatrix_account.this.gcloud_project_id
  name               = "${local.ncc_vpc_name}-cr-int-ha"
  router             = google_compute_router.this.name
  region             = local.region
  subnetwork         = local.bgp_subnet_selflink
  private_ip_address = google_compute_address.this["ha"].address
}

resource "google_network_connectivity_spoke" "avx" {
  project  = data.aviatrix_account.this.gcloud_project_id
  name     = "${local.ncc_vpc_name}-ncc-avx"
  location = local.region
  hub      = try(one(google_network_connectivity_hub.this).id, local.ncc_hub_id)
  linked_router_appliance_instances {
    instances {
      virtual_machine = local.transit_pri_name
      ip_address      = local.transit_pri_bgp_ip
    }
    instances {
      virtual_machine = local.transit_ha_name
      ip_address      = local.transit_ha_bgp_ip
    }
    site_to_site_data_transfer = true
  }
}

resource "google_compute_router_peer" "pri" {
  project  = data.aviatrix_account.this.gcloud_project_id
  for_each = { "pri" = 0, "ha" = 1 }

  name                      = "${local.ncc_vpc_name}-ncc-avx-crpri-to-${each.key}-gw"
  router                    = google_compute_router.this.name
  region                    = local.region
  peer_ip_address           = [local.transit_pri_bgp_ip, local.transit_ha_bgp_ip][each.value]
  peer_asn                  = local.transit_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.pri.name
  router_appliance_instance = [google_network_connectivity_spoke.avx.linked_router_appliance_instances[0].instances[0].virtual_machine, google_network_connectivity_spoke.avx.linked_router_appliance_instances[0].instances[1].virtual_machine][each.value]
}

resource "google_compute_router_peer" "ha" {
  project  = data.aviatrix_account.this.gcloud_project_id
  for_each = { "pri" = 0, "ha" = 1 }

  name                      = "${local.ncc_vpc_name}-ncc-avx-crha-to-${each.key}-gw"
  router                    = google_compute_router.this.name
  region                    = local.region
  peer_ip_address           = [local.transit_pri_bgp_ip, local.transit_ha_bgp_ip][each.value]
  peer_asn                  = local.transit_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.ha.name
  router_appliance_instance = [google_network_connectivity_spoke.avx.linked_router_appliance_instances[0].instances[0].virtual_machine, google_network_connectivity_spoke.avx.linked_router_appliance_instances[0].instances[1].virtual_machine][each.value]
}

resource "aviatrix_transit_external_device_conn" "avx_to_cr" {
  vpc_id                    = local.transit_vpc_id
  connection_name           = "${local.ncc_vpc_name}-avx-to-ncc"
  gw_name                   = local.transit_pri_name
  connection_type           = "bgp"
  tunnel_protocol           = "LAN"
  bgp_local_as_num          = local.transit_asn
  bgp_remote_as_num         = var.cr_asn
  remote_lan_ip             = google_compute_address.this["pri"].address
  local_lan_ip              = local.transit_pri_bgp_ip
  ha_enabled                = true
  backup_bgp_remote_as_num  = var.cr_asn
  backup_remote_lan_ip      = google_compute_address.this["ha"].address
  backup_local_lan_ip       = local.transit_ha_bgp_ip
  enable_bgp_lan_activemesh = true
}

resource "aviatrix_segmentation_network_domain_association" "this" {
  count = var.network_domain == null ? 0 : 1

  network_domain_name = var.network_domain
  attachment_name     = aviatrix_transit_external_device_conn.avx_to_cr.connection_name
}