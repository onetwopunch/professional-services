# Copyright 2020 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


##################################################
##               Project Level                  ##
##################################################


resource "google_project_iam_member" "df_worker_project_iam" {
  for_each = toset(var.df_worker_project_permissions)
  project  = var.project
  role     = each.key
  member   = local.df_member
}

resource "google_project_iam_member" "cf_runner_iam" {
  for_each = toset(var.cf_runner_permissions)
  project  = var.project
  role     = each.key
  member   = local.cf_member
}

##################################################
##               Resource Level                 ##
##################################################


resource "google_storage_bucket_iam_member" "test_bucket_iam" {
  bucket = google_storage_bucket.test_bucket.name
  role = "roles/storage.objectViewer"
  member = local.df_member
}

# See: https://cloud.google.com/dataflow/docs/concepts/access-control#creating_jobs
resource "google_storage_bucket_iam_binding" "df_bucket_iam" {
  bucket = google_storage_bucket.df_bucket.name
  role = "roles/storage.admin"
  members = [
    local.cf_member,
    local.df_member,
  ]
}

# Allow the Cloud Function to ActAs the DF worker service account
# so that it can trigger the job.
resource "google_service_account_iam_member" "df_service_account_iam" {
  service_account_id = google_service_account.df_worker.name
  role               = "roles/iam.serviceAccountUser"
  member             = local.cf_member
}

resource "google_pubsub_topic_iam_member" "df_topic_iam" {
  project = var.project
  topic = google_pubsub_topic.output_topic.name
  role = "roles/pubsub.publisher"
  member = local.df_member
}

resource "google_secret_manager_secret_iam_member" "df_secret_iam" {
  provider = google-beta

  project = var.project
  secret_id = google_secret_manager_secret.hash_key_secret.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = local.df_member
}

