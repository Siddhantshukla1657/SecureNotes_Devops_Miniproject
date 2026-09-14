#!/usr/bin/env bash
# ==============================================================================
# SecureNotes Demo Reset Tool (Bash)
# Restores any of the 4 demo states with one command and pushes to main.
# Usage: ./scripts/reset-demo.sh <state> [--push]
# States:
#   - vulnerable        : Baseline with hardcoded secret + duplicate logic + python:3.8
#   - fixed             : Clean code + hardened python:3.12-slim base
#   - agent-secret-only : Hardcoded secret on clean base (demo code remediation)
#   - agent-image-only  : Clean code on vulnerable python:3.8 (demo image remediation)
# ==============================================================================

set -e

STATE=$1
PUSH_FLAG=$2

if [ -z "$STATE" ]; then
    echo "Usage: ./scripts/reset-demo.sh <vulnerable|fixed|agent-secret-only|agent-image-only> [--push]"
    exit 1
fi

STATE_DIR="demo-states/$STATE"

if [ ! -d "$STATE_DIR" ]; then
    echo "Error: Unknown state '$STATE'. Available states: vulnerable, fixed, agent-secret-only, agent-image-only"
    exit 1
fi

echo "==> Restoring SecureNotes state to: $STATE"

# Copy snapshot files over active workspace
cp "$STATE_DIR/app.py" ./app.py
cp "$STATE_DIR/Dockerfile" ./Dockerfile

echo "==> Updated app.py and Dockerfile to match state '$STATE'."

if [ "$PUSH_FLAG" = "--push" ] || [ "$PUSH_FLAG" = "-p" ]; then
    echo "==> Committing and pushing state to git..."
    git add app.py Dockerfile
    if git diff-index --quiet HEAD --; then
        echo "No changes detected. State is already up to date on current branch."
    else
        git commit -m "demo(state): switch demo baseline to '$STATE'"
        git push origin main
        echo "==> Successfully pushed '$STATE' state to trigger CI/CD pipeline."
    fi
else
    echo "==> Local files updated. To push to GitHub and trigger CI/CD, run:"
    echo "    git add app.py Dockerfile && git commit -m \"demo: switch to $STATE\" && git push origin main"
fi
