#!/bin/bash

# Get current timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Add all changes
git add .

# Get list of changed files
CHANGED_FILES=$(git status --porcelain)

if [ -z "$CHANGED_FILES" ]; then
    echo "No changes to commit"
    exit 0
fi

# Create commit message
echo "Changes at $TIMESTAMP:" > commit_msg.tmp
echo "" >> commit_msg.tmp
echo "$CHANGED_FILES" | while read -r line; do
    STATUS=${line:0:2}
    FILE=${line:3}
    case $STATUS in
        "M ") echo "Modified: $FILE" >> commit_msg.tmp ;;
        "A ") echo "Added: $FILE" >> commit_msg.tmp ;;
        "D ") echo "Deleted: $FILE" >> commit_msg.tmp ;;
        "R ") echo "Renamed: $FILE" >> commit_msg.tmp ;;
        "C ") echo "Copied: $FILE" >> commit_msg.tmp ;;
        "??"*) echo "Untracked: $FILE" >> commit_msg.tmp ;;
        *) echo "Changed: $FILE" >> commit_msg.tmp ;;
    esac
done

# Commit changes
git commit -F commit_msg.tmp

# Clean up
rm commit_msg.tmp

echo "Changes committed successfully"
