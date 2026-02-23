#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" # set working directory to collector_setup

mkdir -p logs # Ensure logs directory exists

LOG_FILE="logs/$(date +%Y%m%d_%H%M%S)-deployment-setup.log"
PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"

set -eo pipefail

. ./functions.sh # source functions from other file here

trap 'error_handler' ERR

input_language
logging_init
config_init
service_account
storage_bucket
cloudrun_service
prompt_store_variables_to_gcs
print_completion