variable "project_id" {
	description = "GCP Project ID"
	type = string
	default = "<gcp_project_id>"
}

locals {
	region = "<gcp_region>"
	project_number = "<gcp_project_number>"
}


provider google {
    project = var.project_id
}

resource "google_cloud_run_v2_service" "pdf_converter" {
  name     = "pdf-converter"
  location = local.region
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"

  traffic {
	  type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
	  percent = "100"
  }

  template {
    scaling {
      max_instance_count = 1
    }

    containers {
      image = "gcr.io/${var.project_id}/pdf-converter"
      resources {
        cpu_idle = true
        limits   = { 
            cpu    = "1000m"
            memory = "2Gi"
        }
      }
      env {
        name = "PDF_BUCKET"
        value = "${var.project_id}-processed"
      }      
    }
  }
}

resource "google_storage_bucket" "upload" {
  name          = "${var.project_id}-upload"
  location      = "US"
}


resource "google_storage_bucket" "processed" {
  name          = "${var.project_id}-processed"
  location      = "US"
}

resource "google_pubsub_topic" "new_doc" {
  name = "new-doc"
}

resource "google_pubsub_topic_iam_binding" "new_doc_binding" {
  topic = google_pubsub_topic.new_doc.name
  role  = "roles/pubsub.publisher"

  members = [
    "serviceAccount:service-${local.project_number}@gs-project-accounts.iam.gserviceaccount.com"
  ]
}

resource "google_storage_notification" "new_doc_notification" {
  bucket         = "${var.project_id}-upload"
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.new_doc.id
  event_types    = ["OBJECT_FINALIZE"]
}

resource "google_service_account" "pubsub_invoker" {
  account_id   = "pubsub-cloud-run-invoker"
  display_name = "PubSub Cloud Run Invoker"
}


resource "google_cloud_run_service_iam_binding" "cloud_run_invoker" {
  location = local.region
  service  = "pdf-converter"
  role     = "roles/run.invoker"

  members = [
    "serviceAccount:${google_service_account.pubsub_invoker.email}"
  ]
}

resource "google_project_iam_binding" "pubsub_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:service-${local.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  ]
}


resource "google_pubsub_subscription" "pdf_conv_sub" {
  name  = "pdf-conv-sub"
  topic = "new-doc"

  push_config {
    push_endpoint = google_cloud_run_v2_service.pdf_converter.uri

    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }
}