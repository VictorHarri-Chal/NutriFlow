#!/usr/bin/env bash
# Installation script — run once on the production server as root.
# Usage: bash install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="/etc/nutriflow-backup.env"

log() { echo "▶ $*"; }
err() { echo "✗ $*" >&2; exit 1; }
ok()  { echo "✓ $*"; }

[[ $EUID -eq 0 ]] || err "Run as root (sudo bash install.sh)"

# ── 1. Vérifier Docker ─────────────────────────────────────────────────────────
log "Checking Docker..."
command -v docker &>/dev/null || err "Docker not found. Install Docker first."
docker info &>/dev/null || err "Docker daemon is not running."
ok "Docker is available"

# ── 2. Installer AWS CLI v2 si absent ─────────────────────────────────────────
if ! command -v aws &>/dev/null; then
  log "Installing AWS CLI v2..."
  apt-get install -y unzip curl &>/dev/null
  TMP_DIR=$(mktemp -d)
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "${TMP_DIR}/awscliv2.zip"
  unzip -q "${TMP_DIR}/awscliv2.zip" -d "${TMP_DIR}"
  "${TMP_DIR}/aws/install" --update
  rm -rf "${TMP_DIR}"
  ok "AWS CLI v2 installed: $(aws --version)"
else
  ok "AWS CLI already installed: $(aws --version)"
fi

# ── 3. Créer /etc/nutriflow-backup.env ────────────────────────────────────────
if [[ -f "$ENV_FILE" ]]; then
  log "${ENV_FILE} already exists — skipping credential prompt (delete to reconfigure)"
else
  log "Creating ${ENV_FILE} (credentials will not be echoed)"
  echo ""
  read -r -s -p "POSTGRES_PASSWORD: " PG_PASS; echo ""
  read -r -s -p "AWS_ACCESS_KEY_ID (R2): " R2_KEY; echo ""
  read -r -s -p "AWS_SECRET_ACCESS_KEY (R2): " R2_SECRET; echo ""
  read -r -p "R2_ENDPOINT [https://cf9a0b25bbe6f0c961a015d8be262707.r2.cloudflarestorage.com]: " R2_ENDPOINT
  R2_ENDPOINT="${R2_ENDPOINT:-https://cf9a0b25bbe6f0c961a015d8be262707.r2.cloudflarestorage.com}"
  read -r -p "R2_BUCKET [nutriflow-storage]: " R2_BUCKET
  R2_BUCKET="${R2_BUCKET:-nutriflow-storage}"

  cat > "$ENV_FILE" <<EOF
POSTGRES_PASSWORD=${PG_PASS}
AWS_ACCESS_KEY_ID=${R2_KEY}
AWS_SECRET_ACCESS_KEY=${R2_SECRET}
R2_ENDPOINT=${R2_ENDPOINT}
R2_BUCKET=${R2_BUCKET}
EOF
  chmod 600 "$ENV_FILE"
  ok "${ENV_FILE} created (mode 600)"
fi

# ── 4. Déployer le script de backup ───────────────────────────────────────────
log "Deploying backup script to /usr/local/bin/backup_nutriflow.sh"
cp "${SCRIPT_DIR}/backup_nutriflow.sh" /usr/local/bin/backup_nutriflow.sh
chmod 750 /usr/local/bin/backup_nutriflow.sh
ok "Script deployed"

# ── 5. Déployer les units systemd ─────────────────────────────────────────────
log "Deploying systemd units..."
cp "${SCRIPT_DIR}/nutriflow-backup.service" /etc/systemd/system/
cp "${SCRIPT_DIR}/nutriflow-backup.timer"   /etc/systemd/system/
systemctl daemon-reload
systemctl enable nutriflow-backup.timer
systemctl start  nutriflow-backup.timer
ok "Timer enabled and started"

# ── 6. Test d'exécution immédiate ─────────────────────────────────────────────
echo ""
read -r -p "Run a test backup now? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  log "Running backup now (this may take a moment)..."
  systemctl start nutriflow-backup.service
  echo ""
  journalctl -u nutriflow-backup --no-pager -n 30
  echo ""
  if systemctl is-failed --quiet nutriflow-backup.service; then
    err "Backup service failed — check logs above"
  else
    ok "Test backup completed successfully"
  fi
fi

# ── 7. Résumé ─────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo " NutriFlow backup installed successfully"
echo ""
echo " Schedule : daily at 03:00 UTC"
echo " Retention: 7 backups"
echo " Bucket   : ${R2_BUCKET:-nutriflow-storage}/backups/"
echo ""
echo " Useful commands:"
echo "   systemctl status nutriflow-backup.timer"
echo "   systemctl start  nutriflow-backup.service   # manual run"
echo "   journalctl -u nutriflow-backup -f           # live logs"
echo "════════════════════════════════════════════════════════"
