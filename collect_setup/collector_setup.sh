#!/bin/bash

#set -o errexit
set -o pipefail

## declare an array of policies
declare -a ROLES=("roles/iam.workloadIdentityUser" "roles/run.developer" "roles/iam.serviceAccountUser" "roles/storage.admin" "roles/cloudscheduler.admin" "roles/run.invoker" "roles/run.serviceAgent" "roles/cloudasset.viewer" "roles/logging.viewer" "roles/securitycenter.adminViewer")
ROLE_COUNT=$(echo "${ROLES[@]}" | wc -w)
DEFAULT_PROJECT="$(gcloud config get-value project)"
# Declare cloud run service name
CLOUD_RUN="compliance-analysis"
LOG_FILE="deployment-setup.log"
# Set cloud scheduler job interval
SCHEDULE="0 0 * * *"
BRANCH="master"
LOG_LEVEL="INFO"
DATE=$(date)
function clean_up {
  # Find and delete all directories starting with "guardrail" in the current working directory
  for dir in $(find . -type d -name "guardrail-*"); do
    # Delete the directory
    rm -r "$dir"
    echo "Deleted $dir"
  done
}

function input_language {
  ## Allows user to set preferred install language.
  read -p " 
################################################################################
##            Compliance as Code Setup Script                                 ##
################################################################################
 
Select your preferred language for installation.
Sélectionnez votre langue préférée pour l'installation.
1) English
2) Francais
> " LANGUAGE_INPUT

  LANGUAGE=$(tr '[A-Z]' '[a-z]' <<<${LANGUAGE_INPUT})
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

  ## Gathers required information for installation
  printf "$LANG_SETUP_PROMPT"

  if [ -z "$SERVICE_ACCOUNT" ]; then
    read -p "$LANG_SERVICE_ACCOUNT" service_account_input
    if [ -n "$service_account_input" ]; then
      SERVICE_ACCOUNT="$(tr A-Z a-z <<<$service_account_input)"
    fi
  fi
  if [ -z "$PROJECT_ID" ]; then
    read -p "'$DEFAULT_PROJECT' $LANG_PROJECT " project_input
    if [ -n "$project_input" ]; then
      PROJECT_ID=$project_input
    else
      PROJECT_ID=$DEFAULT_PROJECT
    fi
  fi
  if [ -z "$ORG_NAME" ]; then
    read -p "$LANG_ORG_NAME" org_name_input
    if [ -n "$org_name_input" ]; then
      ORG_NAME="$(tr A-Z a-z <<<$org_name_input)"
    fi
  fi
  if [ -z "$GC_PROFILE" ]; then
    read -p "$LANG_GC_PROFILE" profile
    if [ -n "$profile" ]; then
      GC_PROFILE="$(tr A-Z a-z <<<$profile)"
    fi
  fi
  if [ -z "$SSC_BUCKET_NAME" ]; then
    read -p "$LANG_BUCKET" bucket_name_input
    if [ -n "$bucket_name_input" ]; then
      SSC_BUCKET_NAME="$(tr A-Z a-z <<<$bucket_name_input)"
    fi
  fi
  if [ -z "$POLICY_REPO" ]; then
    read -p "$LANG_POLICY" policy_repo_input
    if [ -n "$policy_repo_input" ]; then
      POLICY_REPO="$(tr A-Z a-z <<<$policy_repo_input)"
    fi
  fi
  if [ -z "$CAC_IMAGE" ]; then
    read -p "$LANG_CAC_IMAGE" image
    if [ -n "$image" ]; then
      CAC_IMAGE="$(tr A-Z a-z <<<$image)"
    fi
  fi
  if [ -z "$REGION" ]; then
    read -p "$LANG_REGION" region_number
    # Set the selected region as a variable
    case $region_number in
    1)
      REGION="northamerica-northeast1"
      ;;
    2)
      REGION="northamerica-northeast2"
      ;;
    *)
      tput setaf 1
      echo "" 1>&2
      echo $LANG_ERROR
      tput sgr0
      exit 1
      ;;
    esac
  fi

  PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)" 2>&1)
  ORG_ID="$(gcloud organizations list --filter=${ORG_NAME} --format="value(ID)" 2>&1)"
  ACCOUNT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)" 2>&1)

  # Defining cloud scheduler job name
  JOB_NAME="compliance-analysis-automation-"$(echo ${ACCOUNT_NUMBER} | tr '[:upper:]' '[:lower:]')

  # lower casing bucket name
  BUCKET_NAME="compliance-hub-"$(echo ${ACCOUNT_NUMBER} | tr '[:upper:]' '[:lower:]')
  SERVICE_ACCOUNT="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
}

function config_validation {
  printf "$LANG_VALIDATION_PROMPT"

  # Prompt user to confirm the values of the variables

  read -p "$CONFIRM_PROJECT '$PROJECT_ID' $PROMPT" confirm_project
  read -p "$CONFIRM_REGION '$REGION' $PROMPT" confirm_region
  read -p "$CONFIRM_SERVICE_ACCOUNT '$SERVICE_ACCOUNT' $PROMPT" confirm_sa

  # Check if the user's responses match the values of the variables
  if [[ "$confirm_project" != "$PROJECT_ID" || "$confirm_region" != "$REGION" || "$confirm_sa" != "$SERVICE_ACCOUNT" ]]; then
    tput setaf 1
    echo "" 1>&2
    echo $LANG_ERROR
    tput sgr0
    echo ""
    exit 1
  fi

}

#############################################
## Installation Functions
############################################

function service_account {
  gcloud iam service-accounts describe ${SERVICE_ACCOUNT} >>$LOG_FILE 2>&1
  ret=$?
  if [ $ret -ne 0 ]; then
    tput setaf 1
    echo "" 1>&2
    echo $SA_ERROR
    tput sgr0
    echo ""
    exit 1
  fi
  # Binding the SA to principal account
  echo $BINDING_PROMPT
  echo $BINDING_PROMPT >>$LOG_FILE 2>&1
  gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT \
    --member="user:$(gcloud config list account --format "value(core.account)")" \
    --role="roles/iam.serviceAccountTokenCreator" >>$LOG_FILE 2>&1
  sleep 30
  # validation echo
  echo $ROLE_VALIDATION_PROMPT
  echo $ROLE_VALIDATION_PROMPT >>$LOG_FILE 2>&1
  # Get the IAM policy for the current project
  ATTACH_IAM_POLICY=$(gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" \
    --format='table(bindings.role)' --filter="bindings.members:$SERVICE_ACCOUNT AND \
  -deleted" && gcloud organizations get-iam-policy $ORG_ID --flatten="bindings[].members" \
    --format='table(bindings.role)' --filter="bindings.members:$SERVICE_ACCOUNT AND -deleted")
  # ATTACHED_FILTERED_ROLE=$(echo "$IAM_POLICY" | tr ' ' '\n' | sort | uniq)
  ATTACHED_ROLE_COUNT=($(echo "$ATTACH_IAM_POLICY" |grep -v ^$  wc -l))
  ATTACHED_ROLE_COUNT="$((ATTACHED_ROLE_COUNT - 2))"

  if (($ATTACHED_ROLE_COUNT > $ROLE_COUNT)); then
    tput setaf 3
    echo "" 1>&2
    echo "$SA_POLICY_ERROR"
    echo "$SA_CURRENT_POLICY $ATTACH_IAM_POLICY"
    echo ""
    echo "$SA_REQUIRED_POLICY"
    ## looping though role array
    for i in "${ROLES[@]}"; do
      echo "$i"
    done

    read -p "$POLICY_CONFIRMATION" sa_consent
    sa_consent=$(echo "$sa_consent" | tr '[:upper:]' '[:lower:]')
    if [ "$sa_consent" == "y" ]; then
      tput sgr0
      echo $POLICY_CONTINUE
    else
      tput setaf 1
      echo "" 1>&2
      echo $POLICY_EXIT
      tput sgr0
      exit 1

    fi
  else
    for i in "${ROLES[@]}"; do
      if [[ $ATTACH_IAM_POLICY == *"$i"* ]]; then
        echo "INFO: $i $ROLES_VALIDATION '$SERVICE_ACCOUNT'"
      else
        MISSING_ROLES="$MISSING_ROLES'$i'"
      fi

    done
    if [ -z "$MISSING_ROLES" ]; then
      echo ${ROLES_VALIDATION_SUCCESS}
    else
      tput setaf 3
      echo "" 1>&2
      echo ${ROLES_VALIDATION_ERROR}
      tput sgr0
      echo "$MISSING_ROLES"
      exit 1
    fi
  fi
}

function storage_bucket {

  # Create the bucket
  gsutil ls -b gs://$BUCKET_NAME >>$LOG_FILE 2>&1
  ret=$?
  if [ $ret -ne 0 ]; then
    clean_up
    echo $CREATE_BUCKET
    echo $CREATE_BUCKET >>$LOG_FILE 2>&1
    gsutil --impersonate-service-account="$SERVICE_ACCOUNT" mb -l $REGION gs://$BUCKET_NAME >>$LOG_FILE 2>&1
  fi
  # Set the default storage class for the bucket
  echo $CONFIG_BUCKET
  echo $CONFIG_BUCKET >>$LOG_FILE 2>&1

  gsutil --impersonate-service-account="$SERVICE_ACCOUNT" defstorageclass set STANDARD gs://$BUCKET_NAME >>$LOG_FILE 2>&1

  # Set versioning for the bucket
  gsutil --impersonate-service-account="$SERVICE_ACCOUNT" versioning set on gs://$BUCKET_NAME >>$LOG_FILE 2>&1

  # Create the directories
  FOLDER_COUNT=$(gsutil ls gs://$BUCKET_NAME | wc -l | tr -d '[:space:]')

  if [ $FOLDER_COUNT -lt 12 ]; then
    for i in {1..12}; do
      echo $CREATE_FOLDERS >>$LOG_FILE 2>&1
      echo $CREATE_FOLDERS
      mkdir guardrail-$(printf "%02d" $i)
      echo "Please use this space to upload compliance related files" >guardrail-$(printf "%02d" $i)/instructions.txt
      gsutil --impersonate-service-account="$SERVICE_ACCOUNT" cp -r guardrail-$(printf "%02d" $i) gs://$BUCKET_NAME >>$LOG_FILE 2>&1
      rm -rf guardrail-$(printf "%02d" $i)
    done
  fi
  API_ROLES=("legacyBucketReader" "objectViewer" "legacyBucketWriter")
  for role in ${API_ROLES[@]}; do
    gsutil --impersonate-service-account="$SERVICE_ACCOUNT" iam ch \
      serviceAccount:project-$PROJECT_NUMBER@storage-transfer-service.iam.gserviceaccount.com:${role} \
      gs://${BUCKET_NAME} >>$LOG_FILE 2>&1
  done

  gsutil --impersonate-service-account="$SERVICE_ACCOUNT" iam ch \
    serviceAccount:service-$PROJECT_NUMBER@gcp-sa-cloudasset.iam.gserviceaccount.com:objectAdmin \
    gs://${BUCKET_NAME} >>$LOG_FILE 2>&1

  RUN_HOUR="02:00:00-04:00"
  ORDINAL=$((($RANDOM % 10 + 1)))

  gcloud transfer jobs list --job-statuses=enabled | grep nightly_compliance_transfer > /dev/null 2>&1
  ret=$?
  if [ $ret -ne 0 ]; then
    gcloud transfer jobs create gs://${BUCKET_NAME}/ ${SSC_BUCKET_NAME} \
      --name "nightly_compliance_transfer_${ORDINAL}" \
      --include-modified-after-relative=1d \
      --schedule-starts=$(date -d "+1day" -u +"%Y-%m-%dT${RUN_HOUR}") \
      --schedule-repeats-every=p1d \
      --include-prefixes=results >>$LOG_FILE 2>&1
  fi
}

function cloudrun_service {

  # Run the Cloud Run job using the specified image and publishing the logs
  echo $CREATE_CRUN >>$LOG_FILE 2>&1
  gcloud beta --impersonate-service-account="${SERVICE_ACCOUNT}" \
    run deploy $CLOUD_RUN \
    --region=${REGION} \
    --service-account="${SERVICE_ACCOUNT}" \
    --platform managed \
    --min-instances=0 \
    --max-instances=1 \
    --execution-environment=gen2 \
    --ingress=internal \
    --no-allow-unauthenticated \
    --cpu=4 \
    --memory=4Gi \
    --timeout=60m \
    --image $CAC_IMAGE \
    --set-env-vars "LOG_LEVEL="${LOG_LEVEL}"" \
    --set-env-vars "GCP_PROJECT="${PROJECT_ID}"" \
    --set-env-vars "GCS_BUCKET="${BUCKET_NAME}"" \
    --set-env-vars "ORG_NAME="${ORG_NAME}"" \
    --set-env-vars "ORG_ID="${ORG_ID}"" \
    --set-env-vars "POLICY_REPO="${POLICY_REPO}"" \
    --set-env-vars "BRANCH="${BRANCH}"" \
    --set-env-vars "GC_PROFILE="${GC_PROFILE}"" \
    --port 8443 >>$LOG_FILE 2>&1

  # a buffer so google is ready for subsequent call
  sleep 10

  # Get the URL of the Cloud Run service

  CSERVICE_URL=$(gcloud run services describe "$CLOUD_RUN" --format='value(status.url)' --region="$REGION")

  # Create the Cloud Scheduler job
  echo $CREATE_CSCHEDULER
  gcloud scheduler jobs create http $JOB_NAME \
    --impersonate-service-account="$SERVICE_ACCOUNT" \
    --oidc-service-account-email="$SERVICE_ACCOUNT" \
    --schedule "$SCHEDULE" \
    --location "$REGION" \
    --time-zone "UTC" \
    --project "$PROJECT_ID" \
    --description "Compliance analysis automation" \
    --uri "$CSERVICE_URL" \
    --http-method=GET \
    --attempt-deadline=30m >>$LOG_FILE 2>&1
}

## Setup Logging

echo "$DATE" >$LOG_FILE 2>&1
input_language
echo "$LANG_DEPLOYMENT_PROMPT"
echo "$LANG_DEPLOYMENT_PROMPT" >>$LOG_FILE

if [ -f collector_config ]; then
  echo "$LANG_CONFIG_PROMPT"
  . ./collector_config
  config_init
else
  config_init
  config_validation
fi
service_account
storage_bucket
cloudrun_service

echo "
#################################################################
##                  CaC Tool deployment completed                                        
##                                                                                       
## Compliance Proof GCS Bucket: gs://$BUCKET_NAME       
## Cloud Run Service:  $CSERVICE_URL                                 
##
#################################################################               "                             
