#!/bin/bash

PROJECT_ID=`gcloud config get project 2>/dev/null`

pushd ./code/lab-service
npm install express
npm install body-parser
npm install @google-cloud/pubsub
gcloud builds submit --tag gcr.io/$PROJECT_ID/lab-report-service
popd

# ----

pushd ./code/email-service
npm install express
npm install body-parser
gcloud builds submit --tag gcr.io/$PROJECT_ID/email-service
popd

# ----

pushd ./code/sms-service
npm install express
npm install body-parser
gcloud builds submit --tag gcr.io/$PROJECT_ID/sms-service
popd 
