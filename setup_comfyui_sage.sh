#!/bin/bash

echo "=========================================="
echo "ComfyUI + SageAttention 2.2 Setup"
echo "For RTX 5070 Ti + CUDA 12.8 + PyTorch 2.8"
echo "Ubuntu 24.04 + Python 3.12"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
apt update && apt upgrade -y

# Install base packages
echo "Installing base packages..."
apt install -y build-essential git wget cmake pkg-config ninja-build unzip aria2 fuser

echo "System Python version: $(python3 --version)"

# Set up workspace
mkdir -p /workspace && cd /workspace

# Clone ComfyUI if not exists
if [ ! -d "ComfyUI" ]; then
    echo "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git
else
    echo "ComfyUI already exists, updating..."
    cd ComfyUI && git pull && cd ..
fi

cd ComfyUI

# Create and activate Python 3.12 virtual environment
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

echo "Virtualenv Python version: $(python --version)"

# Upgrade pip
pip install --upgrade pip

echo "=========================================="
echo "Installing PyTorch 2.8.0 + CUDA 12.8"
echo "=========================================="

# Install PyTorch 2.8.0 with CUDA 12.8 (matching your system)
pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128

echo "=========================================="
echo "Installing Triton + SageAttention 2.2"
echo "=========================================="

# Install Triton (nightly for RTX 50xx Blackwell support)
pip install triton --pre

# Install packaging
pip install packaging

# Download and install SageAttention 2.2
cd /workspace
if [ ! -f "sageattention-2.2.0-cp312-cp312-linux_x86_64.whl" ]; then
    echo "Downloading SageAttention 2.2 wheel..."
    wget https://huggingface.co/Ovidijusk80/sageattention-2.2.0-cp312-cp312-linux_x86_64.whl/resolve/main/sageattention-2.2.0-cp312-cp312-linux_x86_64.whl
fi

echo "Installing SageAttention 2.2..."
pip install ./sageattention-2.2.0-cp312-cp312-linux_x86_64.whl

echo "=========================================="
echo "Verifying Installation"
echo "=========================================="

python -c "import torch; print('✓ PyTorch:', torch.__version__)"
python -c "import torch; print('✓ CUDA:', torch.version.cuda)"
python -c "import torch; print('✓ CUDA available:', torch.cuda.is_available())"
python -c "import torch; print('✓ GPU:', torch.cuda.get_device_name(0))"
python -c "import torch; print('✓ Compute Capability:', torch.cuda.get_device_capability())"
python -c "import triton; print('✓ Triton:', triton.__version__)"
python -c "import sageattention; print('✓ SageAttention: 2.2.0 installed')"

echo "=========================================="
echo "Installing ComfyUI Requirements"
echo "=========================================="

cd /workspace/ComfyUI
pip install -r requirements.txt

echo "=========================================="
echo "Installing ComfyUI Custom Nodes"
echo "=========================================="

cd custom_nodes

# ComfyUI Manager
if [ ! -d "ComfyUI-Manager" ]; then
    echo "Installing ComfyUI-Manager..."
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git
    cd ComfyUI-Manager && pip install -r requirements.txt 2>/dev/null || pip install gitpython && cd ..
fi

# KJ Nodes (for SageAttention patch)
if [ ! -d "ComfyUI-KJNodes" ]; then
    echo "Installing ComfyUI-KJNodes..."
    git clone https://github.com/kijai/ComfyUI-KJNodes.git
    cd ComfyUI-KJNodes && pip install -r requirements.txt 2>/dev/null && cd ..
fi

# GGUF Support
if [ ! -d "ComfyUI-GGUF" ]; then
    echo "Installing ComfyUI-GGUF..."
    git clone https://github.com/city96/ComfyUI-GGUF.git
    cd ComfyUI-GGUF && pip install -r requirements.txt 2>/dev/null && cd ..
fi

# rgthree (for workflow switches)
if [ ! -d "rgthree-comfy" ]; then
    echo "Installing rgthree-comfy..."
    git clone https://github.com/rgthree/rgthree-comfy.git
    cd rgthree-comfy && pip install -r requirements.txt 2>/dev/null && cd ..
fi

# WAN Block Swap
if [ ! -d "ComfyUI-WanBlockSwap" ]; then
    echo "Installing ComfyUI-WanBlockSwap..."
    git clone https://github.com/kijai/ComfyUI-WanBlockSwap.git
fi

# Video Helper Suite
if [ ! -d "ComfyUI-VideoHelperSuite" ]; then
    echo "Installing ComfyUI-VideoHelperSuite..."
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt 2>/dev/null && cd ..
fi

# Frame Interpolation (RIFE)
if [ ! -d "ComfyUI-Frame-Interpolation" ]; then
    echo "Installing ComfyUI-Frame-Interpolation..."
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git
    cd ComfyUI-Frame-Interpolation && pip install -r requirements.txt 2>/dev/null && cd ..
fi

# ComfyUI Essentials
if [ ! -d "ComfyUI_essentials" ]; then
    echo "Installing ComfyUI_essentials..."
    git clone https://github.com/cubiq/ComfyUI_essentials.git
    cd ComfyUI_essentials && pip install -r requirements.txt 2>/dev/null && cd ..
fi

# MediaMixer (for FinalFrameSelector)
if [ ! -d "ComfyUI-MediaMixer" ]; then
    echo "Installing ComfyUI-MediaMixer..."
    git clone https://github.com/kijai/ComfyUI-MediaMixer.git
fi

# Various (fix soundfile error)
echo "Installing additional dependencies..."
pip install soundfile librosa pydub

echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "System Configuration:"
echo "- OS: Ubuntu 24.04 LTS"
echo "- Python: 3.12.11"
echo "- PyTorch: 2.8.0"
echo "- CUDA: 12.8"
echo "- GPU: RTX 5070 Ti (16GB)"
echo "- SageAttention: 2.2.0"
echo ""
echo "Installed Custom Nodes:"
echo "✓ ComfyUI-Manager"
echo "✓ ComfyUI-KJNodes (SageAttention support)"
echo "✓ ComfyUI-GGUF"
echo "✓ rgthree-comfy (workflow switches)"
echo "✓ ComfyUI-WanBlockSwap"
echo "✓ ComfyUI-VideoHelperSuite"
echo "✓ ComfyUI-Frame-Interpolation (RIFE)"
echo "✓ ComfyUI_essentials"
echo "✓ ComfyUI-MediaMixer"
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Download models:"
echo "   cd /workspace/ComfyUI/models"
echo "   ./download_wan22_models.sh"
echo ""
echo "2. Start ComfyUI:"
echo "   cd /workspace/ComfyUI"
echo "   source venv/bin/activate"
echo "   python main.py --listen 0.0.0.0 --port 8188"
echo ""
echo "3. Load workflow and configure:"
echo "   - SageAttention mode: sageattn_qk_int8_pv_fp8_cuda"
echo "   - Resolution: 720x480 or 640x384"
echo "   - Frames: 49-81"
echo "   - RIFE: multiplier=2 or disable"
echo ""
echo "=========================================="