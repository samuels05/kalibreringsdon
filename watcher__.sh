#!/bin/bash

# Mapp att övervaka
WATCH_DIR="/home/pi/pdf_uploads"

# URL till API:t
UPLOAD_URL="https://example.com/upload"

# Loggfil
LOG_FILE="/home/pi/upload_log.txt"

# Associativ array för att hålla koll på redan övervakade mappar
declare -A WATCHED_DIRS

# Funktion för loggning
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Funktion för uppladdning
upload_pdf() {
    local file="$1"
    sleep 5

    if [[ "$file" == *.pdf ]]; then
        log "PDF hittad: $file"
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$UPLOAD_URL" \
            -F "file=@${file}" \
            -H "Expect:")
        body=$(echo "$response" | sed -e '/HTTP_STATUS:/d')
        status=$(echo "$response" | grep "HTTP_STATUS" | cut -d':' -f2)

        log "CURL svar för $file:"
        log "HTTP $status"
        log "$body"
        log "-------------------------------------"
    fi
}

# Funktion för att starta övervakning av en katalog
start_watch() {
    local dir="$1"

    # Kontrollera om redan övervakad
    if [[ -n "${WATCHED_DIRS["$dir"]}" ]]; then
        return
    fi

    log "Börjar övervaka katalog: $dir"
    WATCHED_DIRS["$dir"]=1

    # Kör inotifywait för denna mapp
    inotifywait -m -e create -e moved_to --format '%w%f' "$dir" |
    while read file; do
        if [[ -d "$file" ]]; then
            # Ny undermapp hittad – starta övervakning
            start_watch "$file" &
        elif [[ -f "$file" && "$file" == *.pdf ]]; then
            upload_pdf "$file" &
        fi
    done &
}

# Starta övervakning för alla befintliga undermappar
initialize_watches() {
    find "$WATCH_DIR" -type d | while read dir; do
        start_watch "$dir"
    done
}

# Kontrollera att övervakningsmapp finns
if [[ ! -d "$WATCH_DIR" ]]; then
    echo "Mappen finns inte: $WATCH_DIR"
    exit 1
fi

log "Startar dynamisk övervakning av $WATCH_DIR och alla undermappar..."
initialize_watches

# Håll huvudtråden igång
while true; do
    sleep 60
done
