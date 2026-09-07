resource "google_compute_instance" "openclaw_vm" {
  project      = var.project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  attached_disk {
    source      = var.persistent_disk_name
    device_name = "openclaw-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = var.subnetwork_id
    # No access_config block ensures no public IP is assigned
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = templatefile("${path.module}/templates/startup-script.sh.tftpl", {
      container_image = var.container_image
    })
  }
}
