#!/bin/bash
# ============================================================================
# Install ComfyUI custom nodes
# ----------------------------------------------------------------------------
# Clones each node into /workspace/ComfyUI/custom_nodes.
# If a node is already there, it updates it instead of cloning again.
# Safe to run again. A failed node is logged (FAIL:) and skipped.
# After this, restart ComfyUI (or press R) for new nodes to show up.
# ============================================================================

LOG="${LOG:-/workspace/setup.log}"
NODES="${COMFYUI_DIR:-/workspace/ComfyUI}/custom_nodes"
FAILED=0

mkdir -p "$NODES"
log() { echo "[nodes] $*" | tee -a "$LOG"; }

if ! command -v git >/dev/null 2>&1; then
  log "Installing git ..."
  (apt-get update -qq && apt-get install -y -qq git) >>"$LOG" 2>&1 \
    || log "WARNING: could not install git — node installs will fail."
fi

# --- Install or update one node -------------------------------------------
# Usage: node GITHUB_URL FOLDER
node() {
  local url="$1" dir="$2"
  if [ -d "$NODES/$dir/.git" ]; then
    log "Updating $dir ..."
    (cd "$NODES/$dir" && git pull --ff-only >>"$LOG" 2>&1) \
      || log "WARNING: could not update $dir — keeping the old copy."
  else
    log "Installing $dir ..."
    if git clone --depth 1 "$url" "$NODES/$dir" >>"$LOG" 2>&1; then
      log "OK: $dir"
    else
      log "FAIL: $dir"
      FAILED=$((FAILED + 1))
      return 1
    fi
  fi
  # Some nodes need extra Python packages — install them if listed.
  if [ -f "$NODES/$dir/requirements.txt" ]; then
    log "Installing extras for $dir ..."
    python3 -m pip install -q -r "$NODES/$dir/requirements.txt" >>"$LOG" 2>&1 \
      || log "WARNING: some extras for $dir did not install."
  fi
}

# --- NODE LIST (all verified on github.com 2026-11-21) --------------------
# ComfyUI-Manager: lets you install more nodes from inside ComfyUI.
# NOTE: it moved from ltdrdata to Comfy-Org — the URL below is the new home.
node "https://github.com/Comfy-Org/ComfyUI-Manager.git" "ComfyUI-Manager"

# VideoHelperSuite: load/save video, frame counts — needed for video work.
node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" "ComfyUI-VideoHelperSuite"

# Impact Pack: detailer / face fix / upscaling helpers.
node "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "ComfyUI-Impact-Pack"

# --- YOUR NODES (add more here) -------------------------------------------
# Copy a line and fill in the GitHub URL + folder name:
# node "https://github.com/USER/REPO.git" "REPO"

log "Done. Restart ComfyUI for new nodes to show up."

if [ "$FAILED" -gt 0 ]; then
  log "FAIL: $FAILED node(s) failed — see above."
  exit 1
fi
exit 0
