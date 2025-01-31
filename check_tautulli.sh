#!/bin/bash
#
# Script Name: check_tautulli.sh
# Description: Checks Tautulli API responsiveness every CHECK_INTERVAL seconds.
#              If Tautulli is not responsive after 3 attempts (each 1 second apart),
#              restarts the specified Docker container and increments a restart counter.
#

# ---------------------------
# Configuration (Modify as needed)
# ---------------------------
TAUTULLI_URL="http://10.0.0.10:8181/api/v2"   # Replace with your Tautulli API endpoint
TAUTULLI_API_KEY="dad9bbb78bde43249754b630b58fbFAKE"  # Replace with your actual Tautulli API key

CHECK_INTERVAL=120      # Seconds between checks (default: 120)
container_name="${1:-tautulli}"  # Allow passing a container name as the first argument; defaults to 'tautulli'.

# Counter to track how many times we've restarted Tautulli
restart_count=0

# ---------------------------
# Function: Check if Tautulli is responsive
# ---------------------------
is_tautulli_responsive() {
    # If Tautulli responds with HTTP 200, we assume it's healthy
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
                    "${TAUTULLI_URL}?apikey=${TAUTULLI_API_KEY}&cmd=get_activity")

    if [[ "$response_code" -eq 200 ]]; then
        return 0
    else
        return 1
    fi
}

# ---------------------------
# Main Loop
# ---------------------------
while true; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking Tautulli API..."

    if is_tautulli_responsive; then
        echo "Tautulli is responsive."
    else
        echo "Tautulli is NOT responsive. Retrying in 1 second..."
        sleep 1

        if is_tautulli_responsive; then
            echo "Tautulli responded on second check. No action needed."
        else
            echo "Still not responsive. Retrying a third time in 1 second..."
            sleep 1

            if is_tautulli_responsive; then
                echo "Tautulli responded on third check. No action needed."
            else
                echo "No response after 3 attempts. Restarting Docker container: ${container_name}"
                docker restart "${container_name}"
                ((restart_count++))
                echo "Tautulli has been restarted ${restart_count} times."
            fi
        fi
    fi

    sleep "${CHECK_INTERVAL}"
done
