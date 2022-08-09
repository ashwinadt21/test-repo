# ------------------------------------------------------------------------------
# CREATE THE NETWORK ENDPOINT GROUP
# ------------------------------------------------------------------------------

data "google_compute_network" "net" {
  name     = var.network_name
  project  = var.network_project
}

data "google_compute_subnetwork" "sub" {
  name     = var.subnetwork
  project  = data.google_compute_network.net.project
  region   = var.region
}

resource "google_compute_network_endpoint_group" "zone1-neg"{
    name = "${var.name}-zone1-neg"
    project = var.project
    network_endpoint_type = "GCE_VM_IP_PORT"
    network = data.google_compute_network.net.id
    subnetwork = data.google_compute_subnetwork.sub.id
    default_port = "443"
    zone = var.zone[0]  
}

resource "google_compute_network_endpoint" "zone1-endpoint" {
  network_endpoint_group = google_compute_network_endpoint_group.zone1-neg.name
  instance   = "endpoint-hc1"
  port       = google_compute_network_endpoint_group.zone1-neg.default_port
  ip_address = "10.118.0.204"
  zone       = var.zone[0]
  project = var.project
}

resource "google_compute_network_endpoint_group" "zone2-neg"{
    name = "${var.name}-zone2-neg"
    project = var.project
    network_endpoint_type = "GCE_VM_IP_PORT"
    network = data.google_compute_network.net.id
    subnetwork = data.google_compute_subnetwork.sub.id
    default_port = "443"
    zone = var.zone[1]  
}

resource "google_compute_network_endpoint" "zone2-endpoint" {
  network_endpoint_group = google_compute_network_endpoint_group.zone2-neg.name
  instance   = "endpoint-hc2"
  port       = google_compute_network_endpoint_group.zone2-neg.default_port
  ip_address = "10.118.0.208"
  zone       = var.zone[1]
  project = var.project
}

# ------------------------------------------------------------------------------
# CREATE THE URL MAP TO MAP PATHS TO BACKENDS
# ------------------------------------------------------------------------------

resource "google_compute_region_url_map" "urlmap" {
  project = var.project
  name        = "${var.name}-ilb"
  description = "URL map for ${var.name}"
  default_service = google_compute_region_backend_service.backend.id
}

# ------------------------------------------------------------------------------
# CREATE THE BACKEND SERVICE CONFIGURATION FOR THE NEG
# ------------------------------------------------------------------------------

resource "google_compute_region_backend_service" "backend" {
  project = var.project
  region  = var.default_region
  name        = "${var.name}-backend"
  description = "Backend for ${var.name}"
  protocol    = var.enable_ssl ? "HTTPS":"HTTP"
  timeout_sec = 10
  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group = google_compute_network_endpoint_group.zone1-neg.self_link
    balancing_mode = "RATE"
    max_rate = 100
    capacity_scaler = 1
    
  }
  backend {
    group = google_compute_network_endpoint_group.zone2-neg.self_link
    balancing_mode = "RATE"
    max_rate = 100
    capacity_scaler = 1
    
  }
  health_checks = [google_compute_region_health_check.default.self_link]
}

# ------------------------------------------------------------------------------
# CONFIGURE HEALTH CHECK FOR THE API BACKEND
# ------------------------------------------------------------------------------

resource "google_compute_region_health_check" "default" {
  project = var.project
  name    = "${var.name}-hc"
  region  = var.default_region
  ssl_health_check {
    port         = var.enable_ssl ? "443":"80"
  }

  check_interval_sec = 5
  timeout_sec        = 5
}

# ------------------------------------------------------------------------------
# IF SSL ENABLED, CREATE FORWARDING RULE AND PROXY
# ------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "https" {
  provider   = google-beta
  project    = var.project
  count      = var.enable_ssl ? 1 : 0
  name       = "${var.name}-https-rule"
  target     = google_compute_region_target_https_proxy.default.self_link
  ip_address = "10.118.0.250"  # Frontend IP Address
  port_range = var.enable_ssl ? "443":"80"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network      = data.google_compute_network.net.id
  subnetwork   = data.google_compute_subnetwork.sub.id 
  network_tier = "PREMIUM"
  labels       = var.custom_labels
}

resource "google_compute_region_target_https_proxy" "default" {
  project = var.project
  name    = "${var.name}-https-proxy"
  url_map = google_compute_region_url_map.urlmap.self_link
  
  ssl_certificates = compact(concat(var.ssl_certificates, google_compute_region_ssl_certificate.default.*.self_link, ), )
}

resource "google_compute_region_ssl_certificate" "default" {
  project = var.project
  name_prefix = "${var.name}-cert"
  private_key = file(var.private_key)
  certificate = file(var.certificate)

  lifecycle {
    create_before_destroy = true
  }
}
