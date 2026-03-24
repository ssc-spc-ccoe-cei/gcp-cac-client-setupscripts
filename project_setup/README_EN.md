# Google Cloud Project Preparation Script

This script prepares a Google Cloud project for the Compliance as Code (CaC) solution. It handles the configuration of APIs, custom IAM roles, and service accounts necessary for the script to function.

- [Purpose](#purpose)
- [Prerequisites \& Environment Variables](#prerequisites--environment-variables)
- [Setup](#setup)
- [Running the Script](#running-the-script)
- [changes \& next items](#changes--next-items)
  - [changes](#changes)


## Purpose

The main goal of this script is to automate the setup of a Google Cloud service account to perform the necessary compliance checks. This is what the files do:

```sh
.
├── clean.sh                          # clean up/remove all resources made for service account 
├── custom_roles                      # yaml files with custom role definitions
│   ├── cac-run-role.yaml             
│   ├── cac-scheduler-role.yaml
│   ├── cac-storage-object-role.yaml
│   └── cac-storage-role.yaml
├── functions.sh                      # script containing all the functions we need
├── logs                              # directory storing all logs
├── preflight.sh                      # pre-check script to test permissions, access required, PROJECT_ID
├── project_prep.sh                   # main script to create service account
├── README_EN.md                      # instructions in English
└── README_FR.md                      # instructions in French
```

## Prerequisites & Environment Variables

The `preflight.sh` script checks that prerequisistes are in place:

```sh
export PROJECT_ID="your-project-id"
cd gcp-cac-client-setupscripts/project_setup
./preflight.sh
```

If you receive an error here such as:
```sh
ERROR: (gcloud.the.resource.permission) HTTPError 403: your-username@domain.ca does not have the.resource.permission access to the Google Cloud project. Permission 'the.resource.permission' denied on resource (or it may not exist). This command is authenticated as your-username@domain.ca which is the active account specified by the [core/account] property.
```
You can try to grant your own user that role in the IAM console `https://console.cloud.google.com/iam-admin/iam?project=<PROJECT_ID>` or contact the administrator to grant you the access required. 
   
## Setup

The script is composed of three main files:

-   `project_prep.sh`: The main script that orchestrates the setup process.
-   `functions.sh`: A collection of helper functions for logging, command execution, and setup steps
-   `preflight.sh`: A precheck script for pre-requisites thats run as part of the main `project_prep.sh` script but can also be run ad-hoc
-   `clean.sh`: A script used to delete resources for the serivce account, its bindings and the GCS bucket. For testing purposes.

The setup process is divided into the following stages:

1.  **Language Selection:** Prompts the user to select a language for the script's output.
2.  **Initialization:** Sets up log files for tracing the execution.
3.  **Prerequisite Validation:** Checks for the `PROJECT_ID`, verifies the project number, billing status, and organization ID.
4.  **API Enablement:** Enables a list of necessary Google Cloud APIs.
5.  **Custom Role Creation:** Creates custom IAM roles required for the CaC solution from the `.yaml` files located in the `custom_roles` directory.
6.  **Service Account Setup:** Creates a primary service account and assigns it a set of predefined and custom roles at both the project and organization levels. It also cleans up legacy roles.
7.  **Service Identity Creation:** Creates service identities for various Google Cloud services.
8.  **Completion:** Prints a summary of the created service accounts.

## Running the Script

To execute the script, navigate to the `project_setup` directory and run the script itself:

```sh
export PROJECT_ID="your-project-name"     # required. The name of your project - not the number!
export LANGUAGE=                          # optional variable you can set to either "en" "fr" if you want to skip the language selection 
./project_prep.sh
```
## changes & next items

### changes

1. Separated functions into other script
2. Only env required is name of project `export PROJECT_ID="name-of-project"`
3. Readme added in EN and FR
4. Bit more logging format added. Logs in separate folder
5. Optional env for LANGUAGE. Can be 'en' or 'fr' to skip prompt
