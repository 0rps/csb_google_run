#!/bin/bash

cd ./lab03

npm install express
npm install body-parser
npm install child_process
npm install @google-cloud/storage

PROJECT_ID=`gcloud config get project 2>/dev/null`

gcloud builds submit --tag gcr.io/$PROJECT_ID/pdf-converter