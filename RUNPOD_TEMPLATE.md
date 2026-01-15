# ComfyUI + LTX-2 + Flux (Blackwell-Ready)

Run ComfyUI with **LTX-2 video generation** and **Flux image generation**, optimized for NVIDIA Blackwell architecture (RTX 5090, RTX PRO 6000, B200).

First start downloads models and installs custom nodes (takes 5-10 minutes depending on network speed). Watch the logs for progress - when you see this, ComfyUI is ready:

```
==============================================
All background tasks complete!
==============================================
```

**Note:** ComfyUI starts immediately and is accessible while downloads continue in the background. Refresh your browser after nodes finish installing to see them in the menu.

---

## Access

| Port | Service |
|------|---------|
| **8188** | ComfyUI web UI |
| **8888** | JupyterLab |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HF_TOKEN` | - | HuggingFace token for gated model downloads (recommended) |
| `DOWNLOAD_LTX` | `yes` | Download LTX-2 video models (~16GB) |
| `DOWNLOAD_FLUX` | `yes` | Download Flux 2 image models (~11GB) |
| `DOWNLOAD_FLUX1_GATED` | `no` | Download gated Flux 1 models (~24GB, requires `HF_TOKEN`) |
| `SKIP_MODEL_DOWNLOAD` | `no` | Skip all model downloads |
| `SKIP_NODE_INSTALL` | `no` | Skip custom node installation |

---

## Pre-installed Models

### LTX-2 (Video Generation)
- `ltx-2-19b-distilled-fp8.safetensors` - Main checkpoint (9.6GB)
- `gemma_3_12B_it_fp8_e4m3fn.safetensors` - Text encoder (6.1GB)
- `MelBandRoformer_fp32.safetensors` - Audio processing (148MB)
- `ltx-2-spatial-upscaler-x2-1.0.safetensors` - Upscaler (gated, 1.2GB)

### Flux 2 (Image Generation)
- `flux2_dev_fp8mixed.safetensors` - Diffusion model (6.1GB)
- `flux2-vae.safetensors` - VAE (168MB)
- `mistral_3_small_flux2_bf16.safetensors` - Text encoder (4.6GB)
- `Flux_2-Turbo-LoRA_comfyui.safetensors` - Turbo LoRA (287MB)

### Text Encoders
- `clip_l.safetensors` - CLIP-L (246MB)
- `t5xxl_fp8_e4m3fn.safetensors` - T5-XXL FP8 (4.89GB)

---

## Pre-installed Custom Nodes

| Node | Purpose |
|------|---------|
| ComfyUI-Manager | Node management & updates |
| ComfyUI-KJNodes | Image processing utilities |
| ComfyUI-LTXVideo | LTX video generation |
| ComfyUI-MelBandRoFormer | Audio processing |
| ComfyUI-VideoHelperSuite | Video combine & export |
| ComfyUI-Impact-Pack | General utilities |
| ComfyUI-GGUF | GGUF model support |
| ComfyUI_essentials | Essential nodes |
| rgthree-comfy | Seed & utility nodes |
| x-flux-comfyui | XLabs Flux nodes |
| was-node-suite-comfyui | Text & utility nodes |
| ComfyUI-Easy-Use | Workflow utilities |
| ComfyUI-Florence2 | Vision model |
| ComfyUI-SUPIR | SUPIR upscaling |
| comfyui_controlnet_aux | ControlNet preprocessors |
| + 15 more | See full list in README |

---

## Included Workflows

Three pre-configured workflows are available in the ComfyUI workflow browser:

1. **LTX2-Audio-Input-FP8-Distilled_Workflow.json** - Audio-driven video generation
2. **LTXV_2_Full.json** - Full LTX video pipeline with upscaling
3. **image_flux2.json** - Flux 2 image generation with Turbo LoRA

---

## Source Code

This is an open source template. Source code available at:
**[github.com/f00d4tehg0dz/runpod_comfyui_ltx2_flux](https://github.com/f00d4tehg0dz/runpod_comfyui_ltx2_flux)**

---

## Directory Structure

| Path | Description |
|------|-------------|
| `/ComfyUI` | ComfyUI installation |
| `/ComfyUI/models` | All model files |
| `/ComfyUI/custom_nodes` | Custom nodes |
| `/ComfyUI/output` | Generated outputs |
| `/ComfyUI/input` | Input files |
| `/ComfyUI/user/default/workflows` | Pre-installed workflows |

---

## Troubleshooting

### First startup is slow
This is expected - models (~30-50GB) and custom nodes are being downloaded. Watch the logs for progress. Subsequent restarts are fast.

### Models not loading
Check the logs for download errors. Ensure `HF_TOKEN` is set for gated models.