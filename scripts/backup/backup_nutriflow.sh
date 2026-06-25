#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/etc/nutriflow-backup.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] $ENV_FILE not found. Run install.sh first." >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is not set}"
: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is not set}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is not set}"
: "${R2_ENDPOINT:?R2_ENDPOINT is not set}"
: "${R2_BUCKET:?R2_BUCKET is not set}"

TIMESTAMP=$(date -u +"%Y-%m-%d_%H-%M")
BACKUP_FILE="/tmp/nutri_flow_${TIMESTAMP}.dump"
S3_KEY="backups/${TIMESTAMP}.dump"
RETENTION_DAYS=7

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"; }

# ── 1. pg_dump ─────────────────────────────────────────────────────────────────
log "Starting pg_dump → ${BACKUP_FILE}"
if ! docker exec \
  -e PGPASSWORD="${POSTGRES_PASSWORD}" \
  nutri_flow-db \
  pg_dump -Fc -U nutri_flow nutri_flow_production \
  > "${BACKUP_FILE}"; then
  log "ERROR: pg_dump failed"
  rm -f "${BACKUP_FILE}"
  exit 1
fi

BACKUP_SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
log "pg_dump OK — size: ${BACKUP_SIZE}"

# ── 2. Upload vers R2 ──────────────────────────────────────────────────────────
log "Uploading to s3://${R2_BUCKET}/${S3_KEY}"
if ! AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
   AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
   aws s3 cp "${BACKUP_FILE}" "s3://${R2_BUCKET}/${S3_KEY}" \
   --endpoint-url "${R2_ENDPOINT}" \
   --no-progress; then
  log "ERROR: upload to R2 failed"
  rm -f "${BACKUP_FILE}"
  exit 1
fi
log "Upload OK"

# ── 3. Nettoyage local ─────────────────────────────────────────────────────────
rm -f "${BACKUP_FILE}"
log "Local temp file removed"

# ── 4. Pruning R2 — conserver les ${RETENTION_DAYS} derniers ──────────────────
log "Pruning backups older than ${RETENTION_DAYS} days on R2"

mapfile -t ALL_KEYS < <(
  AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
  AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
  aws s3 ls "s3://${R2_BUCKET}/backups/" \
    --endpoint-url "${R2_ENDPOINT}" \
  | awk '{print $4}' \
  | grep '\.dump$' \
  | sort
)

TOTAL=${#ALL_KEYS[@]}
log "Found ${TOTAL} backup(s) on R2"

if [[ $TOTAL -gt $RETENTION_DAYS ]]; then
  DELETE_COUNT=$(( TOTAL - RETENTION_DAYS ))
  log "Deleting ${DELETE_COUNT} old backup(s)"
  for key in "${ALL_KEYS[@]:0:$DELETE_COUNT}"; do
    log "  → deleting backups/${key}"
    AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
    AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
    aws s3 rm "s3://${R2_BUCKET}/backups/${key}" \
      --endpoint-url "${R2_ENDPOINT}"
  done
fi

log "Backup complete — ${TIMESTAMP}"
