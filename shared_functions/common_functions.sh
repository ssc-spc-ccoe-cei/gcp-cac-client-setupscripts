#!/bin/bash

# --- Error handler for robust error trapping ---
function error_handler() {
  local msg="${LANG_ERROR_UNEXPECTED:-An unexpected error occurred. Script cannot continue.}"
  print_error "$msg"
  exit 1
}

# Trap errors and call the error handler
trap 'error_handler' ERR

# Centralized log function to write to both console and log file
function log_message() {
  local message="$1"
  echo "${message}"
  echo "${message}" >> "$LOG_FILE"
}

function log_newline() {
  echo ""
}

function log_info() {
  tput setaf 4
  log_newline
  log_message "INFO: $1"
  tput sgr0
}

function log_header() {
  tput setaf 3; tput bold
  log_message "--- $1 ---"
  tput sgr0
}

function log_step() {
  echo "  ➜ $1"
}

function print_error {
  local error_msg="$1"
  tput setaf 1
  log_message "[FAILED]" >&2
  log_message "[ERROR] ${error_msg}" >&2

  # Only show logs if the file actually exists and has content
  if [ -s "$LOG_FILE" ]; then
    echo -e "\n--- Last 5 lines of technical error logs ---" >&2
    tail -n 5 "$LOG_FILE" >&2
    echo -e "--------------------------------------------\n" >&2
  fi
  tput sgr0
}

function print_success {
  local message="${1:-}"
  tput setaf 2
  log_message "[SUCCESS] ${message}"
  tput sgr0
}

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

function run_command() {

  # Grab command to run, and processing + error messages as input
  local command="$1"
  local processing_msg="$2"
  local error_msg="$3"

  # Log the start of the command, without a newline
  echo -n "➜ ${processing_msg}..."
  echo "[INFO] Running: ${processing_msg}" >> "$LOG_FILE"


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
  ## Allows user to set preferred install language, looping until a valid choice is made.

  while true; do
    if [ -z "${LANGUAGE:-}" ]; then # If LANGUAGE is not set or is empty, prompt the user.
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
      LANGUAGE=$(tr '[:upper:]' '[:lower:]' <<< "$LANGUAGE_INPUT")
    fi

    case $LANGUAGE in
      1|en|english)
        source ../language_localization/english_ENG.sh
        print_success "$LANG_LANGUAGE_SET"
        break # Exit loop on valid selection
        ;;
      2|fr|francais)
        source ../language_localization/french_FR.sh
        print_success "$LANG_LANGUAGE_SET"
        break # Exit loop on valid selection
        ;;
      *)
        tput setaf 1
        echo "" >&2
        echo "[ERROR] Invalid input. Please select a valid installation language. / Entrée invalide. Veuillez sélectionner une langue d'installation valide." >&2
        tput sgr0
        LANGUAGE="" # Unset LANGUAGE to force a re-prompt
        sleep 1
        ;;
    esac
  done
}
