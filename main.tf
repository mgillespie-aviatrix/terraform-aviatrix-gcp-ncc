resource "google_network_connectivity_hub" "this" {
  count = var.create_ncc_hub ? 1 : 0

  project     = data.aviatrix_account.this.gcloud_project_id
  name        = var.ncc_hub_name
  description = "Created by terraform-aviatrix-gcp-ncc module."
}

resource "google_compute_router" "this" {
  project = data.aviatrix_account.this.gcloud_project_id
  region  = data.google_compute_subnetwork.bgp.region
  name    = "${var.transit_gateway.gw_name}-cr"
  network = data.google_compute_subnetwork.bgp.network
  bgp {
    asn = var.cr_asn
  }
}

resource "google_compute_address" "this" {
  project  = data.aviatrix_account.this.gcloud_project_id
  for_each = toset(local.cr_peers)

  name         = "${google_compute_router.this.name}-address-${each.value}"
  region       = data.google_compute_subnetwork.bgp.region
  subnetwork   = data.google_compute_subnetwork.bgp.self_link
  address_type = "INTERNAL"
}

resource "google_compute_router_interface" "pri" {
  project = data.aviatrix_account.this.gcloud_project_id

  name                = "${google_compute_router.this.name}-int-pri"
  router              = google_compute_router.this.name
  region              = data.google_compute_subnetwork.bgp.region
  subnetwork          = data.google_compute_subnetwork.bgp.self_link
  private_ip_address  = google_compute_address.this["pri"].address
  redundant_interface = google_compute_router_interface.ha.name
}

resource "google_compute_router_interface" "ha" {
  project = data.aviatrix_account.this.gcloud_project_id

  name               = "${google_compute_router.this.name}-int-ha"
  router             = google_compute_router.this.name
  region             = data.google_compute_subnetwork.bgp.region
  subnetwork         = data.google_compute_subnetwork.bgp.self_link
  private_ip_address = google_compute_address.this["ha"].address
}

resource "google_network_connectivity_spoke" "avx" {
  project  = data.aviatrix_account.this.gcloud_project_id
  name     = "${google_compute_router.this.name}-to-avx"
  location = data.google_compute_subnetwork.bgp.region
  hub      = try(one(google_network_connectivity_hub.this).id, local.ncc_hub_id)
  linked_router_appliance_instances {
    dynamic "instances" {
      for_each = local.avx_peers
      content {
        virtual_machine = local.avx_peers[instances.key]["uri"]
        ip_address      = instances.value["ip"]
      }
    }
    site_to_site_data_transfer = true
  }
}

resource "google_compute_router_peer" "this" {
  for_each = local.cr_peer_map

  project                   = data.aviatrix_account.this.gcloud_project_id
  name                      = "${google_compute_router.this.name}-avx-peer-${each.key}"
  router                    = google_compute_router.this.name
  region                    = data.google_compute_subnetwork.bgp.region
  peer_ip_address           = local.avx_peers[each.value["avx"]]["ip"]
  peer_asn                  = aviatrix_transit_external_device_conn.avx_to_cr.bgp_local_as_num
  advertised_route_priority = 100
  interface                 = each.value["cr"] == "pri" ? google_compute_router_interface.pri.name : google_compute_router_interface.ha.name
  router_appliance_instance = local.avx_peers[each.value["avx"]]["uri"]

  depends_on = [
    google_network_connectivity_spoke.avx
  ]
}

resource "aviatrix_transit_external_device_conn" "avx_to_cr" {
  vpc_id                    = var.transit_gateway.vpc_id
  connection_name           = "${google_compute_router.this.name}-ncc-to-avx"
  gw_name                   = var.transit_gateway.gw_name
  connection_type           = "bgp"
  tunnel_protocol           = "LAN"
  bgp_local_as_num          = coalesce(var.transit_gateway.local_as_number, var.transit_asn)
  bgp_remote_as_num         = var.cr_asn
  remote_lan_ip             = google_compute_address.this["pri"].address
  local_lan_ip              = local.avx_peers["pri"]["ip"]
  ha_enabled                = local.transit_gateway_ha
  backup_bgp_remote_as_num  = local.transit_gateway_ha ? var.cr_asn : null
  backup_remote_lan_ip      = local.transit_gateway_ha ? google_compute_address.this["ha"].address : null
  backup_local_lan_ip       = local.transit_gateway_ha ? local.avx_peers["ha"]["ip"] : null
  enable_bgp_lan_activemesh = local.transit_gateway_ha
}

resource "aviatrix_segmentation_network_domain_association" "this" {
  count = var.network_domain == null ? 0 : 1

  network_domain_name = var.network_domain
  attachment_name     = aviatrix_transit_external_device_conn.avx_to_cr.connection_name
}