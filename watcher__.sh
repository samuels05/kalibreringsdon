#!/bin/bash

# === Configuration ===
WATCH_DIR="/path/to/your/folder"    # Folder to monitor
UPLOAD_URL="https://example.com/upload"  # Replace with your actual endpoint

# Check if inotifywait is installed
if ! command -v inotifywait &> /dev/null; then
    echo "Error: inotify-tools is not installed. Install it using: sudo apt install inotify-tools"
    exit 1
fi

echo "Monitoring folder: $WATCH_DIR"

# === Monitor folder ===
inotifywait -m -e create --format "%f" "$WATCH_DIR" | while read NEW_FILE; do
    FULL_PATH="$WATCH_DIR/$NEW_FILE"
    echo "New file detected: $FULL_PATH"

    # Wait for file to finish writing (optional: small delay)
    sleep 1

    # Send file via curl
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
      -F "username=myuser" \
      -F "password=mypass" \
      -F "file=@$FULL_PATH" \
      "$UPLOAD_URL")

    if [[ "$RESPONSE" == "200" ]]; then
        echo "✅ File $NEW_FILE uploaded successfully."
    else
        echo "❌ Upload failed (HTTP $RESPONSE) for file $NEW_FILE."
    fi
done
