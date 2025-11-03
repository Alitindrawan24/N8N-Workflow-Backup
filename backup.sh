#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------
# Load environment variables from .env (if present)
# ---------------------------------------------------------
if [ -f ".env" ]; then
  # Read all non-commented lines and export them as environment variables
  export $(grep -v '^#' .env | xargs)
fi

# ---------------------------------------------------------
# Validate required environment variables
# ---------------------------------------------------------
: "${N8N_BASE_URL:?need N8N_BASE_URL}"       # Base URL for your n8n instance (e.g., https://n8n.example.com)
: "${N8N_API_KEY:?need N8N_API_KEY}"         # API key from n8n Settings > n8n API
: "${N8N_API_VERSION:=1}"                    # Default API version is 1
: "${GIT_COMMIT:=true}"                      # Whether to auto-commit changes to Git
: "${BACKUP_ACTIVE_ONLY:=false}"             # If true, only backup active workflows

# ---------------------------------------------------------
# Setup working directories
# ---------------------------------------------------------
WORKDIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${WORKDIR}/workflows"
mkdir -p "${OUT_DIR}"

echo "[backup] Fetching workflow list from n8n..."

# ---------------------------------------------------------
# 1. Fetch all workflows from n8n Public API
# ---------------------------------------------------------
WORKFLOWS_JSON=$(curl -sS -X GET \
  "${N8N_BASE_URL}/api/v${N8N_API_VERSION}/workflows" \
  -H "accept: application/json" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}")

# ---------------------------------------------------------
# 2. Filter workflow IDs
#    - If BACKUP_ACTIVE_ONLY=true → only select workflows with active == true
#    - Otherwise → select all workflows
# ---------------------------------------------------------
if [ "${BACKUP_ACTIVE_ONLY}" = "true" ]; then
  echo "[backup] Filtering only active workflows..."
  WORKFLOW_IDS=$(echo "${WORKFLOWS_JSON}" | jq -r '.data[] | select(.active == true) | .id')
else
  WORKFLOW_IDS=$(echo "${WORKFLOWS_JSON}" | jq -r '.data[].id')
fi

# Count how many workflows will be processed
COUNT=$(echo "${WORKFLOW_IDS}" | wc -l | tr -d ' ')
echo "[backup] Found ${COUNT} workflows to backup."

# ---------------------------------------------------------
# 3. Loop through workflow IDs and fetch full details
#    - Save each workflow as a separate .json file
# ---------------------------------------------------------
for ID in ${WORKFLOW_IDS}; do
  # Fetch workflow detail from n8n API
  WF_DETAIL=$(curl -sS -X GET \
    "${N8N_BASE_URL}/api/v${N8N_API_VERSION}/workflows/${ID}" \
    -H "accept: application/json" \
    -H "X-N8N-API-KEY: ${N8N_API_KEY}")

  # Extract workflow name and sanitize it for filename usage
  WF_NAME=$(echo "${WF_DETAIL}" | jq -r '.name' | sed 's/ /-/g' | tr '[:upper:]' '[:lower:]')
  SAFE_NAME="${WF_NAME:-workflow}-${ID}.json"

  # Save workflow definition as pretty-printed JSON file
  echo "[backup] Saving ${SAFE_NAME}..."
  echo "${WF_DETAIL}" | jq '.' > "${OUT_DIR}/${SAFE_NAME}"
done

echo "[backup] ✅ Backup completed. Files stored in ${OUT_DIR}"

# ---------------------------------------------------------
# 4. Optionally commit and push backups to GitHub
# ---------------------------------------------------------
if [ "${GIT_COMMIT}" = "true" ]; then
  cd "${WORKDIR}"

  # Add updated JSON files to Git
  git add workflows/*.json

  # Use UTC timestamp in commit message for traceability
  TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  git commit -m "chore(n8n-backup): auto backup ${TS}" || echo "[backup] nothing to commit"

  # Push to main branch
