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

  depends_on = [google_project_service.required]
}

module "artifact_registry" {
  source     = "./modules/artifact_registry"
  project_id = var.project_id
  region     = var.region

  depends_on = [google_project_service.required]
}

module "secrets" {
  source                = "./modules/secrets"
  project_id            = var.project_id
  service_account_email = local.sa_email

  depends_on = [google_project_service.required]
}

module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone

  depends_on = [google_project_service.required]
}

module "compute" {
  source                = "./modules/compute"
  project_id            = var.project_id
  zone                  = var.zone
  subnetwork_id         = module.vpc.subnet_id
  persistent_disk_name  = module.storage.disk_name
  service_account_email = local.sa_email
  container_image       = local.image

  depends_on = [module.storage, google_project_service.required]
}

module "monitoring" {
  source     = "./modules/monitoring"
  project_id = var.project_id

  depends_on = [google_project_service.required]
}
