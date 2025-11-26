#!/usr/bin/env bash

REPO="frogbot-state"
REMOTE_PATH="state/repo-status"
LOCAL_DIR="./repo-status-files"

echo "Downloading files from Artifactory..."
jf rt dl "${REPO}/${REMOTE_PATH}/*" "${LOCAL_DIR}/" --flat=true

echo
echo "Processing files..."

current_epoch=$(date -u +%s)

for file in ${LOCAL_DIR}/*.txt; do
    echo "----------------------------------------"
    echo "Processing: $file"

    repoPath=$(cut -d',' -f1 "$file")
    lastCommit=$(cut -d',' -f2 "$file")
    status=$(cut -d',' -f3 "$file")
    fileTs=$(cut -d',' -f4 "$file")

    echo "repoPath $repoPath"
    echo "lastCommit $lastCommit"
    echo "status $status"
    echo "fileTs $fileTs"

    if [ "$status" == "completed" ]; then
        echo "✔ Completed — no reset needed."
        continue
    fi
    # Clean the timestamp: remove Z and add UTC
    file_epoch=$(date -u -d "$fileTs" +%s 2>/dev/null)

    if [ -z "$file_epoch" ]; then
        echo "Invalid timestamp: $fileTs"
        continue
    fi

    age_seconds=$(( current_epoch - file_epoch ))
    age_hours=$(( age_seconds / 3600 ))

    echo "Age: ${age_hours} hours"

    if [ $age_hours -ge 24 ]; then
        echo "More than 24 hours old — resetting status."

        echo "${repoPath},${lastCommit},resetted,${fileTs}" > "$file"
        jf rt u "$file" "${REPO}/${REMOTE_PATH}/$(basename "$file")" --flat
    else
        echo "Recent — no reset required."
    fi
done
