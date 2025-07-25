#!/bin/bash

# Mapp att övervaka
WATCH_DIR="/home/pi/pdf_uploads"

# URL till API:t
UPLOAD_URL="https://example.com/upload"

# Loggfil
LOG_FILE="/home/pi/upload_log.txt"

# Funktion som laddar upp PDF
upload_pdf() {
    local file="$1"

    # Vänta 5 sekunder för att säkerställa att filen är färdigskriven
    sleep 5

    if [[ "$file" == *.pdf ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - PDF hittad: $file" >> "$LOG_FILE"

        # Utför uppladdning
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$UPLOAD_URL" \
            -F "file=@${file}" \
            -H "Expect:")

        # Separera HTTP status från svar
        body=$(echo "$response" | sed -e '/HTTP_STATUS:/d')
        status=$(echo "$response" | grep "HTTP_STATUS" | cut -d':' -f2)

        echo "$(date '+%Y-%m-%d %H:%M:%S') - CURL svar för $file:" >> "$LOG_FILE"
        echo "HTTP $status" >> "$LOG_FILE"
        echo "$body" >> "$LOG_FILE"
        echo "-------------------------------------" >> "$LOG_FILE"
    fi
}

# Kontrollera att mappen finns
if [[ ! -d "$WATCH_DIR" ]]; then
    echo "Mappen finns inte: $WATCH_DIR"
    exit 1
fi

echo "Övervakar $WATCH_DIR för PDF-filer..."
echo "$(date '+%Y-%m-%d %H:%M:%S') - Startar övervakning..." >> "$LOG_FILE"

# Starta övervakning
inotifywait -m -r -e create -e moved_to --format '%w%f' "$WATCH_DIR" | while read file
do
    if [[ -f "$file" ]]; then
        upload_pdf "$file" &
    fi
done
