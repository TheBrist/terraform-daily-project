module "project_folder" {
  source = "./modules/folder"
  parent = "folders/${var.parent_folder_id}"
  name   = "daily-cards"
}

module "project" {
  source          = "./modules/project"
  name            = var.project_name
  parent          = module.project_folder.id
  billing_account = var.billing_account_id
  services        = var.project_apis
}

