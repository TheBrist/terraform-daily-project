module "terraform_remote_State" {
  source = "./modules/gcs"
  project_id = module.project.id
  name = "tfstate-daily-project"
  location = var.region
}
