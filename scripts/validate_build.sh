#!/bin/bash
# Agent0 Build Validation Script
# Usage: ./scripts/validate_build.sh

set -e

echo "🏗️ Agent0 Build Validation"
echo "==========================="
echo ""

# Check Python version
echo "🐍 Python Version Check"
python3 --version
if [ $? -ne 0 ]; then
    echo "❌ Python not found"
    exit 1
fi
echo "✅ Python OK"
echo ""

# Check CUDA availability
echo "🎮 CUDA Check"
python3 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'CUDA Version: {torch.version.cuda if torch.cuda.is_available() else \"N/A\"}')" || {
    echo "❌ PyTorch/CUDA check failed"
    exit 1
}
echo "✅ CUDA OK"
echo ""

# Check critical packages
echo "📦 Critical Package Check"
PACKAGES=(
    "torch"
    "transformers"
    "ray"
    "vllm"
    "flash_attn"
    "accelerate"
    "wandb"
)

for pkg in "${PACKAGES[@]}"; do
    python3 -c "import $pkg; print(f'✅ $pkg: OK')" 2>/dev/null || {
        if [ "$pkg" == "flash_attn" ]; then
            if ! python3 -c "import torch; exit(0 if torch.cuda.is_available() else 1)"; then
                echo "⚠️  $pkg: SKIPPED (No CUDA)"
                continue
            fi
        fi
        echo "❌ $pkg: MISSING"
        MISSING=1
    }
done

if [ -n "$MISSING" ]; then
    echo ""
    echo "⚠️  Some packages are missing. Install with:"
    echo "   pip install -r Agent0/requirements.txt"
    exit 1
fi
echo ""

# Check VeRL installation
echo "🔬 VeRL Framework Check"
cd /workspace/Agent0/executor_train/verl 2>/dev/null || {
    echo "❌ VeRL directory not found"
    exit 1
}

python3 -c "import verl; print('✅ VeRL: OK')" 2>/dev/null || {
    echo "⚠️  VeRL not installed. Install with:"
    echo "   cd Agent0/executor_train/verl && pip install -e ."
}
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
        exit 1
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
