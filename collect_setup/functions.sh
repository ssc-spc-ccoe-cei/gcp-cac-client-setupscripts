#!/bin/bash

## declare an array of roles
declare -a ROLES=(
    "roles/iam.workloadIdentityUser"
    "roles/iam.serviceAccountUser"
    "roles/run.invoker"
    "roles/run.serviceAgent"
    "roles/cloudasset.viewer"
    "roles/logging.viewer"
    "roles/securitycenter.adminViewer"
    "projects/$PROJECT_ID/roles/cac_storage_role" #storage.admin
    "projects/$PROJECT_ID/roles/cac_scheduler_role"  #cloudscheduler.admin
    "projects/$PROJECT_ID/roles/cac_run_role" #run.developer
)


ROLE_COUNT=$(echo "${ROLES[@]}" | wc -w)
# Declare cloud run service name
CLOUD_RUN="compliance-analysis"
SCHEDULE="0 0 * * *"
LOG_LEVEL="INFO"
DATE=$(date)


# Import shared functions
source ../shared_functions/common_functions.sh

function logging_init {
  log_info "$LANG_CREATING_LOG_FILES"

  if ! echo "[INFO] --- Log Started ---" > "$LOG_FILE"; then
    print_error "$LANG_ERROR_CREATE_LOG"
    exit 1
  else
    print_success "$LANG_LOG_CREATED"
  fi
}

function config_init {

  log_info "$LANG_CHECKING_VARIABLES"

  REQUIRED_VARIABLES=(
      "PROJECT_ID"
      "SERVICE_ACCOUNT"
      "ORG_NAME"
      "ORG_ID"
      "GC_PROFILE"
      "SECURITY_CATEGORY_KEY"
      "PRIVILEGED_USERS_LIST"
      "REGULAR_USERS_LIST"
      "ALLOWED_DOMAINS"
      "DENY_DOMAINS"
      "HAS_GUEST_USERS"
      "HAS_FEDERATED_USERS"
      "ALLOWED_IPS"
      "CUSTOMER_IDS"
      "CA_ISSUERS"
      "ORG_ADMIN_GROUP_EMAIL"
      "BREAKGLASS_USER_EMAILS"
      "POLICY_REPO"
      "OPA_IMAGE"
      "REGION"
  )

  MISSING_VARS=()

  for setting in "${REQUIRED_VARIABLES[@]}"; do
    if [[ "$setting" == "ALLOWED_IPS" && $HAS_FEDERATED_USERS == "true" ]]; then
      continue
    fi

    if [ -z "${!setting}" ]; then
      MISSING_VARS+=("$setting")
    fi
  done

  if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    print_error "$LANG_ERROR_MISSING_VARS [${MISSING_VARS[*]}]. Please set these in the collector_config file."
    exit 1
  fi

  PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)" 2>&1)
  ACCOUNT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)" 2>&1)
  JOB_NAME="compliance-analysis-automation-$(echo "${ACCOUNT_NUMBER}" | tr '[:upper:]' '[:lower:]')"
  BUCKET_NAME="compliance-hub-"$(echo ${ACCOUNT_NUMBER} | tr '[:upper:]' '[:lower:]')
  CONFIG_BACKUP_BUCKET_NAME="collector-config-backup-"$(echo ${ACCOUNT_NUMBER} | tr '[:upper:]' '[:lower:]')
  CONFIG_FILE="collector_config.txt"

  print_success "$LANG_CONFIG_INITIALIZED"

}

function service_account {
  log_info "$LANG_CONFIGURING_SA"

  run_command \
    "gcloud iam service-accounts describe \"${SERVICE_ACCOUNT}\"" \
    "$LANG_CONFIRMING_SA $SERVICE_ACCOUNT" \
    "$LANG_ERROR_SA_NOT_EXIST $SERVICE_ACCOUNT"

  local current_user
  current_user=$(gcloud config list account --format 'value(core.account)' 2>/dev/null)

  run_command \
    "gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT --member=user:$current_user --role=roles/iam.serviceAccountTokenCreator" \
    "$LANG_BINDING_TOKEN_CREATOR" \
    "$LANG_ERROR_BINDING_TOKEN_CREATOR"

  run_command \
    "gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/storagetransfer.admin" \
    "$LANG_GRANTING_STORAGE_TRANSFER" \
    "$LANG_ERROR_GRANTING_STORAGE_TRANSFER $SERVICE_ACCOUNT"

}

function clean_up {
  find . -type d -name "guardrail-*" -exec rm -r {} +
  find . -type d -name "guardrail-*" -print | while read -r dir; do
    log_message "$LANG_LOG_DELETED_DIR $dir"
  done
}

function create_gcs_bucket {
  local bucket_name=$1
  local region=$2
  local service_account=$3
  local project_id=$4

  # Check if bucket exists
  if gcloud storage buckets describe "gs://$bucket_name" \
    --impersonate-service-account="$service_account" \
    --project "$project_id" \
    --verbosity=none >/dev/null 2>&1; then
    return 0
  fi

  clean_up

  # Create the bucket if it doesn't exist
  gcloud storage buckets create "gs://$bucket_name" \
    --location="$region" \
    --impersonate-service-account="$service_account" \
    --project="$project_id"
}

function create_transfer_job {
  local bucket_name="${1#gs://}"
  local ssc_bucket_name="${2#gs://}"
  local org_name=$3

  # Check if job exists
  if gcloud transfer jobs list --job-statuses=enabled --format="value(name)" | grep -q "nightly_compliance_transfer"; then
     return 0
  fi

  local run_hour="02:00:00-04:00"
  local ordinal=$((($RANDOM % 10 + 1)))
  local schedule_start=""

  if [[ "$(uname)" == "Darwin" ]]; then
      schedule_start=$(date -v+1d -u +"%Y-%m-%dT${run_hour}")
  else
      schedule_start=$(date -d "+1 day" -u +"%Y-%m-%dT${run_hour}")
  fi

  gcloud transfer jobs create "gs://${bucket_name}/" "gs://${ssc_bucket_name}/${org_name}/" \
      --name "nightly_compliance_transfer_${ordinal}" \
      --include-modified-after-relative=1d \
      --schedule-starts="$schedule_start" \
      --schedule-repeats-every=p1d \
      --verbosity=error
}

function storage_bucket {
  log_info "$LANG_CREATING_BUCKET $BUCKET_NAME"

  run_command \
    "create_gcs_bucket $BUCKET_NAME $REGION $SERVICE_ACCOUNT $PROJECT_ID" \
    "$LANG_CREATING_BUCKET gs://$BUCKET_NAME" \
    "$LANG_ERROR_CREATING_BUCKET gs://$BUCKET_NAME"

  run_command \
      "gcloud storage buckets update gs://$BUCKET_NAME --default-storage-class=STANDARD --impersonate-service-account=\"$SERVICE_ACCOUNT\" --verbosity=none" \
      "$LANG_SETTING_STORAGE_CLASS gs://$BUCKET_NAME" \
      "$LANG_ERROR_SETTING_STORAGE_CLASS gs://$BUCKET_NAME"

  # Set versioning for the bucket
  run_command \
      "gcloud storage buckets update gs://$BUCKET_NAME --versioning --impersonate-service-account=\"$SERVICE_ACCOUNT\" --verbosity=none" \
      "$LANG_ENABLING_VERSIONING gs://$BUCKET_NAME" \
      "$LANG_ERROR_ENABLING_VERSIONING gs://$BUCKET_NAME"

  # Create the directories
  FOLDER_COUNT=$(gcloud storage ls gs://$BUCKET_NAME --impersonate-service-account="$SERVICE_ACCOUNT" --verbosity=none | wc -l | tr -d '[:space:]')

  if [ $FOLDER_COUNT -lt 13 ]; then
    for i in {1..13}; do
      mkdir -p guardrail-$(printf "%02d" $i)
      echo "$LANG_INSTRUCTION_FILE_CONTENT" >guardrail-$(printf "%02d" $i)/instructions.txt

      run_command \
        "gcloud storage cp --recursive guardrail-$(printf "%02d" $i) gs://$BUCKET_NAME --impersonate-service-account=\"$SERVICE_ACCOUNT\" --verbosity=none" \
        "$LANG_UPLOADING_GUARDRAIL$(printf "%02d" $i)" \
        "$LANG_ERROR_UPLOADING_GUARDRAIL$(printf "%02d" $i)"

      rm -rf guardrail-$(printf "%02d" $i)
    done
  fi

  # Set the IAM policy for the bucket

  # gsutil doesn't allow setting IAM policies with custom roles - changed to gcloud command
  run_command \
    "gcloud storage buckets add-iam-policy-binding gs://${BUCKET_NAME} \
    --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-cloudasset.iam.gserviceaccount.com \
    --role=projects/$PROJECT_ID/roles/cac_storage_object_role \
    --impersonate-service-account=\"$SERVICE_ACCOUNT\" \
    --verbosity=none" \
    "$LANG_SETTING_IAM_POLICY" \
    "$LANG_ERROR_SETTING_IAM_POLICY"

    # Set up cloud storage transfer job
    run_command \
      "create_transfer_job $BUCKET_NAME $SSC_BUCKET_NAME $ORG_NAME" \
      "$LANG_CREATING_TRANSFER_JOB" \
      "$LANG_ERROR_CREATING_TRANSFER_JOB"
}

function create_cloud_scheduler {
  local scheduler_job_name=$1
  local service_url=$2

  # Check if job exists
  if gcloud scheduler jobs describe "$scheduler_job_name" \
    --impersonate-service-account="$SERVICE_ACCOUNT"\
    --location "$REGION" \
    --project "$PROJECT_ID" \
    --verbosity=none >/dev/null 2>&1; then
      return 0
  fi

  # Create the job if it doesn't exist
  gcloud scheduler jobs create http $scheduler_job_name \
    --impersonate-service-account=$SERVICE_ACCOUNT \
    --oidc-service-account-email=$SERVICE_ACCOUNT \
    --schedule "$SCHEDULE" \
    --location $REGION \
    --time-zone UTC \
    --project $PROJECT_ID \
    --description 'Compliance analysis automation' \
    --uri $service_url \
    --http-method=GET \
    --attempt-deadline=30m
}

function cloudrun_service {
  log_info "$LANG_CONFIGURING_CLOUD_RUN"

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
              timeoutSeconds: 3600
              serviceAccountName: ${SERVICE_ACCOUNT}
              containers:
              - name: cac-python-1
                image: ${REGION}-docker.pkg.dev/${BUILD_PROJECT_ID}/cac-python/cac-app:${IMAGE_TAG}
                imagePullPolicy: Always
                ports:
                - name: h2c
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
                  value: "${BUCKET_NAME}"
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
                - name: BREAKGLASS_USER_EMAILS
                  value: '${BREAKGLASS_USER_EMAILS}'
                resources:
                  limits:
                    cpu: 4000m
                    memory: 10Gi
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
                    /usr/bin/opa run --server --h2c --addr :8181 --log-level debug --disable-telemetry --set server.decoding.max_length=1073741824 --set server.decoding.gzip.max_length=1073741824 /mnt/policies
                env:
                - name: GC_PROFILE
                  value: "${GC_PROFILE}"
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
                - name: GR13_02_BREAKGLASS_USER_EMAILS
                  value: '${BREAKGLASS_USER_EMAILS}'
                - name: GR13_03_BREAKGLASS_USER_EMAILS
                  value: '${BREAKGLASS_USER_EMAILS}'
                resources:
                  limits:
                    cpu: 4000m
                    memory: 8Gi
                volumeMounts:
                - name: policies
                  mountPath: /mnt/policies
                startupProbe:
                  initialDelaySeconds: 30
                  timeoutSeconds: 120
                  periodSeconds: 240
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

  run_command \
    "gcloud --impersonate-service-account="${SERVICE_ACCOUNT}" run services replace cloudrun.yaml --region "$REGION"" \
    "$LANG_LOG_CLOUDRUN_DEPLOY" \
    "$LANG_ERROR_DEPLOYING_CLOUD_RUN"


  if [ "${BIN_AUTH_ENABLED:-false}" = "true" ]; then

    # Wait briefly to ensure the service is ready for update
    run_command \
        "sleep 15; gcloud --impersonate-service-account=\"${SERVICE_ACCOUNT}\" run services update \"${CLOUD_RUN}\" --binary-authorization=default --region \"$REGION\"" \
        "$LANG_ENABLING_BIN_AUTH" \
        "$LANG_ERROR_ENABLING_BIN_AUTH"
  fi

  CSERVICE_URL=$(gcloud --impersonate-service-account="$SERVICE_ACCOUNT" run services describe "$CLOUD_RUN" --format='value(status.url)' --region="$REGION" --verbosity=none)

  # Check if the Cloud Scheduler job already exists
  run_command \
    "create_cloud_scheduler ${JOB_NAME} ${CSERVICE_URL}" \
    "$LANG_CREATING_SCHEDULER $JOB_NAME" \
    "$LANG_ERROR_CREATING_SCHEDULER $JOB_NAME"
}

function prompt_store_variables_to_gcs() {
  log_newline
  local input
  while true; do
    read -p "$LANG_PROMPT_UPLOAD_CONFIG" input
    case $input in
      1)
        upload_variables_to_gcs
        break
        ;;
      0)
        echo "$LANG_SKIPPING_UPLOAD"
        break
        ;;
      *)
        echo "$LANG_ERROR_INVALID_YES_NO"
        ;;
    esac
  done
}

function generate_collector_config() {

  cat <<EOF > "$CONFIG_FILE"
  ###--------------------------------------
  # Python app.py deployment settings
  #----------------------------------------
  ### Azure Tenant Domain (if any)
  export TENANT_DOMAIN="${TENANT_DOMAIN}"
  ### GCP Organization Information
  export PROJECT_ID="${PROJECT_ID}"
  # Organization Name
  export ORG_NAME="${ORG_NAME}"
  # GC Cloud Usage Profile number
  export GC_PROFILE="${GC_PROFILE}"
  export GCP_PROJECT="${GCP_PROJECT}"
  ###--------------------------------------
  # Python app.py deployment settings
  #----------------------------------------
  # GR1.3
  export ORG_ADMIN_GROUP_EMAIL="${ORG_ADMIN_GROUP_EMAIL}"
  # GR5.1
  # Tag Key used to identify security classification of GCP resources
  # example: a GCS bucket can be identified as containing Protected "A" data by tagging it
  # DATA_CLASSIFICATION: Protected A
  export SECURITY_CATEGORY_KEY="${SECURITY_CATEGORY_KEY}"
  # GR1.6 & GR2.1
  # List of Privileged Users and their regular account names
  # Format: '(user:admin1@example.com,user:admin2@example.com,user:admin3@example.com)'
  export PRIVILEGED_USERS_LIST="${PRIVILEGED_USERS_LIST}"
  export REGULAR_USERS_LIST="${REGULAR_USERS_LIST}"
  # GR2.8
  # List of Domains that are allowed/denied to access the GCP environment
  # Format: 'domain1.com,domain2.ca'
  export ALLOWED_DOMAINS="${ALLOWED_DOMAINS}"
  export DENY_DOMAINS="${DENY_DOMAINS}"
  # GR2.9 & GR 2.10
  export HAS_GUEST_USERS="${HAS_GUEST_USERS}"
  # GR3.1
  export HAS_FEDERATED_USERS="${HAS_FEDERATED_USERS}"
  # GR3.1
  # List of IPs allowed to access the GCP environment
  # Format: 10.0.7.44,192.168.0.16
  # NOTE: this can also be left blank if HAS_FEDERATED_USERS="true"
  export ALLOWED_IPS="${ALLOWED_IPS}"
  # GR3.1
  # List of GCP Org and/or Workspace Customer IDs
  # i.e. CUSTOMER_IDS='C03xxxx4x,Abc123,XYZ890'
  export CUSTOMER_IDS="${CUSTOMER_IDS}"
  # GR7.3
  # List of Acceptable Certifcate Authorities
  # Format: "Let's Encrypt,Verisign"
  export CA_ISSUERS="${CA_ISSUERS}"
  # GCP Organization ID
  # run `gcloud organizations list` to find yours
  export ORG_ID="${ORG_ID}"
  #GR13.2 & GR13.3
  # breakglass user emails
  export BREAKGLASS_USER_EMAILS='${BREAKGLASS_USER_EMAILS}'
  ###--------------------------------------
  # Core deployment settings
  #----------------------------------------
  # setting you likely will NOT need to change
  export REGION="${REGION}"
  export APP_PORT="${APP_PORT}"
  export BIN_AUTH_ENABLED="${BIN_AUTH_ENABLED}"
  ###--------------------------------------
  # SSC Team will provide following information
  #----------------------------------------
  export POLICY_REPO="${POLICY_REPO}"
  export POLICY_PROJECT="${POLICY_PROJECT}"
  export BRANCH="${BRANCH}"
  export BUILD_PROJECT_ID="${BUILD_PROJECT_ID}"
  export IMAGE_TAG="${IMAGE_TAG}"
  export OPA_IMAGE="${OPA_IMAGE}"
  export POLICY_VERSION="${POLICY_VERSION}"
  export SERVICE_ACCOUNT="${SERVICE_ACCOUNT}"
  # (central) destination bucket for storage transfer requires the gs:// prefix
  export SSC_BUCKET_NAME="${SSC_BUCKET_NAME}"
EOF
}

function upload_variables_to_gcs() {

  # Create the collector config file
  run_command \
    "generate_collector_config" \
    "$LANG_CREATING_CONFIG_FILE" \
    "$LANG_ERROR_CREATING_CONFIG_FILE"

  # Create the bucket if it doesn't exist
  run_command \
    "create_gcs_bucket $CONFIG_BACKUP_BUCKET_NAME $REGION $SERVICE_ACCOUNT $PROJECT_ID" \
    "$LANG_CREATING_BACKUP_BUCKET gs://$CONFIG_BACKUP_BUCKET_NAME" \
    "$LANG_ERROR_CREATING_BACKUP_BUCKET gs://$CONFIG_BACKUP_BUCKET_NAME"

  # upload the file named $CONFIG_FILE to gcs if present in pwd
  if [ -f "$CONFIG_FILE" ]; then
    run_command \
      "gcloud storage cp \"$CONFIG_FILE\" gs://$CONFIG_BACKUP_BUCKET_NAME/$CONFIG_FILE --impersonate-service-account=\"$SERVICE_ACCOUNT\"" \
      "$LANG_UPLOADING_CONFIG gs://$CONFIG_BACKUP_BUCKET_NAME/$CONFIG_FILE" \
      "$LANG_ERROR_UPLOADING_CONFIG gs://$CONFIG_BACKUP_BUCKET_NAME/$CONFIG_FILE"
  else
    print_error "$LANG_ERROR_NO_CONFIG_FILE"
    exit 1
  fi
}

function print_completion {
echo -e "$LANG_COMPLETION_BANNER_COLLECTOR"
}
