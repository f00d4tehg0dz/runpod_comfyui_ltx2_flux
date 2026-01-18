# ============================================================================
# Stage 1: Builder
# ============================================================================
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV VENV_PATH=/opt/venv
ENV PATH="${VENV_PATH}/bin:${PATH}"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    wget \
    curl \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python3 -m venv ${VENV_PATH}

# Install PyTorch with CUDA 12.8 support
RUN pip install --no-cache-dir \
    torch==2.8.0 \
    torchvision==0.23.0 \
    torchaudio==2.8.0 \
    --index-url https://download.pytorch.org/whl/cu128

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI

# Install ComfyUI requirements
WORKDIR /ComfyUI
RUN pip install --no-cache-dir -r requirements.txt

# Install additional Python packages commonly needed by custom nodes
# These are pre-installed to speed up node installation at runtime
RUN pip install --no-cache-dir \
    jupyterlab \
    albumentations \
    sageattention==1.0.6 \
    huggingface_hub \
    opencv-python \
    scikit-image \
    scipy \
    einops \
    transformers \
    accelerate \
    safetensors \
    onnxruntime-gpu \
    ultralytics \
    segment-anything \
    timm \
    ftfy \
    regex \
    tqdm \
    dill \
    numba \
    colour-science \
    rembg

# Install packages that require compilation (need python3-dev headers)
RUN pip install --no-cache-dir insightface || true
RUN pip install --no-cache-dir mediapipe || true

# Prune git history to reduce image size
RUN rm -rf /ComfyUI/.git

# ============================================================================
# Stage 2: Runtime
# ============================================================================
FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VENV_PATH=/opt/venv
ENV PATH="/opt/venv/bin:/usr/local/cuda/bin:${PATH}"
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    gcc \
    git \
    wget \
    curl \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    openssh-server \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install uv package manager (needed for ComfyUI-Manager)
RUN pip install --no-cache-dir uv

# Copy virtual environment from builder
COPY --from=builder ${VENV_PATH} ${VENV_PATH}

# Copy ComfyUI
COPY --from=builder /ComfyUI /ComfyUI

# Create model and custom_nodes directories
RUN mkdir -p /ComfyUI/models/checkpoints \
    /ComfyUI/models/clip \
    /ComfyUI/models/vae \
    /ComfyUI/models/loras \
    /ComfyUI/models/text_encoders \
    /ComfyUI/models/diffusion_models \
    /ComfyUI/models/latent_upscale_models \
    /ComfyUI/custom_nodes \
    /ComfyUI/user/default/workflows

WORKDIR /ComfyUI

# ============================================================================
# Copy workflow files
# ============================================================================
COPY workflows/ /ComfyUI/user/default/workflows/

# ============================================================================
# Copy startup script (handles model downloads and node installation)
# ============================================================================
COPY comfyui-with-flux-ltx2-blackwell/start.sh /start.sh
RUN chmod +x /start.sh

# Expose ports
EXPOSE 8188 8888

WORKDIR /ComfyUI

# ============================================================================
# Environment Variables for Runtime Configuration
# ============================================================================
# Set these via docker run -e or Runpod environment variables:
#
# HF_TOKEN          - HuggingFace token for gated model downloads
# DOWNLOAD_LTX      - "yes" or "no" (default: yes)
# DOWNLOAD_FLUX     - "yes" or "no" (default: yes)
# DOWNLOAD_FLUX1_GATED - "yes" or "no" (default: no, requires HF_TOKEN)
# SKIP_MODEL_DOWNLOAD - "yes" to skip all model downloads
# SKIP_NODE_INSTALL - "yes" to skip custom node installation
# ============================================================================

CMD ["/start.sh"]