module "vm-managed-sa-example2" {
  source     = "./modules/compute-vm"
  project_id = module.project.id
  zone       = "${var.region}-b"
  name       = "github-runner"

  instance_type = "e2-medium"

  boot_disk = {
    initialize_params = {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/vm"]
    addresses  = module.addresses.global_addresses["github-runner"].address
  }]

  tags   = ["github-runner"]
  labels = { role = "github-runner" }

  service_account = {
    email  = module.github_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    startup-script = file("${path.module}/install-runner.sh")
  }
}
