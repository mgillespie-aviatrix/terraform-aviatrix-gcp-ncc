output "external_device_conn" {
  description = "The Aviatrix Transit external device connection."
  value       = aviatrix_transit_external_device_conn.avx_to_cr
}

output "gcp_peer_pri" {
  description = "The Google Cloud Router primary peer objects."
  value       = google_compute_router_peer.pri
}

output "gcp_peer_ha" {
  description = "The Google Cloud Router ha peer objects."
  value       = google_compute_router_peer.ha
}