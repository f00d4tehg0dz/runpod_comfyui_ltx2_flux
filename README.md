# Runpod ComfyUI + LTX-2 + Flux (Blackwell-ready) Template

A lightweight Docker image for ComfyUI with LTX-2 video generation and Flux image generation, optimized for Blackwell-class GPUs (RTX 5090, RTX PRO 6000). Based on NVIDIA CUDA 12.8 with PyTorch 2.8.0.

**Models and custom nodes are downloaded at container startup**, keeping the Docker image small and allowing you to control what gets installed via environment variables.

---

## Features

- **Lightweight Docker image** - Only ComfyUI + Python dependencies (~8GB vs 50GB+)
- **Runtime model downloads** - Models downloaded on first startup, skipped if already present
- **Runtime custom node installation** - 30+ nodes installed automatically at startup
- **HuggingFace authentication** - Support for gated model downloads
- **Conditional downloads** - Control what models to download via environment variables
- **Persistent storage friendly** - Perfect for Runpod network volumes
- **Flux.1-dev & Flux 2** text-to-image generation
- **LTX-2 19B Distilled FP8** video generation
- **Audio-driven video synthesis** with MelBandRoFormer
- **Three pre-configured workflows** ready to use

---

## Included Workflows

### 1. LTX2-Audio-Input-FP8-Distilled_Workflow.json
Audio-driven video workflow using:
- LTX-2 19B Distilled FP8 checkpoint
- MelBandRoFormer for audio vocal extraction
- 8-step LCM sampler with simple scheduler
- Image-to-video with audio sync

### 2. LTXV_2_Full.json
Full LTXV pipeline with:
- Multi-stage upscaling
- LoRA/patcher support
- VHS video combine and export

### 3. image_flux2.json
Flux 2 image generation workflow using:
- Flux 2 dev FP8 mixed diffusion model
- Mistral text encoder
- Flux 2 Turbo LoRA for faster generation

---

## Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Clone the repository
git clone https://github.com/f00d4tehg0dz/runpod_comfyui_ltx2_flux.git
cd runpod_comfyui_ltx2_flux

# Copy and edit environment file
cp .env.example .env
# Edit .env and add your HF_TOKEN if needed

# Start ComfyUI
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Option 2: Docker Run

```bash
# Basic run (downloads all public models)
docker run --gpus all -p 8188:8188 f00d4tehg0dz/comfyui-with-flux-ltx2-blackwell:latest

# With HuggingFace token for gated models
docker run --gpus all -p 8188:8188 \
    -e HF_TOKEN=your_token_here \
    f00d4tehg0dz/comfyui-with-flux-ltx2-blackwell:latest

# With persistent storage (recommended)
docker run --gpus all -p 8188:8188 \
    -v comfyui-models:/ComfyUI/models \
    -v comfyui-nodes:/ComfyUI/custom_nodes \
    -e HF_TOKEN=your_token_here \
    f00d4tehg0dz/comfyui-with-flux-ltx2-blackwell:latest
```

### Option 3: Build from Source

1. **Clone this repository:**
   ```bash
   git clone https://github.com/f00d4tehg0dz/runpod_comfyui_ltx2_flux.git
   cd runpod_comfyui_ltx2_flux
   ```

2. **Build the Docker image:**
   ```bash
   python build_docker.py comfyui-with-flux-ltx2-blackwell --latest
   ```

   **Build without pushing to Docker Hub:**
   ```bash
   python build_docker.py comfyui-with-flux-ltx2-blackwell --no-push
   ```

   **Build and run with docker-compose:**
   ```bash
   docker-compose up --build -d
   ```

---

## Environment Variables

Control model downloads and node installation at runtime:

| Variable | Default | Description |
|----------|---------|-------------|
| `HF_TOKEN` | `""` | HuggingFace token for gated model downloads |
| `DOWNLOAD_LTX` | `yes` | Download LTX-2 models (`yes`/`no`) |
| `DOWNLOAD_FLUX` | `yes` | Download Flux 2 models (`yes`/`no`) |
| `DOWNLOAD_FLUX1_GATED` | `no` | Download gated Flux 1 models (`yes`/`no`) |
| `SKIP_MODEL_DOWNLOAD` | `no` | Skip all model downloads (`yes`/`no`) |
| `SKIP_NODE_INSTALL` | `no` | Skip custom node installation (`yes`/`no`) |

### Examples

```bash
# Download only LTX models (skip Flux)
docker run --gpus all -p 8188:8188 \
    -e DOWNLOAD_FLUX=no \
    f00d4tehg0dz/comfyui-with-flux-ltx2-blackwell:latest

# Download everything including gated Flux 1 models
docker run --gpus all -p 8188:8188 \
    -e HF_TOKEN=your_token \
    -e DOWNLOAD_FLUX1_GATED=yes \
    f00d4tehg0dz/comfyui-with-flux-ltx2-blackwell:latest

# Skip downloads (models already on volume)
docker run --gpus all -p 8188:8188 \
    -v /workspace/comfyui:/ComfyUI \
    -e SKIP_MODEL_DOWNLOAD=yes \
    -e SKIP_NODE_INSTALL=yes \
    f00d4tehg0dz/comfyui-with-flux-ltx2-blackwell:latest
```

---

## Models Downloaded at Startup

### LTX-2 Models (DOWNLOAD_LTX=yes)

| Model | Location | Gated |
|-------|----------|-------|
| `ltx-2-19b-distilled-fp8.safetensors` | `/ComfyUI/models/checkpoints/` | No |
| `gemma_3_12B_it_fp8_e4m3fn.safetensors` | `/ComfyUI/models/text_encoders/` | No |
| `MelBandRoformer_fp32.safetensors` | `/ComfyUI/models/diffusion_models/` | No |
| `ltx-2-spatial-upscaler-x2-1.0.safetensors` | `/ComfyUI/models/latent_upscale_models/` | **Yes** |

### Flux 2 Models (DOWNLOAD_FLUX=yes)

| Model | Location | Gated |
|-------|----------|-------|
| `flux2-vae.safetensors` | `/ComfyUI/models/vae/` | No |
| `mistral_3_small_flux2_bf16.safetensors` | `/ComfyUI/models/text_encoders/` | No |
| `flux2_dev_fp8mixed.safetensors` | `/ComfyUI/models/diffusion_models/` | No |
| `Flux_2-Turbo-LoRA_comfyui.safetensors` | `/ComfyUI/models/loras/` | No |

### Flux 1 Gated Models (DOWNLOAD_FLUX1_GATED=yes)

| Model | Location | Gated |
|-------|----------|-------|
| `ae.safetensors` | `/ComfyUI/models/vae/` | **Yes** |
| `flux1-dev.safetensors` | `/ComfyUI/models/diffusion_models/` | **Yes** |

### Always Downloaded (Public Models)

| Model | Location |
|-------|----------|
| `clip_l.safetensors` | `/ComfyUI/models/clip/` |
| `t5xxl_fp8_e4m3fn.safetensors` | `/ComfyUI/models/clip/` |
| `Xlabs-AI_flux-RealismLora.safetensors` | `/ComfyUI/models/xlabs/loras/` |

---

## Custom Nodes (Installed at Startup)

The following 30+ custom nodes are automatically installed on first run:

| Node | Purpose |
|------|---------|
| [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) | Node management |
| [ComfyUI-KJNodes](https://github.com/kijai/ComfyUI-KJNodes) | ImageResizeKJv2, PatchSageAttentionKJ |
| [ComfyUI-MelBandRoFormer](https://github.com/kijai/ComfyUI-MelBandRoFormer) | Audio processing |
| [ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite) | VHS_VideoCombine |
| [rgthree-comfy](https://github.com/rgthree/rgthree-comfy) | Seed node, utilities |
| [was-node-suite-comfyui](https://github.com/WASasquatch/was-node-suite-comfyui) | Text Multiline, MarkdownNote |
| [ComfyUI-Logic](https://github.com/theUpsider/ComfyUI-Logic) | Float node |
| [ComfyUI-Custom-Scripts](https://github.com/pythongosssss/ComfyUI-Custom-Scripts) | MathExpression |
| [ComfyUI-Impact-Pack](https://github.com/ltdrdata/ComfyUI-Impact-Pack) | General utilities |
| [ComfyMath](https://github.com/evanspearman/ComfyMath) | Math operations |
| [ComfyUI_essentials](https://github.com/cubiq/ComfyUI_essentials) | Essential nodes |
| [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF) | GGUF model support |
| [ComfyUI-LTXVideo](https://github.com/Lightricks/ComfyUI-LTXVideo) | LTX Video nodes |
| [ComfyUI-Easy-Use](https://github.com/yolain/ComfyUI-Easy-Use) | Utility nodes |
| [ComfyUI-Monnky-LTXV2](https://github.com/monnky/ComfyUI-Monnky-LTXV2) | Monnky LTXV2 nodes |
| [x-flux-comfyui](https://github.com/XLabs-AI/x-flux-comfyui) | XLabs Flux nodes |
| [ComfyUI-Florence2](https://github.com/kijai/ComfyUI-Florence2) | Florence2 vision |
| [ComfyUI-CogVideoXWrapper](https://github.com/kijai/ComfyUI-CogVideoXWrapper) | CogVideoX support |
| [ComfyUI-segment-anything-2](https://github.com/kijai/ComfyUI-segment-anything-2) | SAM2 segmentation |
| [ComfyUI-SUPIR](https://github.com/kijai/ComfyUI-SUPIR) | SUPIR upscaling |
| [ComfyUI-Flowty-LDSR](https://github.com/flowtyone/ComfyUI-Flowty-LDSR) | LDSR upscaling |
| [ComfyUI_UltimateSDUpscale](https://github.com/ssitu/ComfyUI_UltimateSDUpscale) | Ultimate SD Upscale |
| [comfyui-reactor-node](https://codeberg.org/Gourieff/comfyui-reactor-node) | Face swap |
| [ComfyUI-AdvancedLivePortrait](https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait) | Live portrait |
| [ComfyUI_LayerStyle](https://github.com/chflame163/ComfyUI_LayerStyle) | Layer styling |
| [comfyui_controlnet_aux](https://github.com/Fannovel16/comfyui_controlnet_aux) | ControlNet preprocessors |
| [ComfyUI-Frame-Interpolation](https://github.com/Fannovel16/ComfyUI-Frame-Interpolation) | Frame interpolation |
| [civitai_comfy_nodes](https://github.com/civitai/civitai_comfy_nodes) | Civitai integration |

---

## Runpod Deployment

1. Create a new pod on [Runpod.io](https://runpod.io)
2. Select a Blackwell GPU (RTX 5090, RTX PRO 6000) or compatible
3. Use the Docker image: `f00d4tehg0dz/comfyui-with-flux-ltx2-blackwell:latest`
4. Set minimum disk space: **100GB** (recommended: 150GB)
5. **Add environment variables:**
   - `HF_TOKEN` - Your HuggingFace token (for gated models)
6. Access ComfyUI at port **8188**

### Using Network Volume (Recommended)

Mount a network volume to `/ComfyUI` to persist models and custom nodes:
- First run: Models and nodes are downloaded (~50GB)
- Subsequent runs: Skips existing files, starts instantly

---

## Directory Structure

```
runpod_comfyui_ltx2_flux/
├── README.md
├── build_docker.py
├── docker-compose.yml
├── .env.example
├── workflows/
│   ├── LTX2-Audio-Input-FP8-Distilled_Workflow.json
│   ├── LTXV_2_Full.json
│   └── image_flux2.json
└── comfyui-with-flux-ltx2-blackwell/
    ├── Dockerfile
    └── start.sh
```

---

## Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| GPU | RTX 4090 (24GB) | RTX 5090 / Blackwell |
| VRAM | 24GB | 48GB+ |
| Storage | 100GB | 150GB+ |
| RAM | 32GB | 64GB |

---

## Workflow Paths (Inside Container)

After deployment, workflows are available at:
```
/ComfyUI/user/default/workflows/LTX2-Audio-Input-FP8-Distilled_Workflow.json
/ComfyUI/user/default/workflows/LTXV_2_Full.json
/ComfyUI/user/default/workflows/image_flux2.json
```

---

## Troubleshooting

### First startup is slow
This is expected - models (~30-50GB) and custom nodes are being downloaded. Subsequent starts will be fast if using persistent storage.

### Gated model download failed
- Verify your `HF_TOKEN` environment variable is set correctly
- Ensure you've accepted the model license on HuggingFace
- Check container logs: `docker logs <container_id>`

### Models not loading
- Check if downloads completed: Look for `[OK]` messages in logs
- Verify model files exist in `/ComfyUI/models/`

### Custom nodes not working
- Check if installation completed: Look for `[DONE] Custom nodes installation complete` in logs
- Use ComfyUI-Manager to reinstall if needed

### Out of VRAM
- Use FP8 model variants where possible
- Reduce batch size in workflows
- Enable tiled VAE decoding

---

## Credits

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) - Base framework
- [Lightricks/LTX-2](https://huggingface.co/Lightricks/LTX-2) - LTX-2 video model
- [black-forest-labs/FLUX.1-dev](https://huggingface.co/black-forest-labs/FLUX.1-dev) - Flux image model
- [Comfy-Org/flux2-dev](https://huggingface.co/Comfy-Org/flux2-dev) - Flux 2 models
- [Kijai](https://github.com/kijai) - Many excellent custom nodes

---

## License

This template follows the licenses of the included models and tools. Check individual model cards for specific licensing terms.
