#!/bin/bash
# ============================================================================
# ComfyUI animation studio — MAIN setup script for Vast.ai
# ----------------------------------------------------------------------------
# What this does, every time you rent a new server:
#   1. Downloads your models        (download-models.sh)
#   2. Installs your custom nodes   (install-nodes.sh)
#   3. Emails you when it's done    (notify-done.sh)
#
# HOW TO USE IT (full steps are in README.md):
#   Option A: In your Vast.ai template, set PROVISIONING_SCRIPT to the raw
#             URL of THIS file. It runs by itself when the server boots.
#   Option B: After the server boots, open Jupyter Terminal and run:
#               bash /workspace/setup/provisioning.sh
#
# SETUP_BASE_URL: where the other 3 scripts live.
#   Change YOUR-GITHUB-USERNAME below to your own GitHub name once the
#   files are in a repo. Until then, Option B (local copies) is the way.
# ============================================================================

LOG="/workspace/setup.log"
SETUP_DIR="/workspace/setup"
BASE_URL="${SETUP_BASE_URL:-https://raw.githubusercontent.com/YOUR-GITHUB-USERNAME/vast-comfyui-setup/main}"

mkdir -p "$SETUP_DIR"
touch "$LOG"

# Send all output to the screen AND to the log file at the same time.
exec > >(tee -a "$LOG") 2>&1

echo "============================================================"
echo " ComfyUI setup started: $(date)"
echo "============================================================"

# Wait a little for ComfyUI to appear (the template sets it up at boot).
# We do NOT stop if it never shows up — the other scripts make the
# folders they need. This just gives the template time to finish first.
for i in $(seq 1 18); do
  if [ -d "/workspace/ComfyUI" ]; then
    echo "Found ComfyUI at /workspace/ComfyUI"
    break
  fi
  sleep 10
done

# --- Get one of the other scripts ----------------------------------------
# Use a copy sitting next to this file if there is one (Option B).
# Otherwise download it from your repo (Option A).
get_script() {
  local name="$1"
  local here
  here="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
  if [ -f "$here/$name" ]; then
    echo "Using local copy of $name"
    cp "$here/$name" "$SETUP_DIR/$name"
  else
    echo "Downloading $name from $BASE_URL ..."
    if curl -fsSL "$BASE_URL/$name" -o "$SETUP_DIR/$name"; then
      echo "Downloaded $name"
    else
      echo "WARNING: could not download $name — that step will be skipped."
      return 1
    fi
  fi
  chmod +x "$SETUP_DIR/$name"
  return 0
}

# --- Run one step, keep going even if it fails ---------------------------
# A failed step is written to setup.log.failures so the email can list it.
run_step() {
  local label="$1"
  local script="$2"
  echo ""
  echo "--- STEP: $label ---"
  if [ ! -f "$SETUP_DIR/$script" ]; then
    echo "FAIL: $script is missing — skipping $label."
    echo "FAIL: $label ($script missing)" >> "$LOG.failures"
    return 1
  fi
  if bash "$SETUP_DIR/$script"; then
    echo "OK: $label finished."
  else
    echo "FAIL: $label had errors — see the log. Continuing anyway."
    echo "FAIL: $label" >> "$LOG.failures"
  fi
  return 0
}

rm -f "$LOG.failures"
get_script "download-models.sh"
get_script "install-nodes.sh"
get_script "notify-done.sh"

run_step "Download models" "download-models.sh"
run_step "Install custom nodes" "install-nodes.sh"
run_step "Send ready email" "notify-done.sh"

echo ""
echo "============================================================"
echo " ComfyUI setup finished: $(date)"
echo " Full log: $LOG"
echo " Done file: /workspace/setup-done.txt"
echo "============================================================"
