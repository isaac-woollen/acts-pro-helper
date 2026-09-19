#!/bin/bash

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

urlencode() {
    # urlencode <string>
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

stop_file_check() {
  # Check if the stop file exists
  if [ -f "$STOP_FILE" ]; then
    log_info "Stop file found. Exiting..."
    rm "$STOP_FILE"
    exit 0
  fi
}

look_loop() {
  # While loop to continuously run the script
  while true; do
    stop_file_check

    sleep 1
    # Get the current status from the PRO server
    response=$(curl -s -X GET "http://${HOST}:${PORT}/v1/status/slide")
    # Check if response is not empty
    if [ -z "$response" ]; then
      continue
    fi
    
    # Check if the current slide text matches the Bible reference regex
    if [[ "$response" =~ $BIBLE_REFERENCE_REGEX ]]; then
      # Set Look to Scripture
      if [ "$already_triggered" = false ]; then
        SCRIPTURE_LOOK_ENCODED=$(urlencode "$SCRIPTURE_LOOK")
        log_info "Triggering look: $SCRIPTURE_LOOK"
        curl -s -X GET "http://${HOST}:${PORT}/v1/look/${SCRIPTURE_LOOK_ENCODED}/trigger"
        already_triggered=true
      fi
    else
      already_triggered=false
    fi

  done
}

new_countdown_music_loop() {
  # While loop to continuously run the script
  while true; do
    stop_file_check
    sleep 10
    
    update_file="$NEW_COUNTDOWN_MUSIC_DIRECTORY/update.file"
    pro_countdown_music_file_name="countdown.wav"
    # Check if update.file have been added to the countdown music directory
    if [ -f "$update_file" ]; then
      # Read update.file to get the new countdown music file name
      countdown_music_file_name=$(cat "$update_file")
      countdown_music_file="$NEW_COUNTDOWN_MUSIC_DIRECTORY/$countdown_music_file_name"
      if [ ! -f "$countdown_music_file" ]; then
        log_error "Countdown music file '$countdown_music_file' does not exist. Skipping update."
        mv "$update_file" "$update_file.backup.txt"
        continue
      fi
      log_info "New countdown music detected. Triggering update."
      cp "$countdown_music_file" "$PRO_MEDIA_DIRECTORY/$pro_countdown_music_file_name"
      mv "$update_file" "$update_file.backup.txt"
    fi

  done
}

# Create configuration directory if it doesn't exist
mkdir -p $HOME/.acts-pro-helper

LOGFILE="$HOME/.acts-pro-helper/acts-pro-helper.log"
exec >> "$LOGFILE" 2>&1

log_info "=== START ==="

# Configuration
CONF_FILE="$HOME/.acts-pro-helper/config.conf"

# Create configuration file if it doesn't exist
if [ ! -f "$CONF_FILE" ]; then
  echo "Creating default configuration file: $CONF_FILE"
  cat > "$CONF_FILE" << EOF
# Acts PRO Helper Configuration
HOST="localhost"
PORT="49888"
SCRIPTURE_LOOK="Scripture"
NEW_COUNTDOWN_MUSIC_DIRECTORY="$HOME/Dropbox/ACTS Dropbox/ACTS Audio/Countdown Music"
PRO_MEDIA_DIRECTORY="$HOME/Library/Application Support/RenewedVision/ProPresenter/UserWorkspaces/ProPresenter/Media/Assets"

EOF
fi

# Load configuration
if [ -f "$CONF_FILE" ]; then
  source "$CONF_FILE"
fi

# Stop File
STOP_FILE="/tmp/acts-pro-helper.stop" 

# Bible reference Regex
BIBLE_REFERENCE_REGEX='(^|[^[:alnum:]_])([1-3][[:space:]])?[[:alpha:]]+([[:space:]]+[[:alpha:]]+)*[[:space:]]+[0-9]+:[0-9]+(-[0-9]+)?($|[^[:alnum:]_])'

# State
already_triggered=false

# Cleanup function to stop background jobs
cleanup() {
    log_info "Stopping background jobs..."
    kill $(jobs -p) 2>/dev/null
    wait 2>/dev/null
}

trap cleanup EXIT INT TERM

# Loops
look_loop &
new_countdown_music_loop &

wait