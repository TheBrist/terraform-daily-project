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

module "firewall" {
  source     = "./modules/net-vpc-firewall"
  project_id = module.project.id
  network    = module.vpc.name
  
  ingress_rules = {
    allow-cloudrun-to-sql = {
      description = "Allow backend cloudrun service to access sql database"
      source_ranges = [ module.vpc.subnets["${var.region}/cr-back-vpc-connector"].ip_cidr_range ]
      destination_ranges = [module.db.ip]
      rules = [{protocol = "tcp", ports = [5432]}]
    }
  }
}