provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
}

locals {
  sa_email = var.service_account_email != "" ? var.service_account_email : data.google_compute_default_service_account.default.email
  image    = var.container_image != "" ? var.container_image : "${var.region}-docker.pkg.dev/${var.project_id}/openclaw/app:latest"
}

module "vpc" {
  source     = "./modules/vpc"
  project_id = var.project_id
  region     = var.region
}

module "artifact_registry" {
  source     = "./modules/artifact_registry"
  project_id = var.project_id
  region     = var.region
}

module "secrets" {
  source                = "./modules/secrets"
  project_id            = var.project_id
  service_account_email = local.sa_email
}

module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
}

module "compute" {
  source                = "./modules/compute"
  project_id            = var.project_id
  zone                  = var.zone
  subnetwork_id         = module.vpc.subnet_id
  persistent_disk_name  = module.storage.disk_name
  service_account_email = local.sa_email
  container_image       = local.image

  depends_on = [module.storage]
}

module "monitoring" {
  source     = "./modules/monitoring"
  project_id = var.project_id
}
