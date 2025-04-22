variable "parent_folder_id" {
  type = string
  default = "715513075959"
}

variable "billing_account_id" {
  type = string
  sensitive = true
}

variable "terraform_service_account_address" {
  type = string
}

variable "region" {
  type = string
  default = "me-west1"
}

variable "project_apis" {
  type = list(string) 
}

variable "project_name" {
  type = string
}
