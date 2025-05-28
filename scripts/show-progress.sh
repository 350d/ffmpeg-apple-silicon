#!/bin/bash

# Progress display utility for FFmpeg builds
# Usage: make 2>&1 | ./show-progress.sh "Building FFmpeg"

TASK_NAME="${1:-Building}"
COUNTER=0
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

show_progress() {
    local message="$1"
    local spin_char="${SPINNER:$((COUNTER % ${#SPINNER})):1}"
    printf "\r%s %s %s" "$spin_char" "$TASK_NAME" "$message"
    ((COUNTER++))
}

while IFS= read -r line; do
    if [[ "$line" == *"CC"* ]]; then
        filename=$(echo "$line" | sed 's/.*CC[[:space:]]*\([^[:space:]]*\).*/\1/' | xargs basename)
        show_progress "Compiling $filename"
    elif [[ "$line" == *"LD"* ]]; then
        show_progress "Linking binaries"
    elif [[ "$line" == *"AR"* ]]; then
        show_progress "Creating archives"
    elif [[ "$line" == *"error:"* ]] || [[ "$line" == *"Error"* ]]; then
        echo -e "\n❌ Error: $line"
        exit 1
    elif [[ "$line" == *"warning:"* ]] && [[ "$SHOW_WARNINGS" == "1" ]]; then
        echo -e "\n⚠️  Warning: $line"
    fi
    
    # Sleep briefly to make animation visible
    sleep 0.01
done

echo -e "\n✅ $TASK_NAME completed successfully!" 