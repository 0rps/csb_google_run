#!/bin/bash

GCP_PROJECT_ID=qwiklabs-gcp-04-b44c8db33efd
GCP_PROJECT_NUMBER="1096674639877"
GCP_REGION=us-central1

gcloud projects list
gcloud config set project "$GCP_PROJECT_ID"


sed -i "s|`<gcp_project>`|project-asdf-123|g" manifest.tf
sed -i "s|\`<gcp_project_id>\`|$GCP_PROJECT_ID|g" manifest.tf
sed -i "s|\`<gcp_project_number>\`|$GCP_PROJECT_NUMBER|g" manifest.tf

