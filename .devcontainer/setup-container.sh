#!/usr/bin/env bash
set -euo pipefail

ORG="${BRIG_ID_ORG:-brig-id}"
REPOS="${BRIG_ID_REPOS:-.github}"

echo "Setting up ${ORG} workspace..."

for repo in $REPOS; do
  target="/workspaces/${repo}"

  if [ -d "${target}/.git" ] || [ -n "$(ls -A "${target}" 2>/dev/null || true)" ]; then
    echo "✓ ${repo}: already available"
    continue
  fi

  echo "→ ${repo}: cloning missing sibling repository"
  if command -v gh >/dev/null 2>&1; then
    gh repo clone "${ORG}/${repo}" "${target}" || echo "! ${repo}: clone failed"
  else
    git clone "https://github.com/${ORG}/${repo}.git" "${target}" || echo "! ${repo}: clone failed"
  fi
done

echo "Workspace ready."
