#!/bin/bash
# Agent0 Build Validation Script
# Usage: ./scripts/validate_build.sh

# Don't exit on error - we want to check everything and provide comprehensive feedback
set +e

echo "🏗️ Agent0 Build Validation"
echo "==========================="
echo ""

VALIDATION_PASSED=true
CRITICAL_MISSING=false
WARNINGS=0

# Check Python version
echo "🐍 Python Version Check"
PYTHON_VERSION=$(python3 --version 2>&1)
if [ $? -ne 0 ]; then
    echo "❌ Python not found"
    echo "   Install Python 3.8+ from https://www.python.org/"
    CRITICAL_MISSING=true
    VALIDATION_PASSED=false
else
    echo "$PYTHON_VERSION"
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | grep -oP '\d+' | head -1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | grep -oP '\.\K\d+' | head -1)
    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
        echo "⚠️  Python 3.8+ required, found Python $PYTHON_MAJOR.$PYTHON_MINOR"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "✅ Python version OK"
    fi
fi
echo ""

# Check CUDA availability (before checking PyTorch)
echo "🎮 CUDA/GPU Check"
if command -v nvidia-smi &> /dev/null; then
    CUDA_AVAILABLE=true
    GPU_INFO=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader | head -1)
    echo "✅ NVIDIA GPU detected: $GPU_INFO"
else
    CUDA_AVAILABLE=false
    echo "⚠️  No NVIDIA GPU detected (or nvidia-smi not available)"
    echo "   CPU-only mode will be used"
fi
echo ""

# Check PyTorch and CUDA
echo "🔥 PyTorch Check"
PYTORCH_OK=false
if python3 -c "import torch" 2>/dev/null; then
    PYTORCH_VERSION=$(python3 -c "import torch; print(torch.__version__)" 2>/dev/null)
    echo "✅ PyTorch installed: $PYTORCH_VERSION"
    PYTORCH_OK=true
    
    # Check CUDA support in PyTorch
    if python3 -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
        CUDA_VERSION=$(python3 -c "import torch; print(torch.version.cuda)" 2>/dev/null)
        echo "✅ CUDA support available: $CUDA_VERSION"
    else
        if [ "$CUDA_AVAILABLE" = true ]; then
            echo "⚠️  CUDA GPU detected but PyTorch CUDA support not available"
            echo "   Install PyTorch with CUDA: https://pytorch.org/get-started/locally/"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "ℹ️  CPU-only PyTorch (no GPU detected)"
        fi
    fi
else
    echo "❌ PyTorch not installed"
    echo ""
    echo "   Installation options:"
    echo "   1. Run setup script: ./scripts/setup.sh"
    echo "   2. Manual install: pip install torch torchvision torchaudio"
    echo "   3. With CUDA: Visit https://pytorch.org/get-started/locally/"
    CRITICAL_MISSING=true
    VALIDATION_PASSED=false
fi
echo ""

# Check critical packages
echo "📦 Package Check"
echo "---------------"

# Critical packages (must have)
CRITICAL_PACKAGES=(
    "torch:PyTorch"
    "transformers:HuggingFace Transformers"
    "ray:Ray"
)

# Important packages (should have)
IMPORTANT_PACKAGES=(
    "vllm:vLLM"
    "accelerate:Accelerate"
    "wandb:Weights & Biases"
)

# Optional packages (nice to have)
OPTIONAL_PACKAGES=(
    "flash_attn:Flash Attention"
)

MISSING_CRITICAL=()
MISSING_IMPORTANT=()
MISSING_OPTIONAL=()

for pkg_info in "${CRITICAL_PACKAGES[@]}"; do
    pkg=$(echo $pkg_info | cut -d: -f1)
    name=$(echo $pkg_info | cut -d: -f2)
    if python3 -c "import $pkg" 2>/dev/null; then
        VERSION=$(python3 -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
        echo "✅ $name ($pkg): $VERSION"
    else
        echo "❌ $name ($pkg): MISSING (CRITICAL)"
        MISSING_CRITICAL+=("$pkg")
        CRITICAL_MISSING=true
        VALIDATION_PASSED=false
    fi
done

for pkg_info in "${IMPORTANT_PACKAGES[@]}"; do
    pkg=$(echo $pkg_info | cut -d: -f1)
    name=$(echo $pkg_info | cut -d: -f2)
    if python3 -c "import $pkg" 2>/dev/null; then
        VERSION=$(python3 -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
        echo "✅ $name ($pkg): $VERSION"
    else
        echo "⚠️  $name ($pkg): MISSING (important)"
        MISSING_IMPORTANT+=("$pkg")
        WARNINGS=$((WARNINGS + 1))
    fi
done

for pkg_info in "${OPTIONAL_PACKAGES[@]}"; do
    pkg=$(echo $pkg_info | cut -d: -f1)
    name=$(echo $pkg_info | cut -d: -f2)
    if python3 -c "import $pkg" 2>/dev/null; then
        VERSION=$(python3 -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
        echo "✅ $name ($pkg): $VERSION"
    else
        echo "ℹ️  $name ($pkg): not installed (optional)"
        MISSING_OPTIONAL+=("$pkg")
    fi
done

echo ""

# Check VeRL installation
echo "🔬 VeRL Framework Check"
if [ -d "/workspace/Agent0/executor_train/verl" ]; then
    cd /workspace/Agent0/executor_train/verl 2>/dev/null
    if python3 -c "import verl" 2>/dev/null; then
        echo "✅ VeRL framework installed"
    else
        echo "⚠️  VeRL not installed"
        echo "   Install with: cd Agent0/executor_train/verl && pip install -e ."
        echo "   Or run: ./scripts/setup.sh"
        WARNINGS=$((WARNINGS + 1))
    fi
    cd - > /dev/null
else
    echo "⚠️  VeRL directory not found at Agent0/executor_train/verl"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check file structure
echo "📁 File Structure Check"
REQUIRED_DIRS=(
    "Agent0/curriculum_train"
    "Agent0/executor_train"
    "Agent0/curriculum_train/scripts"
    "Agent0/executor_train/examples"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "/workspace/$dir" ]; then
        echo "✅ $dir exists"
    else
        echo "❌ $dir missing"
        VALIDATION_PASSED=false
    fi
done
echo ""

# Check configuration files
echo "⚙️  Configuration Files Check"
CONFIG_FILES=(
    "Agent0/requirements.txt"
    "Agent0/curriculum_train/requirements.txt"
    "Agent0/curriculum_train/scripts/curriculum_train.sh"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "/workspace/$file" ]; then
        echo "✅ $file exists"
    else
        echo "⚠️  $file missing (may be optional)"
    fi
done
echo ""

# Check external services (if configured)
echo "🌐 External Services Check"
if [ -f "/workspace/Agent0/curriculum_train/vllm_service_init/start_vllm_server_tool.py" ]; then
    echo "✅ vLLM service script found"
    # Check if sandbox URLs are configured
    if grep -q "SANDBOX_API_URLS" /workspace/Agent0/curriculum_train/vllm_service_init/start_vllm_server_tool.py; then
        echo "⚠️  Sandbox URLs may need configuration"
    fi
else
    echo "⚠️  vLLM service script not found"
fi
echo ""

echo "✅ Build validation complete!"
echo ""
echo "Next steps:"
echo "1. Configure SandboxFusion URLs if needed"
echo "2. Set environment variables (STORAGE_PATH, WANDB_API_KEY, etc.)"
echo "3. Run tests: ./scripts/run_tests.sh"
