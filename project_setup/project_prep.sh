#!/bin/bash

#set -o errexit
set -o pipefail



LOG_FILE="deployment-setup.log"
DATE=$(date)


PROJECT_ID="$(gcloud config get-value project)"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)" 2>&1)

PROJECT_ROLES=("iam.workloadIdentityUser" "run.developer" "iam.serviceAccountUser" "storage.admin" "storage.buckets.create" "cloudscheduler.admin" "run.invoker" "run.serviceAgent")
ORG_ROLES=("securitycenter.adminViewer" "logging.viewer" "cloudasset.viewer" "essentialcontacts.viewer" "certificatemanager.viewer" "accesscontextmanager.policyReader" "accesscontextmanager.gcpAccessReader")

SERVICE_APIS=("run" "storagetransfer" "cloudasset")
PROJECT_APIS=("run" "cloudscheduler" "storage" "cloudasset" "storagetransfer" "securitycenter" "containerregistry" "admin" "cloudidentity" "cloudresourcemanager" "orgpolicy" "accesscontextmanager" "certificatemanager" "essentialcontacts" )


function input_language {
  ## Allows user to set preferred install language.
  read -p " 
################################################################################
##            Compliance as Code Prep Script                                 ##
################################################################################

Select your preferred language for installation.
Sélectionnez votre langue préférée pour l'installation.
1) English
2) Francais
> " LANGUAGE_INPUT

  LANGUAGE=$(tr '[A-Z]' '[a-z]' <<<$LANGUAGE_INPUT)
  case $LANGUAGE in
  1)
    source ../language_localization/english_ENG.sh
    ;;
  2)
    source ../language_localization/french_FR.sh
    ;;
  *)
    tput setaf 1
    echo "" 1>&2
    echo $'ERROR: Invalid input. Please select an installation language'
    tput sgr0
    exit 1
    ;;
  esac
}
function config_init {
  read -p "$LANG_ORG_NAME" org_name_input
    if [ -n "$org_name_input" ]; then
      ORG_NAME="$(tr A-Z a-z <<<$org_name_input)"
    fi
  ORG_ID="$(gcloud organizations list --filter=$org_name_input --format="value(ID)" 2>&1)"
  OUTPUT_FILE="${ORG_NAME}-service-account.log"
  echo "$DATE" >$LOG_FILE 2>&1
  echo "$DATE" >$OUTPUT_FILE 2>&1
}
function enable_apis {
  echo "$LANG_APIS"
  for service in ${PROJECT_APIS[@]}; do
    gcloud services enable $service.googleapis.com --project=$PROJECT_ID >>$LOG_FILE 2>&1
  done
}

function service_account_setup {
  SERVICE_ACCOUNT="cac-solution-${ORG_ID}-sa"
  gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
    --description="CaC Solution Service Account" >>$LOG_FILE 2>&1

  echo "$LANG_SA_SETUP"
  for role in ${PROJECT_ROLES[@]}; do
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
      --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
      --role=roles/${role}>>$LOG_FILE 2>&1
  done

  for role in ${ORG_ROLES[@]}; do
    gcloud organizations add-iam-policy-binding $ORG_ID \
      --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
      --role=roles/${role}>>$LOG_FILE 2>&1
  done
}

function service_identities_create {
  echo "$LANG_SI_CREATE"
  for api in ${SERVICE_APIS[@]}; do
    gcloud beta services identity create --service ${api}.googleapis.com >>$LOG_FILE 2>&1

  done
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:project-$PROJECT_NUMBER@storage-transfer-service.iam.gserviceaccount.com \
    --role=roles/storage.objectViewer>>$LOG_FILE 2>&1
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-cloudasset.iam.gserviceaccount.com \
    --role=roles/storage.objectAdmin >>$LOG_FILE 2>&1
}

input_language
config_init
enable_apis
service_account_setup

service_identities_create

echo "
################################################################################
##             CaC Environment Preparation completed                          
################################################################################
## Service Account Information for SSC:
##
## Compliance Tool Service Account: 
## $SERVICE_ACCOUNT
##
## CloudRun Robot Account: 
## service-$PROJECT_NUMBER@serverless-robot-prod.iam.gserviceaccount.com
##
## Cloud Storage Robot Account:    
## project-$PROJECT_NUMBER@storage-transfer-service.iam.gserviceaccount.com     
##
## Binary Authorization Service Account:
## service-$PROJECT_NUMBER@gcp-sa-binaryauthorization.iam.gserviceaccount.com   
##
################################################################################
"
echo "
################################################################################
##             CaC Environment Preparation completed                          
################################################################################
## Service Account Information for SSC:
##
## Compliance Tool Service Account: 
## $SERVICE_ACCOUNT
##
## CloudRun Robot Account: 
## service-$PROJECT_NUMBER@serverless-robot-prod.iam.gserviceaccount.com
##
## Cloud Storage Robot Account:    
## project-$PROJECT_NUMBER@storage-transfer-service.iam.gserviceaccount.com     
##
## Binary Authorization Service Account:
## service-$PROJECT_NUMBER@gcp-sa-binaryauthorization.iam.gserviceaccount.com   
##
################################################################################
" > $OUTPUT_FILE 2>&1
