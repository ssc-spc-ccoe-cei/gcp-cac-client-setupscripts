#!/bin/bash

LOG_FILE="deployment-setup.log"
OUTPUT_FILE="service-account-info.log"
DATE=$(date)

# Stop script on error
set -o errexit
# Stop script on pipeline failure
set -o pipefail
# Stop script on unset var
set -o nounset

# Function to handle unexpected errors
function error_handler() {
  echo "Error: An error occurred in the script. Please check the logs for more details." >&2
  exit 1
}

# Trap errors and call the error handler
trap 'error_handler' ERR

# Function to print success message
function print_success {
  tput setaf 2 
  echo "[SUCCESS]"
  tput sgr0 
}

# Function to print error message
function print_error {
  local error_msg="$1"
  tput setaf 1 
  echo "[FAILED]" >&2
  echo -e "\nERROR: ${error_msg}" >&2
  
  # Only show logs if the file actually exists and has content
  if [ -s "$LOG_FILE" ]; then
    echo -e "\n--- Last 5 lines of technical error logs ---" >&2
    tail -n 5 "$LOG_FILE" >&2 
    echo -e "--------------------------------------------\n" >&2
  fi
  
  tput sgr0
}

# Function to show progress
function show_progress() {
  # Grabs the Process ID (PID) of the background command
  local pid=$1
  local spin='-\|/'
  local i=0

  # Hide the cursor
  tput civis
  
# Check if process is running using 'kill -0'
  while kill -0 $pid 2>/dev/null; do
      
      # Cycle i from 0 to 3
      i=$(( (i+1) % 4 ))
      
      # Print character using substring extraction
      printf "[%s]" "${spin:$i:1}"
      
      # Backspace 3 times to return to the start of the brackets
      printf "\b\b\b"
      sleep 0.1
    done
  
  # Restore the cursor
  tput cnorm
}

# Wrapper function to run commands and show more detailed progress and logs
function run_command() {
  
  # Grab command to run, and processing + error messages as input
  local command="$1"
  local processing_msg="$2"
  local error_msg="$3"
  
  echo -n "➜ ${processing_msg}..."

  # Run command in background
  eval "$command" >> "$LOG_FILE" 2>&1 &
  local pid=$!
  
  # Run the loading progress animation
  show_progress $pid
  
  # Wait for command to finish
  local status=0
  
  # Report on status code
  if wait $pid; then
      status=0
  else
      status=$?
  fi
  # -----------------------

  if [ $status -eq 0 ]; then
    print_success
  else
    print_error "$error_msg"
    return 1
  fi
}

function input_language {
  ## Allows user to set preferred install language.
  read -p " 
┌───────────────────────────────────────────────────┐
│                                                   │
│          Compliance as Code Prep Script           │
│                                                   │
└───────────────────────────────────────────────────┘

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
  echo ""
  echo "INFO: Initializing Configuration..."
  
  echo -n "➜ Initializing Log File... "
  sleep 0.3
  if ! echo "--- Log Started: $DATE ---" > "$LOG_FILE"; then
    print_error "Failed to create log file."
    exit 1
  else
    print_success
  fi

  echo -n "➜ Initializing Service Account Information File..."
  sleep 0.3
  if ! echo "--- Output Started: $DATE ---" > "$OUTPUT_FILE"; then
    print_error "Failed to create service account information file."
    exit 1
  else
    print_success
  fi
  
}

function validate_prereqs {

  #echo $LANG_SETUP_PROMPT
  echo ""
  echo "INFO: Checking prerequisites..."
    
  echo -n "➜ Verifying Project ID... "
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  
  # Check if PROJECT_ID is empty
  if [[ -z "$PROJECT_ID" ]]; then
    print_error "No Google Cloud Project set. Run: gcloud config set project <id>"
    exit 1
  else
    print_success
  fi
  
  # Set and check project number
  echo -n "➜ Fetching Project Number... "
  if ! PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)" 2>/dev/null); then
    print_error "Could not verify Project Number."
    exit 1
  else
    print_success
  fi
  
  # Check if billing is enabled on project
  echo -n "➜ Verifying Billing Status... "
  BILLING_ENABLED=$(gcloud beta billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null)
  
  if [[ "$BILLING_ENABLED" != "True" ]]; then
    print_error "Billing is NOT enabled for $PROJECT_ID."
    exit 1
  else
    print_success
  fi
  
  # Set and check organization ID
  echo -n "➜ Verifying Organization ID... "
  ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID --format="value(id,type)" | grep "organization" | cut -f1)
  
  if [[ -z "$ORG_ID" ]]; then
    print_error "Could not verify Organization ID."
    exit 1
    else
      print_success
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
  
  echo "$LANG_APIS"
  for service in ${PROJECT_APIS[@]}; do
      run_command \
        "gcloud services enable $service.googleapis.com --project=$PROJECT_ID" \
        "Enabling Service: $service" \
        "Could not enable $service."
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
  
  # If create failed, try to update
  if gcloud iam roles update $role_id --project=$PROJECT_ID --file=$role_yaml --quiet; then
    return 0
  fi
  
  # If both failed return error code 1
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
  echo ""
  echo "Setting up Custom Roles..." 

  for role_file in ${CUSTOM_PROJECT_ROLES_FILES[@]}; do
    # Replace hyphens with underscores
    role_id="${role_file//-/_}"
    role_yaml="$CUSTOM_ROLES_DIR/${role_file}.yaml"
    
    # Need helper function to add roles
    # Otherwise will fail if it already exists
    run_command \
      "deploy_single_role $role_id $role_yaml" \
      "Configuring Role: $role_id" \
      "Failed to create or update role $role_id"
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
  
  echo "$LANG_SA_SETUP"
  
  # Need helper function to create service account
  # Otherwise will fail if it already exists
  run_command \
    "create_service_account ${SERVICE_ACCOUNT} 'CaC Solution Service Account'" \
    "Creating Service Account: $SERVICE_ACCOUNT" \
    "Could not create Service Account: $SERVICE_ACCOUNT."
  

  echo ""
  echo "Cleaning up legacy roles..."
  for role in "${OLD_PROJECT_ROLES[@]}"; do
    # Suppress error if role does not exist
    run_command \
      "gcloud projects remove-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${SERVICE_ACCOUNT}@$PROJECT_ID.iam.gserviceaccount.com --role=roles/${role} --quiet || true" \
      "Removing legacy role: $role" \
      "Could not remove role $role."
  done

  echo ""
  echo "Granting Project Roles..."
  for role in ${PROJECT_ROLES[@]}; do
    run_command \
      "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --role=roles/${role}" \
      "Granting Role: $role" \
      "Failed to grant role $role."
  done

  echo ""
  echo "Granting Custom Roles..."
  for role in ${CUSTOM_PROJECT_ROLES[@]}; do
  
    local role_name=${role##*/}
    
    run_command \
      "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --role=${role}" \
      "Granting Custom Role: $role_name" \
      "Failed to grant custom role $role."
  done
  
  echo ""
  echo "Granting Organization Roles..."
  for role in ${ORG_ROLES[@]}; do
    run_command \
      "gcloud organizations add-iam-policy-binding $ORG_ID --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --condition=None --role=roles/${role}" \
      "Granting Org Role: $role" \
      "Failed to grant organization role $role. Check your permissions on Org ID $ORG_ID."
  done
}

function service_identities_create {

  SERVICE_APIS=(
    "run" 
    "storagetransfer" 
    "cloudasset"
  )
    
  echo "$LANG_SI_CREATE"
  
  for api in ${SERVICE_APIS[@]}; do
    run_command \
      "gcloud beta services identity create --service ${api}.googleapis.com --project=$PROJECT_ID" \
      "Creating Identity for: $api" \
      "Could not create identity for $api."
  done

  #echo "$LANG_SI_CREATE"
  echo ""
  echo "Granting Roles to Google Service Identities..."

  local STS_SA="project-$PROJECT_NUMBER@storage-transfer-service.iam.gserviceaccount.com"
  
  run_command \
    "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${STS_SA} --role=roles/storage.objectViewer" \
    "Granting Storage Viewer to Transfer Service" \
    "Failed to grant role to Storage Transfer Service agent."

  local ASSET_SA="service-$PROJECT_NUMBER@gcp-sa-cloudasset.iam.gserviceaccount.com"
  
  run_command \
    "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${ASSET_SA} --role=projects/$PROJECT_ID/roles/cac_storage_object_role" \
    "Granting Custom Storage Role to Cloud Asset Service" \
    "Failed to grant custom role to Cloud Asset agent."

}

function print_completion {

  local main_sa="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
  local run_sa="service-${PROJECT_NUMBER}@serverless-robot-prod.iam.gserviceaccount.com"
  local storage_sa="project-${PROJECT_NUMBER}@storage-transfer-service.iam.gserviceaccount.com"
  local binauth_sa="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

  # Print to screen and file simultaneously
  cat <<EOF | tee -a "$OUTPUT_FILE"
  
┌───────────────────────────────────────────────────────┐
│                                                       │
│   CaC Environment Preparation Completed Successfully  │
│                                                       │
└───────────────────────────────────────────────────────┘

  Service Account Information for SSC:
  
  Compliance Tool Service Account:  $main_sa
  Cloud Run Robot Account:          $run_sa
  Storage Transfer Robot Account:   $storage_sa
  Binary Auth Robot Account:        $binauth_sa
EOF
}

input_language
config_init
validate_prereqs
enable_apis
create_custom_project_roles
service_account_setup
service_identities_create
print_completion
