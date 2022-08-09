organization_domain  = "adt.com"
billing_account      = "0106C3-57FC7B-37783F"
group_network_admins = "adtgcp-cs-networkadm@adt.com"

impersonate_service_account = "cs-terraform-service-account@adtgcp-cs-coreterra-seed-6879.iam.gserviceaccount.com"


name    = "adtgcp-cent1-hc-test"
network_project = "adtgcp-cs-enterprise-859a"
region  = "us-central1"
zone    = ["us-central1-a","us-central1-b"]

project = "adtgcp-test-hc5-5286"

# Network Endpoint Group
network_name = "adtgcp-ent-1"
subnetwork   = "adtgcp-us-cent1-ent-dev-g-1"

# SSL Certificates
private_key = "./perf.api2.adt.com-key.pem"
certificate = "./perf.api2.adt.com-cert-only.pem"

