#!/bin/bash

#set -o errexit
set -o pipefail



LOG_FILE="deployment-setup.log"
DATE=$(date)


PROJECT_ID="$(gcloud config get-value project)"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)" 2>&1)

CUSTOM_ROLES_DIR="./custom_roles"

CUSTOM_PROJECT_ROLES_FILES=(
    "cac-storage-role" 
    "cac-storage-object-role"
    "cac-scheduler-role" 
    "cac-run-role"
)

PROJECT_ROLES=(
    "iam.workloadIdentityUser" 
    "iam.serviceAccountUser" 
    "run.invoker" 
    "run.serviceAgent"
)

OLD_PROJECT_ROLES=(
    "storage.admin"
    "cloudscheduler.admin"
    "run.developer"
)

CUSTOM_PROJECT_ROLES=(
    "projects/$PROJECT_ID/roles/cac_storage_role" #storage.admin
    "projects/$PROJECT_ID/roles/cac_scheduler_role"  #cloudscheduler.admin
    "projects/$PROJECT_ID/roles/cac_run_role" #run.developer
)

ORG_ROLES=(
    "securitycenter.adminViewer" 
    "logging.viewer" 
    "cloudasset.viewer" 
    "essentialcontacts.viewer" 
    "certificatemanager.viewer" 
    "accesscontextmanager.policyReader" 
    "accesscontextmanager.gcpAccessReader"
)

SERVICE_APIS=(
    "run" 
    "storagetransfer" 
    "cloudasset"
)

PROJECT_APIS=(
    "run" 
    "cloudscheduler" 
    "storage" 
    "cloudasset" 
    "storagetransfer" 
    "securitycenter" 
    "containerregistry" 
    "admin" 
    "cloudidentity" 
    "cloudresourcemanager" 
    "orgpolicy" 
    "accesscontextmanager" 
    "certificatemanager" 
    "essentialcontacts" 
)


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

function create_custom_project_roles {
  echo "$LANG_CUSTOM_ROLES"
  
  for role_file in ${CUSTOM_PROJECT_ROLES_FILES[@]}; do
    role_id="${role_file//-/_}"  # Convert hyphens to underscores for role ID
    role_yaml="$CUSTOM_ROLES_DIR/${role_file}.yaml"
    
    # Try to create the role first
    if gcloud iam roles create $role_id \
       --project=$PROJECT_ID \
       --file=$role_yaml \
       --quiet >>$LOG_FILE 2>&1
    then
      : # Do nothing
    else
      # If creation failed (likely because role exists) then update it instead
      gcloud iam roles update $role_id \
        --project=$PROJECT_ID \
        --file=$role_yaml \
        --quiet >>$LOG_FILE 2>&1
    fi
    
  done
}


function service_account_setup {
  SERVICE_ACCOUNT="cac-solution-${ORG_ID}-sa"
  gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
    --description="CaC Solution Service Account" >>$LOG_FILE 2>&1

  echo "$LANG_SA_SETUP"
  
    # Remove old pre-defined roles from service account, if they exist
    for role in "${OLD_PROJECT_ROLES[@]}"; do
        gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
        --member=serviceAccount:${SERVICE_ACCOUNT}@$PROJECT_ID.iam.gserviceaccount.com \
        --role=roles/${role} >>$LOG_FILE 2>&1
    done

    for role in ${PROJECT_ROLES[@]}; do
        gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
        --role=roles/${role}>>$LOG_FILE 2>&1
    done
  
    for role in ${CUSTOM_PROJECT_ROLES[@]}; do
        gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
        --role=${role}>>$LOG_FILE 2>&1
    done
    
    for role in ${ORG_ROLES[@]}; do
        gcloud organizations add-iam-policy-binding $ORG_ID \
        --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --condition=None \
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
    --role=projects/$PROJECT_ID/roles/cac_storage_object_role >>$LOG_FILE 2>&1 # storage.objectAdmin
}

input_language
config_init
enable_apis
create_custom_project_roles
service_account_setup
service_identities_create

echo "
################################################################################
##             CaC Environment Preparation completed                          
################################################################################
## Service Account Information for SSC:
##
## Compliance Tool Service Account: 
## $SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
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
## $SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
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
