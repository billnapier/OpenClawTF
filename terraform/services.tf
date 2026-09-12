# Google Cloud API enablement.
#
# Bootstrap exception: cloudresourcemanager.googleapis.com and
# serviceusage.googleapis.com must be enabled by hand before Terraform can
# manage project services at all — the provider needs them to make these very
# calls. Everything else belongs here rather than in a manual setup step (see
# docs/Quickstart.md).
locals {
  required_services = toset([
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "artifactregistry.googleapis.com",
    "sts.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project = var.project_id
  service = each.value

  # Enabling an already-enabled API is a no-op, so this adopts services that
  # were turned on by hand before they were declared here.
  #
  # Never disable on destroy: other workloads in the project may depend on
  # these, and re-enabling is slow enough to turn a teardown into an outage.
  disable_on_destroy = false
}
