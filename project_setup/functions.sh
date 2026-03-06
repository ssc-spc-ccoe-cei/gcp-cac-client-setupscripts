#!/bin/sh

# Import shared functions
source ../shared_functions/common_functions.sh

function logging_init {
  log_info "$LANG_CREATING_LOG_FILES"

  if ! echo "[INFO] --- Log Started ---" > "$LOG_FILE"; then
    print_error "[ERROR] Failed to create log file."
    exit 1
  else
    print_success "Log files created successfully."
  fi
}

function validate_prereqs {

  log_info "$LANG_CHECKING_PREREQS"

  # Check the gcloud is installed
  log_info "$LANG_CHECKING_GCLOUD_INSTALLATION"
  if ! command -v gcloud &> /dev/null; then
      print_error "$LANG_GCLOUD_NOT_INSTALLED"
      exit 1
  else
      print_success "$LANG_GCLOUD_INSTALLED"
  fi

  # Check if PROJECT_ID is set
  log_info "$LANG_VERIFYING_PROJECT_ID"
  if [[ -z "$PROJECT_ID" ]]; then   # Check if PROJECT_ID is empty
    print_error "$LANG_ERROR_NO_PROJECT_ID"
    exit 1
  else
    print_success "$LANG_PROJECT_ID_VERIFIED $PROJECT_ID"
  fi

  # Set and check project number
  log_info "$LANG_FETCHING_PROJECT_NUMBER"
  if ! PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)" 2>/dev/null); then
    print_error "$LANG_ERROR_PROJECT_NUMBER"
    exit 1
  else
    print_success "$LANG_PROJECT_NUMBER_VERIFIED $PROJECT_NUMBER"
  fi

  # Attempt to get the current authenticated account using gcloud
  log_info "$LANG_CHECKING_GCLOUD_AUTH"
  local ACCOUNT
  ACCOUNT=$(gcloud config get-value account 2>/dev/null)

  if [ -n "$ACCOUNT" ]; then
      print_success "$LANG_GCLOUD_AUTH_OK: $ACCOUNT"
  else
      print_error "$LANG_GCLOUD_AUTH_FAIL" 1
      exit 1
  fi

  # # Check project permissions for logged in user
  # log_info "$LANG_CHECKING_GCLOUD_IAM"
  # local required_roles=(
  #     "roles/iam.roleAdmin"
  #     "roles/serviceusage.serviceUsageAdmin"
  #     "roles/iam.serviceAccountAdmin"
  # )

  # MEMBER="user:$ACCOUNT"

  # USER_ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --filter="bindings.members:$MEMBER" --format="value(bindings.role)")

  # if echo "$USER_ROLES" | grep -qFx "roles/owner"; then
  #     print_success "$LANG_OWNER_ROLE_PRESENT"
  # else
  #   for role in "${required_roles[@]}"; do
  #       if echo "$USER_ROLES" | grep -qFx "$role"; then
  #           print_success "$LANG_ROLE_PRESENT $role"
  #       else
  #           print_error "$LANG_MISSING_ROLE $role $LANG_MISSING_ROLE_SUFFIX"
  #           exit 1
  #       fi
  #   done
  # fi

  # Check if billing is enabled on project
  log_info "$LANG_CHECKING_BILLING_STATUS"
  BILLING_ENABLED=$(gcloud beta billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null)

  if [[ "$BILLING_ENABLED" != "True" ]]; then
    print_error "$LANG_ERROR_BILLING_NOT_ENABLED $PROJECT_ID."
    exit 1
  else
    print_success "$LANG_BILLING_ENABLED $PROJECT_ID."
  fi

  # Set and check organization ID
  log_info "$LANG_VERIFYING_ORG_ID"
  ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID --format="value(id,type)" | grep "organization" | cut -f1)

  if [[ -z "$ORG_ID" ]]; then
    print_error "$LANG_ERROR_ORG_ID"
    exit 1
    else
      print_success "$LANG_ORG_ID_VERIFIED $ORG_ID"
    fi
  }

function enable_apis {

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

  log_info "$LANG_APIS"
  for service in ${PROJECT_APIS[@]}; do
      run_command \
        "gcloud services enable $service.googleapis.com --project=$PROJECT_ID" \
        "$LANG_ENABLING_SERVICE $service" \
        "$LANG_COULD_NOT_ENABLE_SERVICE $service."
    done
}

function deploy_single_role {

  # Grab role ID as input
  local role_id=$1

  # Grab role YAML path as input
  local role_yaml=$2

  # Try to create
  if gcloud iam roles create $role_id --project=$PROJECT_ID --file=$role_yaml --quiet; then
    return 0
  fi

  # Check if the role is in a deleted state
  local role_info=$(gcloud iam roles describe $role_id --project=$PROJECT_ID --format="get(deleted)" 2>/dev/null)
  if [ "$role_info" = "True" ]; then
    # Undelete the role
    if gcloud iam roles undelete $role_id --project=$PROJECT_ID --quiet; then
      # After undeletion, update the role
      if gcloud iam roles update $role_id --project=$PROJECT_ID --file=$role_yaml --quiet; then
        return 0
      fi
    fi
  else
    # If not deleted, try to update
    if gcloud iam roles update $role_id --project=$PROJECT_ID --file=$role_yaml --quiet; then
      return 0
    fi
  fi

  # If all failed return error code 1
  return 1
}

function create_custom_project_roles {

  CUSTOM_ROLES_DIR="./custom_roles"

  CUSTOM_PROJECT_ROLES_FILES=(
    "cac-storage-role"
    "cac-storage-object-role"
    "cac-scheduler-role"
    "cac-run-role"
  )

  # echo "$PROJECT_ROLES"
  log_info "$LANG_SETTING_UP_CUSTOM_ROLES"

  for role_file in ${CUSTOM_PROJECT_ROLES_FILES[@]}; do
    # Replace hyphens with underscores
    role_id="${role_file//-/_}"
    role_yaml="$CUSTOM_ROLES_DIR/${role_file}.yaml"

    # Need helper function to add roles
    # Otherwise will fail if it already exists
    run_command \
      "deploy_single_role $role_id $role_yaml" \
      "$LANG_CONFIGURING_ROLE $role_id" \
      "$LANG_FAILED_CREATE_OR_UPDATE_ROLE $role_id"
  done
}

function create_service_account {

  # Grab service account name and describe as input
  local name=$1
  local desc=$2
  local email="${name}@${PROJECT_ID}.iam.gserviceaccount.com"

  # Check if service account exists
  if gcloud iam service-accounts describe "$email" --project="$PROJECT_ID" >/dev/null 2>&1; then
    return 0
  fi

  # Create service account if it doesn't exist
  gcloud iam service-accounts create "$name" --description="$desc" --project="$PROJECT_ID" --quiet
}

function service_account_setup {

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

  ORG_ROLES=(
    "securitycenter.adminViewer"
    "logging.viewer"
    "cloudasset.viewer"
    "essentialcontacts.viewer"
    "certificatemanager.viewer"
    "accesscontextmanager.policyReader"
    "accesscontextmanager.gcpAccessReader"
  )

  CUSTOM_PROJECT_ROLES=(
    "projects/$PROJECT_ID/roles/cac_storage_role"
    "projects/$PROJECT_ID/roles/cac_scheduler_role"
    "projects/$PROJECT_ID/roles/cac_run_role"
  )

  SERVICE_ACCOUNT="cac-solution-${ORG_ID}-sa"

  log_info "$LANG_SA_SETUP"

  # Need helper function to create service account
  # Otherwise will fail if it already exists
  run_command \
    "create_service_account ${SERVICE_ACCOUNT} '$LANG_SA_DESCRIPTION'" \
    "$LANG_CREATING_SA $SERVICE_ACCOUNT" \
    "$LANG_ERROR_CREATING_SA $SERVICE_ACCOUNT."

  log_info "$LANG_CLEANING_UP_LEGACY_ROLES"
  for role in "${OLD_PROJECT_ROLES[@]}"; do
    # Suppress error if role does not exist
    run_command \
      "gcloud projects remove-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${SERVICE_ACCOUNT}@$PROJECT_ID.iam.gserviceaccount.com --role=roles/${role} --quiet || true" \
      "$LANG_REMOVING_LEGACY_ROLE $role" \
      "$LANG_COULD_NOT_REMOVE_ROLE $role."
  done

  log_info "$LANG_GRANTING_PROJECT_ROLES"
  for role in ${PROJECT_ROLES[@]}; do
    run_command \
      "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --role=roles/${role}" \
      "$LANG_GRANTING_ROLE $role" \
      "$LANG_FAILED_GRANT_ROLE $role."
  done

  log_info "$LANG_GRANTING_CUSTOM_ROLES"
  for role in ${CUSTOM_PROJECT_ROLES[@]}; do

    local role_name=${role##*/}

    run_command \
      "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --role=${role}" \
      "$LANG_GRANTING_CUSTOM_ROLE $role_name" \
      "$LANG_FAILED_GRANT_CUSTOM_ROLE $role."
  done

  log_info "$LANG_GRANTING_ORG_ROLES"
  for role in ${ORG_ROLES[@]}; do
    run_command \
      "gcloud organizations add-iam-policy-binding $ORG_ID --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --condition=None --role=roles/${role}" \
      "$LANG_GRANTING_ORG_ROLE $role" \
      "$LANG_FAILED_GRANT_ORG_ROLE $role $ORG_ID."
  done
}

function service_identities_create {

  SERVICE_APIS=(
    "run"
    "storagetransfer"
    "cloudasset"
  )

  log_info "$LANG_SI_CREATE"

  for api in ${SERVICE_APIS[@]}; do
    run_command \
      "gcloud beta services identity create --service ${api}.googleapis.com --project=$PROJECT_ID" \
      "$LANG_CREATING_IDENTITY_FOR $api" \
      "$LANG_COULD_NOT_CREATE_IDENTITY_FOR $api."
  done

  log_info "$LANG_GRANTING_ROLES_TO_SERVICE_IDENTITIES"

  local STS_SA="project-$PROJECT_NUMBER@storage-transfer-service.iam.gserviceaccount.com"

  run_command \
    "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${STS_SA} --role=roles/storage.objectViewer" \
    "$LANG_GRANTING_STORAGE_VIEWER_TO_TRANSFER_SERVICE" \
    "$LANG_FAILED_GRANT_ROLE_TO_TRANSFER_SERVICE_AGENT"

  local ASSET_SA="service-$PROJECT_NUMBER@gcp-sa-cloudasset.iam.gserviceaccount.com"

  run_command \
    "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${ASSET_SA} --role=projects/$PROJECT_ID/roles/cac_storage_object_role" \
    "$LANG_GRANTING_CUSTOM_STORAGE_ROLE_TO_ASSET_SERVICE" \
    "$LANG_FAILED_GRANT_CUSTOM_ROLE_TO_ASSET_AGENT"

}

function print_completion {

  local main_sa="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
  local run_sa="service-${PROJECT_NUMBER}@serverless-robot-prod.iam.gserviceaccount.com"
  local storage_sa="project-${PROJECT_NUMBER}@storage-transfer-service.iam.gserviceaccount.com"
  local binauth_sa="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

  # Create JSON object
  local json_output=$(printf '{
    "compliance_tool_sa": "%s",
    "cloud_run_robot_account": "%s",
    "storage_transfer_robot_account": "%s",
    "binary_auth_robot_account": "%s"
  }' "$main_sa" "$run_sa" "$storage_sa" "$binauth_sa")

  # Save JSON to a file
  echo "$json_output" > service_accounts.json

  # Print to screen and file simultaneously
  {
    echo ""
    echo -e "$LANG_COMPLETION_BANNER"
    echo ""
    echo "$LANG_SERVICE_ACCOUNT_INFO"
    echo ""
    echo "$LANG_COMPLIANCE_TOOL_SA $main_sa"
    echo "$LANG_CLOUD_RUN_ROBOT_ACCOUNT $run_sa"
    echo "$LANG_STORAGE_TRANSFER_ROBOT_ACCOUNT $storage_sa"
    echo "$LANG_BINARY_AUTH_ROBOT_ACCOUNT $binauth_sa"
  } | tee -a "$OUTPUT_FILE"
}
