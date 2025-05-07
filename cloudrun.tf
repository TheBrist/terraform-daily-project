module "backend_cloud_run" {
  source     = "./modules/cloud-run-v2"
  project_id = module.project.id
  region     = var.region
  name       = var.cloud_run_back_name

  containers = {
    backend-api = {
      image = "${var.region}-docker.pkg.dev/${module.project.id}/${module.back_registry.name}/backend:latest"
      env = {
        "DB_USER" = "postgres",
        "DB_PASSWORD" = "postgres",
        "DATABASE" = "postgres",
        "DB_PORT" = 5432
        "DB_HOST" = "10.60.0.3"
        "JWT_SECRET" = "yeskin"
      }
      volume_mounts = {
        cloudsql = "/cloudsql"
      }
    }
  }

  volumes = {
    "cloudsql" = {
      cloud_sql_instances = [module.db.connection_name]
    }
  }

  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  revision = {
    gen2_execution_environment = true
    max_instance_count = 20
    vpc_access = {
      egress = "ALL_TRAFFIC"
      subnet = module.vpc.subnets["${var.region}/backend-cloudrun"].name
    }
  }

  service_account     = module.cloud_run_back_sa.email
  deletion_protection = false
}

module "frontend_cloud_run" {
  source = "./modules/cloud-run-v2"
  project_id = module.project.id
  region = var.region
  name = var.cloud_run_front_name

  containers = {
    frontend = {
      image = "${var.region}-docker.pkg.dev/${module.project.id}/${module.front_registry.name}/frontend:latest"
      env = {
        "VITE_API_BASE" = module.backend_cloud_run.service_name
      }
    }
  }
  
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  
  deletion_protection = false
}