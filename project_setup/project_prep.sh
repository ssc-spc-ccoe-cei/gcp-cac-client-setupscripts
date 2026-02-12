#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Determine script directory
cd "$SCRIPT_DIR" # set working directory to project_setup

mkdir -p logs # Ensure logs directory exists

LOG_FILE="logs/$(date +%Y%m%d_%H%M%S)-deployment-setup.log"
OUTPUT_FILE="credentials.txt"
PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"

set -eo pipefail

. ./functions.sh # source functions from other file here

trap 'error_handler' ERR

input_language              # Allows user to set preferred install language.
logging_init                # Initializes log and output files
validate_prereqs            # Validates prerequisites for access and environment variables
enable_apis                 # Enables required APIs for the project
create_custom_project_roles # Creates custom roles for the project
service_account_setup       # Creates service account and keys, grants permissions
service_identities_create   # Creates service identities for required services and grants them permissions
print_completion            # Prints completion message and location of output file
