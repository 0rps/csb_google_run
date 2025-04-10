variable "project_id" {
	description = "GCP Project ID"
	type = string
	default = "<gcp_project_id>"
}

locals {
	region = "<gcp_region>"
	project_number = "<gcp_project_number>"

  services = {
    lab_report = {
      name      = "lab-report-service"
      is_public = true
    }
    email = {
      name      = "email-service"
      is_public = false
    }
    sms = {
      name      = "sms-service"
      is_public = false
    }
  }
}


provider google {
    project = var.project_id
}

# ------
resource "google_pubsub_topic" "new-lab-report" {
  name = "new-lab-report"
}

resource "google_cloud_run_v2_service" "services" {
  for_each = local.services

  name     = each.value.name
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
      image = "gcr.io/${var.project_id}/${each.value.name}"
      resources {
        cpu_idle = true
        limits   = { 
            cpu    = "1000m"
            memory = "2Gi"
        }
      }     
    }
  }
}

# ------


# gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
resource "google_project_iam_binding" "pubsub_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:service-${local.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  ]
}

# gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
resource "google_service_account" "pubsub_invoker" {
  account_id   = "pubsub-cloud-run-invoker"
  display_name = "PubSub Cloud Run Invoker"
}

# gcloud run services add-iam-policy-binding email-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region "REGION" --platform managed

resource "google_cloud_run_service_iam_binding" "service_invokesr" {
  for_each = local.services

  location = local.region
  service  = each.value.name
  role     = "roles/run.invoker"

  members = [
    ( each.value.is_public 
      ? "allUsers" 
      : "serviceAccount:${google_service_account.pubsub_invoker.email}" 
    )
  ]
}

# gcloud pubsub subscriptions create email-service-sub --topic new-lab-report --push-endpoint=$EMAIL_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
resource "google_pubsub_subscription" "email_service_sub" {
  name  = "email-service-sub"
  topic = "new-lab-report"

  push_config {
    push_endpoint = google_cloud_run_v2_service.services["email"].uri

    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }
}

# ------

resource "google_pubsub_subscription" "sms_service_sub" {
  name  = "sms-service-sub"
  topic = "new-lab-report"

  push_config {
    push_endpoint = google_cloud_run_v2_service.services["sms"].uri

    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }
}