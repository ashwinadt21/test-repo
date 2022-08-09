terraform {
  backend "gcs" {
    bucket = "adtgcp-terraform-state"
    prefix = "" # Example "<BUSNESSUNIT>/<PROJECT>/<RESOURCE>/state" - "com/adtgcp-com-prd-genetec-lotte/compute/state"
  }
}
