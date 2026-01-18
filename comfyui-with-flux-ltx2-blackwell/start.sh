#!/bin/bash

echo "=============================================="
echo "ComfyUI + LTX-2 + Flux (Blackwell)"
echo "=============================================="
echo "Starting up... $(date)"
echo ""

# Activate virtual environment
source /opt/venv/bin/activate

# ============================================================================
# Environment Variables (set via docker run -e or Runpod)
# ============================================================================
DOWNLOAD_LTX="${DOWNLOAD_LTX:-yes}"
DOWNLOAD_FLUX="${DOWNLOAD_FLUX:-yes}"
DOWNLOAD_FLUX1_GATED="${DOWNLOAD_FLUX1_GATED:-no}"
SKIP_MODEL_DOWNLOAD="${SKIP_MODEL_DOWNLOAD:-no}"
SKIP_NODE_INSTALL="${SKIP_NODE_INSTALL:-no}"

echo "Configuration:"
echo "  DOWNLOAD_LTX: $DOWNLOAD_LTX"
echo "  DOWNLOAD_FLUX: $DOWNLOAD_FLUX"
echo "  DOWNLOAD_FLUX1_GATED: $DOWNLOAD_FLUX1_GATED"
echo "  SKIP_MODEL_DOWNLOAD: $SKIP_MODEL_DOWNLOAD"
echo "  SKIP_NODE_INSTALL: $SKIP_NODE_INSTALL"
echo "  HF_TOKEN: ${HF_TOKEN:+[SET]}"
echo ""

# ============================================================================
# Create directories with proper permissions
# ============================================================================
echo "Setting up directories..."

# Create all required directories
for dir in \
    /ComfyUI/models/checkpoints \
    /ComfyUI/models/clip \
    /ComfyUI/models/vae \
    /ComfyUI/models/loras \
    /ComfyUI/models/text_encoders \
    /ComfyUI/models/diffusion_models \
    /ComfyUI/models/latent_upscale_models \
    /ComfyUI/models/xlabs/loras \
    /ComfyUI/custom_nodes \
    /ComfyUI/output \
    /ComfyUI/input
do
    mkdir -p "$dir" 2>/dev/null || true
    chmod 777 "$dir" 2>/dev/null || true
done

# Test write access
TEST_FILE="/ComfyUI/models/.write_test"
if touch "$TEST_FILE" 2>/dev/null; then
    rm -f "$TEST_FILE"
    echo "Directories ready (write access OK)"
else
    echo "WARNING: Cannot write to /ComfyUI/models - check volume permissions"
    echo "Trying to fix permissions..."
    chown -R $(id -u):$(id -g) /ComfyUI 2>/dev/null || true
    chmod -R 777 /ComfyUI 2>/dev/null || true
fi
echo ""

# ============================================================================
# Helper Functions
# ============================================================================
hf_download() {
    local URL="$1"
    local OUTPUT="$2"
    local DESCRIPTION="$3"
    local OUTPUT_DIR=$(dirname "$OUTPUT")

    # Check if already exists
    if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
        local SIZE=$(du -h "$OUTPUT" 2>/dev/null | cut -f1)
        echo "[SKIP] $DESCRIPTION (exists, $SIZE)"
        return 0
    fi

    echo "[DOWNLOADING] $DESCRIPTION..."
    echo "  -> $OUTPUT"

    # Ensure directory exists and is writable
    mkdir -p "$OUTPUT_DIR" 2>/dev/null
    if [ ! -w "$OUTPUT_DIR" ]; then
        echo "[ERROR] Directory not writable: $OUTPUT_DIR"
        chmod 777 "$OUTPUT_DIR" 2>/dev/null || true
    fi

    # Remove any partial downloads
    rm -f "$OUTPUT" 2>/dev/null

    # Download with wget
    local WGET_EXIT
    if [ -n "$HF_TOKEN" ]; then
        wget --header="Authorization: Bearer $HF_TOKEN" \
             --progress=bar:force:noscroll \
             --tries=3 \
             --timeout=120 \
             --continue \
             -O "$OUTPUT" \
             "$URL" 2>&1
        WGET_EXIT=$?
    else
        wget --progress=bar:force:noscroll \
             --tries=3 \
             --timeout=120 \
             --continue \
             -O "$OUTPUT" \
             "$URL" 2>&1
        WGET_EXIT=$?
    fi

    # Debug output
    if [ $WGET_EXIT -ne 0 ]; then
        echo "[DEBUG] wget exit code: $WGET_EXIT"
    fi

    # Check if file was downloaded successfully
    if [ -f "$OUTPUT" ]; then
        local SIZE=$(du -h "$OUTPUT" 2>/dev/null | cut -f1)
        local BYTES=$(stat -c%s "$OUTPUT" 2>/dev/null || stat -f%z "$OUTPUT" 2>/dev/null || echo "0")
        if [ "$BYTES" -gt 1000 ]; then
            echo "[OK] $DESCRIPTION ($SIZE)"
            return 0
        else
            echo "[FAILED] $DESCRIPTION - file too small ($BYTES bytes)"
            rm -f "$OUTPUT" 2>/dev/null
            return 1
        fi
    else
        echo "[FAILED] $DESCRIPTION - file not created"
        ls -la "$OUTPUT_DIR" 2>/dev/null | head -5
        return 1
    fi
}

clone_node() {
    local REPO="$1"
    local NAME="$(basename "$REPO" .git)"
    local TARGET="/ComfyUI/custom_nodes/$NAME"

    if [ -d "$TARGET" ]; then
        echo "[SKIP] $NAME (exists)"
        return 0
    fi

    echo "[CLONING] $NAME..."
    if git clone --depth 1 -q "$REPO" "$TARGET" 2>/dev/null; then
        # Install requirements if they exist
        if [ -f "$TARGET/requirements.txt" ]; then
            pip install --no-cache-dir -q -r "$TARGET/requirements.txt" 2>/dev/null || true
        fi
        echo "[OK] $NAME"
        return 0
    else
        echo "[FAILED] $NAME"
        return 1
    fi
}

# ============================================================================
# Background Installation Function
# ============================================================================
install_nodes_background() {
    echo ""
    echo "=============================================="
    echo "[NODES] Installing Custom Nodes..."
    echo "=============================================="

    mkdir -p /ComfyUI/custom_nodes
    cd /ComfyUI/custom_nodes

    # Core management
    clone_node "https://github.com/ltdrdata/ComfyUI-Manager.git"
    clone_node "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"

    # Image processing and upscaling
    clone_node "https://github.com/flowtyone/ComfyUI-Flowty-LDSR.git"
    clone_node "https://github.com/kijai/ComfyUI-SUPIR.git"
    clone_node "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"

    # Kijai nodes
    clone_node "https://github.com/kijai/ComfyUI-KJNodes.git"
    clone_node "https://github.com/kijai/ComfyUI-Florence2.git"
    clone_node "https://github.com/kijai/ComfyUI-MelBandRoFormer.git"
    clone_node "https://github.com/kijai/ComfyUI-CogVideoXWrapper.git"
    clone_node "https://github.com/kijai/ComfyUI-segment-anything-2.git"

    # Utility nodes
    clone_node "https://github.com/rgthree/rgthree-comfy.git"
    clone_node "https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git"
    clone_node "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
    clone_node "https://github.com/Jordach/comfy-plasma.git"
    clone_node "https://github.com/theUpsider/ComfyUI-Logic.git"
    clone_node "https://github.com/cubiq/ComfyUI_essentials.git"
    clone_node "https://github.com/chrisgoringe/cg-image-picker.git"
    clone_node "https://github.com/chrisgoringe/cg-use-everywhere.git"

    # Video nodes
    clone_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    clone_node "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
    clone_node "https://github.com/GACLove/ComfyUI-VFI.git"

    # LTX Video nodes
    clone_node "https://github.com/Lightricks/ComfyUI-LTXVideo.git"

    # Impact pack
    clone_node "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    clone_node "https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git"

    # Other useful nodes
    clone_node "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git"
    clone_node "https://github.com/yolain/ComfyUI-Easy-Use.git"
    clone_node "https://github.com/WASasquatch/was-node-suite-comfyui.git"
    clone_node "https://github.com/chflame163/ComfyUI_LayerStyle.git"
    clone_node "https://codeberg.org/Gourieff/comfyui-reactor-node.git"

    # GGUF support
    clone_node "https://github.com/city96/ComfyUI-GGUF.git"

    # Additional LTX/Flux nodes
    clone_node "https://github.com/monnky/ComfyUI-Monnky-LTXV2.git"
    clone_node "https://github.com/evanspearman/ComfyMath.git"

    # Civitai integration
    clone_node "https://github.com/civitai/civitai_comfy_nodes.git"

    echo ""
    echo "[NODES] Custom nodes installation complete!"
    echo "=============================================="
}

download_models_background() {
    echo ""
    echo "=============================================="
    echo "[MODELS] Downloading Models..."
    echo "=============================================="

    # Create model directories
    mkdir -p /ComfyUI/models/checkpoints
    mkdir -p /ComfyUI/models/clip
    mkdir -p /ComfyUI/models/vae
    mkdir -p /ComfyUI/models/loras
    mkdir -p /ComfyUI/models/text_encoders
    mkdir -p /ComfyUI/models/diffusion_models
    mkdir -p /ComfyUI/models/latent_upscale_models

    # ============================================================================
    # Always download: CLIP / Text Encoders (public models)
    # ============================================================================
    echo ""
    echo "[MODELS] --- CLIP / Text Encoders ---"
    hf_download \
        "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true" \
        "/ComfyUI/models/clip/clip_l.safetensors" \
        "CLIP-L (246MB)"

    hf_download \
        "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors?download=true" \
        "/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors" \
        "T5-XXL FP8 (4.89GB)"
   
    # ============================================================================
    # LTX-2 Models (conditional)
    # ============================================================================
    if [ "$DOWNLOAD_LTX" = "yes" ]; then
        echo ""
        echo "[MODELS] --- LTX-2 Models ---"

        hf_download \
            "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-fp8.safetensors?download=true" \
            "/ComfyUI/models/checkpoints/ltx-2-19b-distilled-fp8.safetensors" \
            "LTX-2 19B Distilled FP8 (9.6GB)"

        hf_download \
            "https://huggingface.co/GitMylo/LTX-2-comfy_gemma_fp8_e4m3fn/resolve/main/gemma_3_12B_it_fp8_e4m3fn.safetensors?download=true" \
            "/ComfyUI/models/text_encoders/gemma_3_12B_it_fp8_e4m3fn.safetensors" \
            "Gemma 3 12B FP8 (6.1GB)"

        hf_download \
            "https://huggingface.co/Kijai/MelBandRoFormer_comfy/resolve/main/MelBandRoformer_fp32.safetensors?download=true" \
            "/ComfyUI/models/diffusion_models/MelBandRoformer_fp32.safetensors" \
            "MelBandRoFormer FP32 (148MB)"

        # LTX-2 Latent Upscaler (public)
        hf_download \
            "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors" \
            "/ComfyUI/models/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors" \
            "LTX-2 Spatial Upscaler x2 (1.2GB)"

        # LTX-2 IC-LoRA Detailer
        hf_download \
            "https://huggingface.co/Lightricks/LTX-2-19b-IC-LoRA-Detailer/resolve/main/ltx-2-19b-ic-lora-detailer.safetensors" \
            "/ComfyUI/models/loras/ltx-2-19b-ic-lora-detailer.safetensors" \
            "LTX-2 19B IC-LoRA Detailer"
    else
        echo "[SKIP] LTX-2 models (DOWNLOAD_LTX=no)"
    fi

    # ============================================================================
    # Flux 2 Models (conditional)
    # ============================================================================
    if [ "$DOWNLOAD_FLUX" = "yes" ]; then
        echo ""
        echo "[MODELS] --- Flux 2 Models ---"

        hf_download \
            "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors?download=true" \
            "/ComfyUI/models/vae/flux2-vae.safetensors" \
            "Flux 2 VAE (168MB)"

        hf_download \
            "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/text_encoders/mistral_3_small_flux2_bf16.safetensors?download=true" \
            "/ComfyUI/models/text_encoders/mistral_3_small_flux2_bf16.safetensors" \
            "Mistral 3 Small BF16 (4.6GB)"

        hf_download \
            "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/diffusion_models/flux2_dev_fp8mixed.safetensors?download=true" \
            "/ComfyUI/models/diffusion_models/flux2_dev_fp8mixed.safetensors" \
            "Flux 2 Dev FP8 Mixed (6.1GB)"

        hf_download \
            "https://huggingface.co/ByteZSzn/Flux.2-Turbo-ComfyUI/resolve/main/Flux_2-Turbo-LoRA_comfyui.safetensors?download=true" \
            "/ComfyUI/models/loras/Flux_2-Turbo-LoRA_comfyui.safetensors" \
            "Flux 2 Turbo LoRA (287MB)"
    else
        echo "[SKIP] Flux 2 models (DOWNLOAD_FLUX=no)"
    fi

    # ============================================================================
    # Flux 1 Gated Models (conditional + requires HF_TOKEN)
    # ============================================================================
    if [ "$DOWNLOAD_FLUX1_GATED" = "yes" ]; then
        echo ""
        echo "[MODELS] --- Flux 1 Gated Models ---"

        if [ -n "$HF_TOKEN" ]; then
            hf_download \
                "https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors?download=true" \
                "/ComfyUI/models/vae/ae.safetensors" \
                "Flux 1 VAE (gated, 335MB)"

            hf_download \
                "https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors?download=true" \
                "/ComfyUI/models/diffusion_models/flux1-dev.safetensors" \
                "Flux 1 Dev (gated, 23.8GB)"
        else
            echo "[SKIP] Flux 1 gated models (requires HF_TOKEN)"
        fi
    else
        echo "[SKIP] Flux 1 gated models (DOWNLOAD_FLUX1_GATED=no)"
    fi

    echo ""
    echo "[MODELS] Model downloads complete!"
    echo "=============================================="
}

# ============================================================================
# Start ComfyUI First (so pod doesn't look hung)
# ============================================================================
echo ""
echo "=============================================="
echo "Starting ComfyUI on port 8188..."
echo "=============================================="
echo ""
echo ">>> ComfyUI will be available at: http://localhost:8188"
echo ">>> Downloads will continue in the background"
echo ">>> Check logs for download progress"
echo ""

cd /ComfyUI

# Start ComfyUI in background
python3 main.py --listen --port 8188 &
COMFYUI_PID=$!

# Give ComfyUI a moment to start
sleep 5

echo ""
echo "=============================================="
echo "ComfyUI started (PID: $COMFYUI_PID)"
echo "=============================================="

# ============================================================================
# Run Downloads in Background
# ============================================================================
run_background_tasks() {
    # First install nodes (faster, needed for ComfyUI to work properly)
    if [ "$SKIP_NODE_INSTALL" != "yes" ]; then
        install_nodes_background
    fi

    # Then download models (slower, but ComfyUI can start without them)
    if [ "$SKIP_MODEL_DOWNLOAD" != "yes" ]; then
        download_models_background
    fi

    echo ""
    echo "=============================================="
    echo "All background tasks complete! $(date)"
    echo "=============================================="
    echo ""
    echo "Tip: Refresh your browser to see new nodes."
}

# Start background tasks
run_background_tasks &
BACKGROUND_PID=$!
echo "[BACKGROUND] Installation started (PID: $BACKGROUND_PID)"

echo ""
echo "=============================================="
echo "All background tasks started!"
echo "ComfyUI is ready at: http://localhost:8188"
echo "=============================================="
echo ""
echo "Tip: Reload ComfyUI after nodes finish installing"
echo "     to see new nodes in the menu."
echo ""

# Wait for background tasks to complete
wait $BACKGROUND_PID 2>/dev/null

echo ""
echo "=============================================="
echo "All downloads complete! $(date)"
echo "=============================================="

# Keep container running by waiting for ComfyUI
wait $COMFYUI_PID