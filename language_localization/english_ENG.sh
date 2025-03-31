LANG_ERROR="ERROR: Invalid input. Please select an appropriate option"
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
