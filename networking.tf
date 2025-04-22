module "vpc" {
  source     = "./modules/net-vpc"
  project_id = module.project.id
  name       = "mynetwork"

  subnets = [for subnet in var.subnets : {
    ip_cidr_range = subnet.ip_cidr_range
    name          = subnet.name
    region        = var.region
  }]

  psa_configs = [ {
    ranges = {cloud-sql = "10.60.0.0/16"}
    deletion_policy = "ABANDON"
  } ]
}

