#!/bin/bash
# ============================================================================
# Download models into ComfyUI
# ----------------------------------------------------------------------------
# Puts every model file in the right ComfyUI folder.
# Safe to run again: files that are already downloaded are skipped.
# Failed downloads are logged (FAIL:) and do NOT stop the other downloads.
#
# NEEDS: huggingface-cli (installed automatically below if missing).
# For gated models (like FLUX.1-dev) set HF_TOKEN in the template first.
# ============================================================================

LOG="${LOG:-/workspace/setup.log}"
COMFY="${COMFYUI_DIR:-/workspace/ComfyUI}"
MODELS="$COMFY/models"
FAILED=0

mkdir -p "$MODELS/checkpoints" "$MODELS/diffusion_models" "$MODELS/loras" \
         "$MODELS/vae" "$MODELS/clip" "$MODELS/text_encoders" \
         "$MODELS/controlnet" "$MODELS/upscale_models" "$MODELS/clip_vision"

log() { echo "[models] $*" | tee -a "$LOG"; }

# --- Make sure huggingface-cli is there -----------------------------------
if ! command -v huggingface-cli >/dev/null 2>&1; then
  log "Installing huggingface_hub ..."
  python3 -m pip install -q huggingface_hub >>"$LOG" 2>&1 \
    || log "WARNING: could not install huggingface_hub"
fi

# --- Gated models need a Hugging Face token -------------------------------
if [ -n "${HF_TOKEN:-}" ]; then
  huggingface-cli login --token "$HF_TOKEN" >>"$LOG" 2>&1 || true
  log "Hugging Face token found — gated models can download."
else
  log "No HF_TOKEN set — gated models (like FLUX.1-dev) will be skipped."
fi

# --- Download one file ------------------------------------------------------
# Usage: dl REPO FILE DESTDIR [NEEDS_TOKEN]
#   REPO  = Hugging Face repo, e.g. Comfy-Org/Wan-2.1
#   FILE  = file path inside the repo
#   DESTDIR = ComfyUI models folder the file belongs in
dl() {
  local repo="$1" file="$2" dest="$3" need_token="${4:-no}"
  local name
  name="$(basename "$file")"

  if [ -s "$dest/$name" ]; then
    log "Already have $name — skipping."
    return 0
  fi
  if [ "$need_token" = "yes" ] && [ -z "${HF_TOKEN:-}" ]; then
    log "SKIP $name — gated model, needs HF_TOKEN. Set it in the template."
    return 0
  fi

  log "Downloading $name ..."
  mkdir -p "$dest"
  if huggingface-cli download "$repo" "$file" --local-dir "$dest" --local-dir-use-symlinks False >>"$LOG" 2>&1; then
    # huggingface-cli keeps the repo sub-folders (split_files/...), so move
    # the file up to the folder ComfyUI actually looks in.
    if [ -f "$dest/$file" ] && [ "$dest/$file" != "$dest/$name" ]; then
      mv "$dest/$file" "$dest/$name"
      rmdir -p "$(dirname "$dest/$file")" 2>/dev/null || true
    fi
    if [ -s "$dest/$name" ]; then
      log "OK: $name"
    else
      log "FAIL: $name downloaded but the file is missing."
      FAILED=$((FAILED + 1))
      return 1
    fi
  else
    log "FAIL: $name from $repo"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

# ============================ MODEL LIST ==================================
# Pick your models here. Each "dl" line is one file to download.
#   To ADD a model: copy a line, change the repo / file / folder.
#   To REMOVE a model: put a # at the start of the line.
# Your own picks (including uncensored ones) go in the "YOUR MODELS"
# block at the bottom.
# ============================================================================

# --- Wan 2.1 — text-to-video, 14B, fp8 version (fits 24GB cards) ---------
# Total set: about 21 GB. Verified on huggingface.co 2026-11-21.
dl "Comfy-Org/Wan-2.1" "split_files/diffusion_models/wan2.1_t2v_14B_fp8_e4m3fn.safetensors" "$MODELS/diffusion_models"
dl "Comfy-Org/Wan-2.1" "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS/text_encoders"
dl "Comfy-Org/Wan-2.1" "split_files/vae/wan_2.1_vae.safetensors" "$MODELS/vae"
# Bigger quality version of the same model (28.6 GB instead of 14.3 GB):
# dl "Comfy-Org/Wan-2.1" "split_files/diffusion_models/wan2.1_t2v_14B_fp16.safetensors" "$MODELS/diffusion_models"

# --- HunyuanVideo 1.5 — image-to-video, 480p, fast step-distilled fp8 ----
# Total set: about 22 GB. Verified on huggingface.co 2026-11-21.
dl "Comfy-Org/Hunyuan-Video-1.5" "split_files/diffusion_models/hunyuanvideo1.5_480p_i2v_step_distilled_fp8_scaled.safetensors" "$MODELS/diffusion_models"
dl "Comfy-Org/Hunyuan-Video-1.5" "split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" "$MODELS/text_encoders"
dl "Comfy-Org/Hunyuan-Video-1.5" "split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors" "$MODELS/text_encoders"
dl "Comfy-Org/Hunyuan-Video-1.5" "split_files/vae/hunyuanvideo15_vae_fp16.safetensors" "$MODELS/vae"
dl "Comfy-Org/Hunyuan-Video-1.5" "split_files/clip_vision/sigclip_vision_patch14_384.safetensors" "$MODELS/clip_vision"

# --- FLUX.1-dev — still images (GATED: needs HF_TOKEN + license OK) -------
# Total set: about 29 GB. The repo is gated: accept the license on the
# FLUX.1-dev Hugging Face page and set HF_TOKEN in the template, or these
# lines are skipped with a note in the log.
dl "black-forest-labs/FLUX.1-dev" "flux1-dev.safetensors" "$MODELS/diffusion_models" yes
dl "black-forest-labs/FLUX.1-dev" "ae.safetensors" "$MODELS/vae" yes
dl "comfyanonymous/flux_text_encoders" "t5xxl_fp8_e4m3fn.safetensors" "$MODELS/text_encoders"
dl "comfyanonymous/flux_text_encoders" "clip_l.safetensors" "$MODELS/text_encoders"

# --- YOUR MODELS (fill these in tonight) ----------------------------------
# Your uncensored picks go here. Copy a line and fill in the repo + file.
# How to find them: open the model on huggingface.co, click "Files and
# versions", copy the repo name and the file path.
#
# Example:
# dl "REPO-NAME" "path/to/model.safetensors" "$MODELS/diffusion_models"
# dl "REPO-NAME" "path/to/model.safetensors" "$MODELS/checkpoints"
# dl "REPO-NAME" "path/to/lora.safetensors" "$MODELS/loras"

# --- Summary ----------------------------------------------------------------
echo ""
log "=== Download summary ==="
du -sh "$MODELS" 2>/dev/null | tee -a "$LOG"
find "$MODELS" -name "*.safetensors" -exec ls -lh {} \; 2>/dev/null | tee -a "$LOG"
log "Done. In ComfyUI, press R to reload the model lists."

if [ "$FAILED" -gt 0 ]; then
  log "FAIL: $FAILED download(s) failed — see above."
  exit 1
fi
exit 0
