#!/bin/bash

# Fetch the latest changes from the remote repository
git fetch

# Get the current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if the local branch is behind or ahead of the remote branch
BEHIND_COUNT=$(git rev-list --left-right --count $BRANCH...origin/$BRANCH | awk '{print $2}')
AHEAD_COUNT=$(git rev-list --left-right --count $BRANCH...origin/$BRANCH | awk '{print $1}')

if [ "$BEHIND_COUNT" -gt 0 ]; then
    echo "Local version is older than origin by $BEHIND_COUNT commit(s), pulling updates..."
    git pull
else
    echo "Local version is up-to-date/ahead, no updates needed."
fi