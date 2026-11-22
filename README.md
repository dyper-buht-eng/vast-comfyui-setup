# ComfyUI Animation Studio — Vast.ai Setup Pack

Rent a GPU on Vast.ai, and this pack sets it up for you: it downloads your
models, installs your custom nodes, and emails you when the server is ready.
You do it once here, and every new server you rent gets the same setup.

## What's in here

| File | What it does |
|---|---|
| `provisioning.sh` | The main script. Runs the other three in order and logs everything to `/workspace/setup.log`. Keeps going if one step fails. |
| `download-models.sh` | Downloads your models into the right ComfyUI folders. The model list is at the top — edit it to add your picks. |
| `install-nodes.sh` | Installs custom nodes (Manager, VideoHelperSuite, Impact Pack). |
| `notify-done.sh` | Emails you "your server is ready" and always writes `/workspace/setup-done.txt` as a backup. |

## Before you start — what you need

1. **A Vast.ai account** with money added (rent is by the hour).
2. **Pick the official "ComfyUI" template** when you rent. It already has
   ComfyUI, Jupyter, and SSH on it — you do NOT install ComfyUI yourself.
   Boot takes about 2–4 minutes.
3. **Disk: 200 GB.** Pick this when you rent the server (see the table below).
4. **GPU: 24 GB of VRAM or more** for video models (Wan, HunyuanVideo).
5. **Your model picks.** The pack already has Wan 2.1, HunyuanVideo 1.5,
   and FLUX.1-dev in it. Your own picks (including uncensored ones) go in
   the "YOUR MODELS" block at the top of `download-models.sh`.
6. **A Gmail app password** for the ready email (steps below).
7. **A Hugging Face token** — only if you want FLUX.1-dev, because that
   model is gated. Make a free read token at huggingface.co/settings/tokens,
   accept the license on the FLUX.1-dev page, and set `HF_TOKEN` in the
   template.

## How much disk space do you need?

Sizes measured from Hugging Face on 2026-11-21 (GB = gigabytes).

| What's on the server | Size |
|---|---|
| ComfyUI + Python + custom nodes | ~5–10 GB |
| Wan 2.1 video set (fp8: model 14.3 + text encoder 6.7 + VAE 0.3) | ~21 GB |
| HunyuanVideo 1.5 video set (fp8: model 8.3 + text encoder 9.4 + extras 3.8) | ~22 GB |
| FLUX.1-dev image set (model ~23.8* + VAE ~0.3 + text encoders 5.1) | ~29 GB |
| Your own extra models | depends on the model |
| Videos you make + spare room | ~10–20 GB |

\* FLUX.1-dev's repo is gated, so its 23.8 GB is the published size — it
couldn't be measured directly. The other sizes above were measured.

**Planning totals:**

| Your setup | Rough total | Disk to rent |
|---|---|---|
| 1 video model (e.g. Wan 2.1 fp8) | ~40–60 GB | 200 GB |
| 2 video models (Wan 2.1 + HunyuanVideo 1.5) | ~70–100 GB | 200 GB |
| 2 video models + FLUX.1-dev, or fp16 versions | ~100 GB and up | 200 GB |

200 GB is the safe pick. It costs a little more per hour, but running out
of disk halfway through a download is worse. If you switch a model from
fp8 to fp16, add about 15 GB per model.

## How long does it take, and what does it cost?

- **Server boot:** 2–4 minutes.
- **Downloads:** the server downloads from Hugging Face at datacenter
  speed. A 20 GB model takes about 5–10 minutes. A full setup is usually
  done in about 10–20 minutes.
- **Cost:** the hourly rate keeps running while it downloads. At a typical
  $0.30–$0.50 per hour, 10–15 minutes of downloading is only a few cents.
  Watch out for bandwidth fees — some hosts charge per TB downloaded, so
  check the price on the machine page before you rent.

## Option A — automatic (best): set it in the template

Do this once, and every server you rent sets itself up.

1. Put these 4 files in a GitHub repo (or a GitHub Gist — any public place
   with raw file links works).
2. In `provisioning.sh`, change `YOUR-GITHUB-USERNAME` in the `BASE_URL`
   line to your GitHub name (and the repo name if it's different).
3. In Vast.ai, go to **Templates**, find the official **ComfyUI** template,
   and click **Edit** (or make a copy of it).
4. Set the **PROVISIONING_SCRIPT** setting to the raw URL of
   `provisioning.sh`, for example:
   `https://raw.githubusercontent.com/YOUR-GITHUB-USERNAME/vast-comfyui-setup/main/provisioning.sh`
   (It must start with `#!/bin/bash` — it does.)
5. Add these settings in the same template (all optional, but the email
   ones are needed for the ready email):
   - `NOTIFY_EMAIL` — your Gmail address
   - `GMAIL_APP_PASSWORD` — your Gmail app password (see below)
   - `HF_TOKEN` — your Hugging Face token (only for gated models)
6. Rent a server with that template. It boots, runs the scripts, and
   emails you when it's done.

## Option B — by hand: paste into Jupyter Terminal

Good for testing, or if you don't want to touch the template yet.

1. Rent a server with the official ComfyUI template (200 GB disk).
2. Wait for the **Open** button, click it, and open **Jupyter Terminal**.
3. Upload these 4 files into `/workspace/setup/` (Jupyter has an Upload
   button), or paste them in with the terminal.
4. Run:
   ```bash
   cd /workspace/setup
   chmod +x *.sh
   NOTIFY_EMAIL="you@gmail.com" GMAIL_APP_PASSWORD="xxxx xxxx xxxx xxxx" bash provisioning.sh
   ```
   (Leave the email part off if you haven't made an app password yet —
   the DONE file still gets written.)
5. Watch it work. When it's done, check `/workspace/setup-done.txt`.

## Email setup — Gmail app password

The ready email comes from your own Gmail. Google needs an **app password**
for this — your normal Gmail password will NOT work.

1. Turn on 2-Step Verification on your Google account (Google Account →
   Security → 2-Step Verification).
2. Go to Google Account → Security → **App passwords**.
3. Pick "Mail" and your device, click **Create**, and copy the 16-letter
   code it shows you (it looks like `abcd efgh ijkl mnop` — no spaces when
   you paste it into the template).
4. Put it in the template as `GMAIL_APP_PASSWORD`, and your Gmail address
   as `NOTIFY_EMAIL`.
5. The password is never written into these files. It only lives in the
   template settings and in a temp file on the server that is deleted right
   after the email sends.

No app password yet? No problem — the setup still runs, and you can check
`/workspace/setup-done.txt` in Jupyter instead of getting an email.

## How to add your own models

Open `download-models.sh` and find the **YOUR MODELS** block. Copy one of
the example lines and change it:

```bash
dl "REPO-NAME" "path/to/model.safetensors" "$MODELS/diffusion_models"
```

- **REPO-NAME** is the Hugging Face repo, like `Comfy-Org/Wan-2.1`.
- **path/to/model.safetensors** is the file path — find it on the model's
  Hugging Face page under "Files and versions".
- The last part is the folder: `diffusion_models` for video models,
  `checkpoints` for image checkpoints, `loras` for LoRAs, `vae` for VAEs,
  `text_encoders` for text encoders, `clip_vision` for vision encoders.

Same idea for extra custom nodes in `install-nodes.sh` — copy a `node`
line and put in the GitHub URL.

## How to check it worked

- **`/workspace/setup-done.txt`** — says READY, or lists what failed.
- **`/workspace/setup.log`** — the full log of everything that happened.
- **In ComfyUI, press R** to reload the model lists after new files arrive.
- **To retry a failed download:** run `bash /workspace/setup/download-models.sh`
  in Jupyter Terminal. Files that already downloaded are skipped.

## Troubleshooting

- **A model didn't download:** check the log for `FAIL:` lines. Common
  causes: wrong repo/file name, or a gated model without `HF_TOKEN`.
- **FLUX.1-dev skipped:** it needs `HF_TOKEN` set AND the license accepted
  on its Hugging Face page. Without both, the script skips it on purpose.
- **Out of disk:** rent 200 GB next time, or remove a model from the list.
- **Nodes don't show up:** restart ComfyUI from the instance portal, or
  press R. Node installs only take effect after a restart.
- **No email arrived:** check that `NOTIFY_EMAIL` and
  `GMAIL_APP_PASSWORD` are set in the template, and that the app password
  has no spaces in it. Check `/workspace/setup-done.txt` — if it says
  READY, the server is fine and only the email failed.
