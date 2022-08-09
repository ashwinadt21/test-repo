terraform {
  required_version = ">= 1.1.3, < 1.2.0"

  required_providers {
    google = {
      version = "~> 3.30"
    }
    google-beta = {
      version = "~> 3.30"
    }
  }
}

provider "google" {
  impersonate_service_account = var.impersonate_service_account
  region = var.default_region
}

provider "google-beta" {
  impersonate_service_account = var.impersonate_service_account
  region = var.default_region
}