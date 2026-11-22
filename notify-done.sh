#!/bin/bash
# ============================================================================
# Tell the user the server is ready
# ----------------------------------------------------------------------------
# ALWAYS writes /workspace/setup-done.txt (the fallback — you can check it
# in Jupyter any time, even if email is not set up).
# ALSO sends an email, but only if these two are set in the template:
#   NOTIFY_EMAIL        = your Gmail address (also the sender + recipient)
#   GMAIL_APP_PASSWORD  = a Gmail app password (16 letters, no spaces)
# See README.md for how to make an app password. NEVER put the password
# in these files — it only lives in the template settings.
# ============================================================================

LOG="${LOG:-/workspace/setup.log}"
DONE_FILE="/workspace/setup-done.txt"

FAILURES="$(grep -E "FAIL:" "$LOG" 2>/dev/null | head -20)"
if [ -n "$FAILURES" ]; then
  STATUS="READY WITH SOME FAILURES"
else
  STATUS="READY"
fi

{
  echo "ComfyUI setup: $STATUS"
  echo "Finished: $(date)"
  echo ""
  echo "Models are in: /workspace/ComfyUI/models"
  echo "Open ComfyUI from the Vast.ai instance portal (Open button)."
  echo "Press R in ComfyUI to reload the model lists."
  echo ""
  if [ -n "$FAILURES" ]; then
    echo "These steps had problems (full log: $LOG):"
    echo "$FAILURES"
    echo ""
    echo "To retry: run bash /workspace/setup/download-models.sh"
    echo "in Jupyter Terminal — files already downloaded are skipped."
  else
    echo "Everything downloaded and installed cleanly."
  fi
} > "$DONE_FILE"
echo "[notify] Wrote $DONE_FILE"

# --- Email (only if both settings are filled in) ---------------------------
if [ -z "${NOTIFY_EMAIL:-}" ] || [ -z "${GMAIL_APP_PASSWORD:-}" ]; then
  echo "[notify] No email settings (NOTIFY_EMAIL / GMAIL_APP_PASSWORD) — skipping email." | tee -a "$LOG"
  echo "[notify] The DONE file above is your fallback — check it in Jupyter." | tee -a "$LOG"
  exit 0
fi

if ! command -v msmtp >/dev/null 2>&1; then
  echo "[notify] Installing msmtp ..." | tee -a "$LOG"
  (apt-get update -qq && apt-get install -y -qq msmtp ca-certificates) >>"$LOG" 2>&1 || true
fi

if ! command -v msmtp >/dev/null 2>&1; then
  echo "[notify] FAIL: msmtp is not available — email not sent." | tee -a "$LOG"
  exit 1
fi

# msmtp settings live ONLY in this temp file (deleted right after sending).
MSMTP_CONF="$(mktemp)"
chmod 600 "$MSMTP_CONF"
cat > "$MSMTP_CONF" <<EOF
account default
host smtp.gmail.com
port 587
auth on
user $NOTIFY_EMAIL
password $GMAIL_APP_PASSWORD
from $NOTIFY_EMAIL
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
EOF

EMAIL_BODY="$(mktemp)"
{
  echo "To: $NOTIFY_EMAIL"
  echo "Subject: Your ComfyUI server is ready ($STATUS)"
  echo ""
  cat "$DONE_FILE"
} > "$EMAIL_BODY"

if msmtp -C "$MSMTP_CONF" "$NOTIFY_EMAIL" < "$EMAIL_BODY" >>"$LOG" 2>&1; then
  echo "[notify] OK: ready email sent to $NOTIFY_EMAIL" | tee -a "$LOG"
else
  echo "[notify] FAIL: email did not send — check the app password." | tee -a "$LOG"
fi

# Clean up — the password must not stay on the server in a file.
rm -f "$MSMTP_CONF" "$EMAIL_BODY"
exit 0
