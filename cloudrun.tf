module "backend_cloud_run" {
  source     = "./modules/cloud-run-v2"
  project_id = module.project.id
  region     = var.region
  name       = var.cloud_run_back_name
  containers = {
    storage-api = {
      image = "${var.region}-docker.pkg.dev/${module.project.id}/${google_artifact_registry_repository.my_repo.repository_id}/express-backend:latest"
      env = {
        "DB_USER" = "postgres",
        "DB_PASSWORD" = "postgres",
        "DATABASE_URL" = "daily_dashboard",
        "DB_PORT" = 5432
        "DB_HOST" = "/cloudsql/${var.project_name}:${var.region}:${module.db.connection_name}"
      }
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

  custom_audiences = []

  service_account     = module.cloud_run_back_sa.email
  deletion_protection = false
}
