data "google_organization" "org" {
  domain = var.organization_domain
}
data "google_billing_account" "default" {
  billing_account = var.billing_account
  open            = true
}

locals {
  primary_region   = var.default_region
  secondary_region = var.backup_region
}

