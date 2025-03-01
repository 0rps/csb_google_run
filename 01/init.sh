#!/bin/bash

GCP_PROJECT_ID=-
GCP_PROJECT_NUMBER="-"
GCP_REGION=us-

gcloud projects list
gcloud config set project "$GCP_PROJECT_ID"

gcloud services enable storage.googleapis.com


sed -i "s|<gcp_project_id>|$GCP_PROJECT_ID|g" manifest.tf
sed -i "s|<gcp_project_number>|$GCP_PROJECT_NUMBER|g" manifest.tf
sed -i "s|<gcp_region>|$GCP_REGION|g" manifest.tf