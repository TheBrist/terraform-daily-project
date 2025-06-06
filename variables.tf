variable "parent_folder_id" {
  type    = string
  default = "715513075959"
}

variable "billing_account_id" {
  type      = string
  sensitive = true
}

variable "terraform_service_account_address" {
  type = string
}

variable "region" {
  type    = string
  default = "me-west1"
}

variable "project_apis" {
  type = list(string)
}

variable "project_name" {
  type = string
}

variable "cloud_run_back_name" {
  type = string
}

variable "cloud_run_front_name" {
  type = string
}

variable "subnets" {
  type = list(object({
    ip_cidr_range = string
    name          = string
  }))
}

variable "cloud_sql_cidr_range" {
  type = string
}

variable "elb_cidr_range" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "database" {
  type = string
}

variable "vm_image" {
  type = string
}

variable "org_id" {
  type = string
}