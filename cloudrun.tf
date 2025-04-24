module "backend_cloud_run" {
  source     = "./modules/cloud-run-v2"
  project_id = module.project.id
  region     = var.region
  name       = var.cloud_run_back_name

  containers = {
    backend-api = {
      image = "${var.region}-docker.pkg.dev/${module.project.id}/${google_artifact_registry_repository.back.repository_id}/express-backend:latest"
      env = {
        "DB_USER" = "postgres",
        "DB_PASSWORD" = "postgres",
        "DATABASE" = "postgres",
        "DB_PORT" = 5432
        "DB_HOST" = "10.60.0.3"
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
  vpc_connector_create = {
    subnet = {
      name = module.vpc.subnets["${var.region}/cr-back-vpc-connector"].name
      project_id = module.project.id
    }
    throughput = {
        max = 300
        min = 200
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
      image = "${var.region}-docker.pkg.dev/${module.project.id}/${google_artifact_registry_repository.front.repository_id}/react-frontend:latest"
      env = {
        "VITE_API_BASE" = module.backend_cloud_run.service_name
      }
    }
  }

  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  revision = {
    vpc_access = {
      connector = module.backend_cloud_run.vpc_connector
      egress = "ALL_TRAFFIC"
    }
  }
  
  deletion_protection = false
}