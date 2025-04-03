#!/bin/bash

#set -o errexit
set -o pipefail

## declare an array of policies
declare -a ROLES=("roles/iam.workloadIdentityUser" "roles/run.developer" "roles/iam.serviceAccountUser" "roles/storage.admin" "roles/cloudscheduler.admin" "roles/run.invoker" "roles/run.serviceAgent" "roles/cloudasset.viewer" "roles/logging.viewer" "roles/securitycenter.adminViewer")
ROLE_COUNT=$(echo "${ROLES[@]}" | wc -w)
# Declare cloud run service name
CLOUD_RUN="compliance-analysis"
LOG_FILE="deployment-setup.log"
# Set cloud scheduler job interval
SCHEDULE="0 0 * * *"
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
  REQUIRED_VARIABLES=("PROJECT_ID" "SERVICE_ACCOUNT" "ORG_NAME" "GC_PROFILE" "SECURITY_CATEGORY_KEY" "PRIVILEGED_USERS_LIST" "REGULAR_USERS_LIST" "ALLOWED_DOMAINS" "DENY_DOMAINS" "HAS_GUEST_USERS" "HAS_FEDERATED_USERS" "ALLOWED_IPS" "CUSTOMER_IDS" "CA_ISSUERS" "ORG_ADMIN_GROUP_EMAIL" "BREAKGLASS_USER_EMAIL" "SSC_BUCKET_NAME" "POLICY_REPO" "OPA_IMAGE" "REGION")

  for setting in "${REQUIRED_VARIABLES[@]}"; do
    if [ -z "${!setting}" ]; then
      echo "ERROR: $setting is not set. Please set the variable in the collector_config file"
    fi
  done

  PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)" 2>&1)
  ORG_ID="$(gcloud organizations list --filter=${ORG_NAME} --format="value(ID)" 2>&1)"
  ACCOUNT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)" 2>&1)

  # Defining cloud scheduler job name
  JOB_NAME="compliance-analysis-automation-"$(echo ${ACCOUNT_NUMBER} | tr '[:upper:]' '[:lower:]')

  # lower casing bucket name
  BUCKET_NAME="compliance-hub-"$(echo ${ACCOUNT_NUMBER} | tr '[:upper:]' '[:lower:]')
  SERVICE_ACCOUNT="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
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

  if [ $FOLDER_COUNT -lt 13 ]; then
    for i in {1..13}; do
      echo $CREATE_FOLDERS >>$LOG_FILE 2>&1
      echo $CREATE_FOLDERS
      mkdir guardrail-$(printf "%02d" $i)
      echo "Please use this space to upload compliance related files" >guardrail-$(printf "%02d" $i)/instructions.txt
      gsutil --impersonate-service-account="$SERVICE_ACCOUNT" cp -r guardrail-$(printf "%02d" $i) gs://$BUCKET_NAME >>$LOG_FILE 2>&1
      rm -rf guardrail-$(printf "%02d" $i)
    done
  fi

  # Set the IAM policy for the bucket
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

  # Set up cloud storage transfer job
  gcloud transfer jobs list --job-statuses=enabled | grep nightly_compliance_transfer >/dev/null 2>&1
  ret=$?
  if [ $ret -ne 0 ]; then
    gcloud transfer jobs create gs://${BUCKET_NAME}/ ${SSC_BUCKET_NAME}/${ORG_NAME}/ \
      --name "nightly_compliance_transfer_${ORDINAL}" \
      --include-modified-after-relative=1d \
      --schedule-starts=$(date -d "+1day" -u +"%Y-%m-%dT${RUN_HOUR}")
  fi
}

function cloudrun_service {

  # Run the Cloud Run job using the specified image and publishing the logs
  echo $CREATE_CRUN >>$LOG_FILE 2>&1
  cat <<EOF >cloudrun.yaml
        apiVersion: serving.knative.dev/v1
        kind: Service
        metadata:
          name: ${CLOUD_RUN}
          labels:
            cloud.googleapis.com/location: northamerica-northeast1
          annotations:
        spec:
          template:
            metadata:
              labels:
                run.googleapis.com/startupProbeType: Default
              annotations:
                autoscaling.knative.dev/maxScale: '1'
                run.googleapis.com/execution-environment: gen2
                run.googleapis.com/startup-cpu-boost: 'true'
                run.googleapis.com/container-dependencies: '{"cac-python-1":["opa-1"]}'
            spec:
              containerConcurrency: 80
              timeoutSeconds: 300
              serviceAccountName: ${SERVICE_ACCOUNT}
              containers:
              - name: cac-python-1
                image: ${REGION}-docker.pkg.dev/${BUILD_PROJECT_ID}/cac-python/cac-app:${IMAGE_TAG}
                imagePullPolicy: Always
                ports:
                - name: http1
                  containerPort: ${APP_PORT}
                env:
                - name: APP_PORT
                  value: "${APP_PORT}"
                - name: LOG_LEVEL
                  value: "INFO"
                - name: GCP_PROJECT
                  value: "${PROJECT_ID}"
                - name: ORG_NAME
                  value: "${ORG_NAME}"
                - name: ORG_ID
                  value: "${ORG_ID}"
                - name: GCS_BUCKET
                  value: "${GCS_BUCKET}"
                - name: GC_PROFILE
                  value: "${GC_PROFILE}"
                - name: TENANT_DOMAIN
                  value: "${TENANT_DOMAIN}"
                - name: POLICY_VERSION
                  value: "${POLICY_VERSION}"
                - name: APP_VERSION
                  value: "${IMAGE_TAG}"
                - name: CUSTOMER_ID
                  value: "${DIRECTORY_CUSTOMER_ID}"
                - name: ORG_ADMIN_GROUP_EMAIL
                  value: "${ORG_ADMIN_GROUP_EMAIL}"
                - name: BREAKGLASS_USER_EMAIL
                  value: "${BREAKGLASS_USER_EMAIL}"
                resources:
                  limits:
                    cpu: 4000m
                    memory: 4Gi
              - name: opa-1
                image: "${OPA_IMAGE}"
                imagePullPolicy: Always
                command: ['/bin/bash']
                args: 
                  - -c
                  - |
                    rm -Rf /mnt/policies/*
                    git config --global credential.helper gcloud.sh
                    git clone --quiet ${POLICY_REPO} /mnt/policies
                    cd /mnt/policies
                    git checkout ${BRANCH}
                    ls -l /mnt/policies
                    /usr/bin/opa run --server --addr :8181 --log-level debug --disable-telemetry /mnt/policies
                env:
                - name: GR11_04_ORG_ID
                  value: "${ORG_ID}"
                - name: GR01_03_ORG_ADMIN_GROUP_EMAIL
                  value: "${ORG_ADMIN_GROUP_EMAIL}"
                - name: GR02_01_ORG_ADMIN_GROUP_EMAIL
                  value: "${ORG_ADMIN_GROUP_EMAIL}"
                - name: GR01_06_PRIVILEGED_USERS
                  value: "${PRIVILEGED_USERS_LIST}"
                - name: GR01_06_REGULAR_USERS
                  value: "${REGULAR_USERS_LIST}"
                - name: GR02_01_PRIVILEGED_USERS
                  value: "${PRIVILEGED_USERS_LIST}"
                - name: GR02_01_REGULAR_USERS
                  value: "${REGULAR_USERS_LIST}"
                - name: GR02_08_ALLOWED_DOMAINS
                  value: "${ALLOWED_DOMAINS}"
                - name: GR02_08_DENY_DOMAINS
                  value: "${DENY_DOMAINS}"
                - name: GR02_09_HAS_GUEST_USERS
                  value: "${HAS_GUEST_USERS}"
                - name: GR02_10_HAS_GUEST_USERS
                  value: "${HAS_GUEST_USERS}"
                - name: GR03_01_HAS_FEDERATED_USERS
                  value: "${HAS_FEDERATED_USERS}"
                - name: GR03_01_CUSTOMER_IDS
                  value: "${CUSTOMER_IDS}"
                - name: GR03_01_ALLOWED_CIDRS
                  value: "${ALLOWED_IPS}"
                - name: GR05_01_SECURITY_CATEGORY_KEY
                  value: "${SECURITY_CATEGORY_KEY}"
                - name: GR07_03_ALLOWED_CA_ISSUERS
                  value: "${CA_ISSUERS}"
                - name: GR13_02_BREAKGLASS_USER_EMAIL
                  value: "${BREAKGLASS_USER_EMAIL}"
                - name: GR13_03_BREAKGLASS_USER_EMAIL
                  value: "${BREAKGLASS_USER_EMAIL}"
                resources:
                  limits:
                    cpu: 1000m
                    memory: 2Gi
                volumeMounts:
                - name: policies
                  mountPath: /mnt/policies
                startupProbe:
                  initialDelaySeconds: 30
                  timeoutSeconds: 10
                  periodSeconds: 10
                  failureThreshold: 5
                  httpGet:
                    path: /
                    port: 8181
              volumes:
              - name: policies
                emptyDir:
                  medium: Memory
                  sizeLimit: 512Mi
          traffic:
          - percent: 100
            latestRevision: true
EOF

  # a buffer so google is ready for subsequent call

  gcloud --impersonate-service-account=${SERVICE_ACCOUNT} \
    run services replace cloudrun.yaml \
    >>$LOG_FILE 2>&1
  
  if [ ${BIN_AUTH_ENABLED:-"false"} = "true" ]; then
    gcloud --impersonate-service-account=${SERVICE_ACCOUNT} \
      run services update ${CLOUD_RUN} \
      --binary-authorization=default \
      --region ${REGION} \
      >>$LOG_FILE 2>&1
  fi
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

config_init

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
