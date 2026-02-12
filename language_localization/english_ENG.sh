LANG_SUCCESS="[SUCCESS]"
LANG_FAILURE="[FAILURE]"
LANG_PREFLIGHT_FAILED_EXITING="Preflight check failed. Exiting."
LANG_GCLOUD_NOT_INSTALLED="gcloud CLI is not installed. Please install it and try again."
LANG_GCLOUD_INSTALLED="gcloud CLI is installed."
LANG_NO_PROJECT_SET="No GCP project is set. Please set a project name with 'export PROJECT_ID=your-project-name' and try again."
LANG_PROJECT_SET="GCP project is set to"
LANG_GCLOUD_AUTH_OK="gcloud authentication is successful."
LANG_GCLOUD_AUTH_FAIL="gcloud authentication failed."
LANG_OWNER_ROLE_PRESENT="User has owner role, skipping individual role checks."
LANG_MISSING_ROLE="Missing required role:"
LANG_MISSING_ROLE_SUFFIX="Please ensure you have the necessary permissions."
LANG_ROLE_PRESENT="Required role is present:"
LANG_GCS_PERMISSIONS_OK="You have permissions to create GCS buckets in the project."
LANG_GCS_PERMISSIONS_FAIL="You do not have permissions to create GCS buckets in the project. Please ensure you have the necessary permissions."
LANG_COMPLETION_BANNER="┌───────────────────────────────────────────────────────┐\n│                                                       │\n│   CaC Environment Preparation Completed Successfully  │\n│                                                       │\n└───────────────────────────────────────────────────────┘"
LANG_SERVICE_ACCOUNT_INFO="  Service Account Information for SSC:"
LANG_COMPLIANCE_TOOL_SA="  Compliance Tool Service Account: "
LANG_CLOUD_RUN_ROBOT_ACCOUNT="  Cloud Run Robot Account:          "
LANG_STORAGE_TRANSFER_ROBOT_ACCOUNT="  Storage Transfer Robot Account:   "
LANG_BINARY_AUTH_ROBOT_ACCOUNT="  Binary Auth Robot Account:        "
LANG_ENABLING_SERVICE="Enabling Service:"
LANG_COULD_NOT_ENABLE_SERVICE="Could not enable"
LANG_CONFIGURING_ROLE="Configuring Role:"
LANG_FAILED_CREATE_OR_UPDATE_ROLE="Failed to create or update role"
LANG_GRANTING_ROLE="Granting Role:"
LANG_FAILED_GRANT_ROLE="Failed to grant role"
LANG_GRANTING_CUSTOM_ROLE="Granting Custom Role:"
LANG_FAILED_GRANT_CUSTOM_ROLE="Failed to grant custom role"
LANG_GRANTING_ORG_ROLE="Granting Org Role:"
LANG_FAILED_GRANT_ORG_ROLE="Failed to grant organization role. Check your permissions on Org ID:"
LANG_CREATING_IDENTITY_FOR="Creating Identity for:"
LANG_COULD_NOT_CREATE_IDENTITY_FOR="Could not create identity for"
LANG_GRANTING_STORAGE_VIEWER_TO_TRANSFER_SERVICE="Granting Storage Viewer to Transfer Service"
LANG_FAILED_GRANT_ROLE_TO_TRANSFER_SERVICE_AGENT="Failed to grant role to Storage Transfer Service agent."
LANG_GRANTING_CUSTOM_STORAGE_ROLE_TO_ASSET_SERVICE="Granting Custom Storage Role to Cloud Asset Service"
LANG_FAILED_GRANT_CUSTOM_ROLE_TO_ASSET_AGENT="Failed to grant custom role to Cloud Asset agent."
LANG_CREATING_GCS_BUCKET="Creating GCS Bucket:"
LANG_FAILED_CREATE_GCS_BUCKET="Failed to create GCS bucket"
LANG_UPLOADING_SERVICE_ACCOUNT_INFO="Uploading Service Account Information to GCS Bucket"
LANG_FAILED_UPLOAD_SERVICE_ACCOUNT_INFO="Failed to upload service account information to GCS bucket. Check if the bucket exists and that you have permissions to write to it."
LANG_PROJECT_ID_VERIFIED="Project ID verified successfully:"
LANG_PROJECT_NUMBER_VERIFIED="Project Number verified successfully:"
LANG_BILLING_ENABLED="Billing is enabled for"
LANG_ORG_ID_VERIFIED="Organization ID verified successfully:"
LANG_REMOVING_LEGACY_ROLE="Removing legacy role:"
LANG_COULD_NOT_REMOVE_ROLE="Could not remove role"
LANG_CHECKING_PREREQS="INFO: Checking prerequisites..."
LANG_VERIFYING_PROJECT_ID="INFO: Verifying Project ID..."
LANG_FETCHING_PROJECT_NUMBER="INFO: Fetching Project Number..."
LANG_CHECKING_BILLING_STATUS="INFO: Checking Billing Status for Project ID: $PROJECT_ID"
LANG_VERIFYING_ORG_ID="INFO: Verifying Organization ID..."
LANG_CREATING_LOG_FILES="INFO: Creating Log Files..."
LANG_SETTING_UP_CUSTOM_ROLES="Setting up Custom Roles..."
LANG_CLEANING_UP_LEGACY_ROLES="Cleaning up legacy roles..."
LANG_GRANTING_PROJECT_ROLES="Granting Project Roles..."
LANG_GRANTING_CUSTOM_ROLES="Granting Custom Roles..."
LANG_GRANTING_ORG_ROLES="Granting Organization Roles..."
LANG_GCS_BUCKET_EXISTS="GCS bucket already exists. Skipping creation."
LANG_GRANTING_ROLES_TO_SERVICE_IDENTITIES="Granting Roles to Google Service Identities..."
LANG_CHECKING_GCLOUD_INSTALLATION="INFO: Checking gcloud installation..."
LANG_CHECKING_GCLOUD_AUTH="INFO: Checking gcloud authentication..."
LANG_CHECKING_GCLOUD_IAM="INFO: Checking gcloud IAM..."
LANG_ERROR="$(date) [ERROR] Invalid input. Please select an appropriate option"
PROMPT="
Please confirm by re-entering the name:
>"

LANG_SETUP_PROMPT="
################################################################################
##            Gathering Required Information                                  ##
################################################################################

"
LANG_VALIDATION_PROMPT="
################################################################################
##            Validating Required Information                                 ##
################################################################################

"

LANG_DEPLOYMENT_PROMPT="
################################################################################
##           Starting CaC Tool Deployment                                     ##
################################################################################

"

LANG_APIS="

INFO: Enabling Required Project Services: Cloud Run, Cloud Storage and Cloud Scheduler"

LANG_SA_SETUP="

INFO: Creating CaC Service account and adding permissions"

LANG_SI_CREATE="

INFO: Creating Google Service Identities
"

LANG_ORG_ID="
Please enter the numeric GCP Organization ID:
>"
LANG_ORG_NAME="
Please enter the Organization Name:
>"
LANG_GC_PROFILE="
Please enter the Organization's Cloud Usage Profile level (1-6):
>"
LANG_SERVICE_ACCOUNT="
Please enter the shortname of the service account to use for deployment:
>"

LANG_BUCKET="
Please enter the Google Cloud Storage Bucket URL:
>"

LANG_POLICY="
Please enter the URL of the Source Repository containing the Compliance Policies:
>"

LANG_PROJECT="is detected as the current project associated with gcloud 
cli, press ENTER to continue using this project or enter a different project name:
>"

LANG_REGION="
Please select an installation region: 
1) northamerica-northeast1 (Canada - Montréal)
2) northamerica-northeast2 (Canada - Toronto)
>"

LANG_CONFIG_PROMPT="

INFO: Configuration file found, setup will use the values to proceed"


CONFIRM_PROJECT="

INFO: CaC tool will be deployed into the project: "

CONFIRM_REGION="

INFO: CaC tool will be deployed into the region: "

CONFIRM_SERVICE_ACCOUNT="

INFO: CaC tool will be deployed using the service account: "

SA_POLICY_ERROR="

WARNING: Service account permissions are over-provisioned

"
SA_CURRENT_POLICY="

Current Permissions are:

"
SA_REQUIRED_POLICY="

Required Permissions are:

"
SA_ERROR="
ERROR: Service Account not found. Please verify and retry"

BINDING_PROMPT="
INFO: Binding Service account to principal user...
"
ROLE_VALIDATION_PROMPT="
INFO: Verifying Service Account Access and Permissions
"
ROLES_VALIDATION="Role correctly assigned to: 
"
ROLES_VALIDATION_SUCCESS="
INFO: Validated required roles for Service Account
"
ROLES_VALIDATION_ERROR="
ERROR: Service account is missing the following roles:
"
POLICY_CONFIRMATION="
Are you sure you want to continue? (y/n)
>"

POLICY_CONTINUE="
INFO: Continuing deployment
"
POLICY_EXIT="
Exiting deployment"


LANG_CAC_IMAGE="Enter the image to use: 
>"
LANG_CAC_OPA_IMAGE="Enter the OPA image to use: 
>"
CREATE_BUCKET="
INFO: Creating guardrail compliance hub bucket...
"
CONFIG_BUCKET="
INFO: Setting storage class and versioning configurations...
"
CREATE_FOLDERS="
INFO: Creating guardrail directories in the background...
"
CREATE_CRUN="
INFO: Creating Cloud Run service in the background...
"
CREATE_CSCHEDULER="
INFO: Creating Cloud Scheduler...
"
COMPLETED="
SUCCESS: CaC Tool deployment completed
"

