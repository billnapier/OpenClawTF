locals {
  secrets = {
    "gemini-api-key"              = "${var.secret_prefix}gemini-api-key"
    "telegram-bot-token"          = "${var.secret_prefix}telegram-bot-token"
    "telegram-allowed-user-ids"   = "${var.secret_prefix}telegram-allowed-user-ids"
    "google-calendar-credentials" = "${var.secret_prefix}google-calendar-credentials"
    "gog-keyring-password"        = "${var.secret_prefix}gog-keyring-password"

  }
}

resource "google_secret_manager_secret" "secrets" {
  for_each  = local.secrets
  project   = var.project_id
  secret_id = each.value

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each  = google_secret_manager_secret.secrets
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}
