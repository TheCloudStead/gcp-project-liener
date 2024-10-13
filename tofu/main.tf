#######################################################################################
# Provider
#######################################################################################

provider "google" {
  project = var.project_id
  region  = var.region
}

#######################################################################################
# Locals
#######################################################################################

locals {
  youtube_project     = "gcp-project-liener"
  youtube_project_fmt = "GCP Project Liener"
}

#######################################################################################
# APIs
#######################################################################################

resource "google_project_service" "cloudscheduler" {
  project            = var.project_id
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunction" {
  project            = var.project_id
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

#######################################################################################
# Messaging
#######################################################################################

resource "google_pubsub_topic" "topic" {
  name = "${local.youtube_project}-topic"
}

#######################################################################################
# Function
#######################################################################################

resource "google_service_account" "account" {
  account_id   = "${local.youtube_project}-sa"
  display_name = "${local.youtube_project_fmt} Service Account"
}

resource "google_organization_iam_custom_role" "custom_org_role" {
  role_id     = replace(local.youtube_project_fmt, " ", "")
  org_id      = var.org_id
  title       = "${local.youtube_project_fmt} Custom Role"
  permissions = ["resourcemanager.projects.list", "resourcemanager.projects.get", "resourcemanager.folders.list"]
}

resource "google_organization_iam_member" "org_custom_binding" {
  org_id = var.org_id
  role   = google_organization_iam_custom_role.custom_org_role.name
  member = "serviceAccount:${google_service_account.account.email}"
}

resource "google_organization_iam_member" "org_lien_mod_binding" {
  org_id = var.org_id
  role   = "roles/resourcemanager.lienModifier"
  member = "serviceAccount:${google_service_account.account.email}"
}

resource "google_storage_bucket" "bucket" {
  name                        = "${local.youtube_project}-gcf-source"
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "archive" {
  name   = "function.zip"
  bucket = google_storage_bucket.bucket.name
  source = "../src/function.zip"
}

resource "google_cloudfunctions_function" "function" {
  name                  = "${local.youtube_project}-function"
  description           = "Cloud function to add a deletion protection lien projects in the org."
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  runtime               = "python312"
  entry_point           = "main"
  service_account_email = google_service_account.account.email
  environment_variables = {
    ORGANIZATION_ID = var.org_id
    RESTRICTIONS    = var.restrictions
    ORIGIN          = var.origin
    REASON          = var.reason
  }

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.topic.name
    failure_policy {
      retry = true
    }
  }

  depends_on = [
    google_service_account.account,
    google_project_service.cloudfunction,
    google_project_service.artifactregistry,
    google_project_service.cloudresourcemanager
  ]
}

#######################################################################################
# Cloud Scheduler
#######################################################################################

resource "google_service_account" "scheduler_account" {
  account_id   = "${local.youtube_project}-cs-sa"
  display_name = "${local.youtube_project_fmt} Scheduler Service Account"
}

resource "google_project_iam_member" "scheduler_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.scheduler_account.email}"
}

resource "google_cloud_scheduler_job" "scheduler" {
  name        = "${local.youtube_project}-job"
  description = "${local.youtube_project_fmt} Scheduler Job"
  schedule    = var.cron
  time_zone   = var.time_zone
  pubsub_target {
    topic_name = google_pubsub_topic.topic.id
    data       = base64encode("{\"message\": \"Liening time!\"}")
  }

  depends_on = [google_project_service.cloudscheduler]
}

#######################################################################################
# END
#######################################################################################