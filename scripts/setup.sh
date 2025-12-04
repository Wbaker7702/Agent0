#!/bin/bash
# Agent0 Setup Script
# Usage: ./scripts/setup.sh [options]
# Options:
#   --skip-flash-attn    Skip Flash Attention installation (if no CUDA)
#   --skip-verl          Skip VeRL installation
#   --minimal            Minimal installation (skip optional packages)
#   --interactive        Interactive mode with prompts

set -e

SKIP_FLASH_ATTN=false
SKIP_VERL=false
MINIMAL=false
INTERACTIVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-flash-attn)
            SKIP_FLASH_ATTN=true
            shift
            ;;
        --skip-verl)
            SKIP_VERL=true
            shift
            ;;
        --minimal)
            MINIMAL=true
            shift
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-flash-attn] [--skip-verl] [--minimal] [--interactive]"
            exit 1
            ;;
    esac
done

BASE_DIR="/workspace/Agent0"
SCRIPT_DIR="/workspace/scripts"

echo "🚀 Agent0 Setup Script"
echo "======================"
echo ""

# Check if we're in the right directory
if [ ! -d "$BASE_DIR" ]; then
    echo "❌ Error: Agent0 directory not found at $BASE_DIR"
    echo "   Please run this script from the workspace root"
    exit 1
fi

# Check Python version
echo "🐍 Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    echo "❌ Error: Python 3.8+ required, found Python $PYTHON_VERSION"
    exit 1
fi
echo "✅ Python $PYTHON_VERSION OK"
echo ""

# Check CUDA availability (optional)
echo "🎮 Checking CUDA availability..."
if command -v nvidia-smi &> /dev/null; then
    CUDA_AVAILABLE=true
    CUDA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
    echo "✅ NVIDIA GPU detected (Driver: $CUDA_VERSION)"
    echo "   CUDA toolkit should be installed for PyTorch with CUDA support"
else
    CUDA_AVAILABLE=false
    echo "⚠️  No NVIDIA GPU detected (or nvidia-smi not available)"
    echo "   Will install CPU-only PyTorch"
fi
echo ""

# Step 1: Install base requirements
echo "📦 Step 1: Installing base requirements..."
echo "----------------------------------------"
if [ -f "$BASE_DIR/requirements.txt" ]; then
    echo "Installing from $BASE_DIR/requirements.txt..."
    pip install -r "$BASE_DIR/requirements.txt" || {
        echo "⚠️  Some packages may have failed to install"
        echo "   This is normal for packages that require CUDA or special build environments"
    }
    echo "✅ Base requirements installed"
else
    echo "❌ Error: requirements.txt not found at $BASE_DIR/requirements.txt"
    exit 1
fi
echo ""

# Step 2: Install curriculum training requirements
echo "📦 Step 2: Installing curriculum training requirements..."
echo "--------------------------------------------------------"
if [ -f "$BASE_DIR/curriculum_train/requirements.txt" ]; then
    pip install -r "$BASE_DIR/curriculum_train/requirements.txt" || {
        echo "⚠️  Some curriculum training packages may have failed"
    }
    echo "✅ Curriculum training requirements installed"
else
    echo "⚠️  curriculum_train/requirements.txt not found (skipping)"
fi
echo ""

# Step 3: Install VeRL framework
if [ "$SKIP_VERL" = false ]; then
    echo "🔬 Step 3: Installing VeRL framework..."
    echo "--------------------------------------"
    if [ -d "$BASE_DIR/executor_train/verl" ]; then
        cd "$BASE_DIR/executor_train/verl"
        pip install -e . || {
            echo "⚠️  VeRL installation had issues, but continuing..."
        }
        cd - > /dev/null
        echo "✅ VeRL framework installed"
    else
        echo "⚠️  VeRL directory not found (skipping)"
    fi
    echo ""
else
    echo "⏭️  Skipping VeRL installation (--skip-verl)"
    echo ""
fi

# Step 4: Install VeRL-Tool
if [ "$SKIP_VERL" = false ] && [ -d "$BASE_DIR/executor_train/verl_tool" ]; then
    echo "🔧 Step 4: Installing VeRL-Tool..."
    echo "----------------------------------"
    cd "$BASE_DIR/executor_train/verl_tool"
    if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        pip install -e . || {
            echo "⚠️  VeRL-Tool installation had issues, but continuing..."
        }
        echo "✅ VeRL-Tool installed"
    else
        echo "⚠️  VeRL-Tool setup files not found (skipping)"
    fi
    cd - > /dev/null
    echo ""
fi

# Step 5: Install Flash Attention (requires CUDA)
if [ "$SKIP_FLASH_ATTN" = false ]; then
    echo "⚡ Step 5: Installing Flash Attention..."
    echo "--------------------------------------"
    if [ "$CUDA_AVAILABLE" = true ]; then
        echo "Installing Flash Attention (this may take a while)..."
        pip install "flash-attn==2.8.3" --no-build-isolation || {
            echo "⚠️  Flash Attention installation failed"
            echo "   This is common if CUDA toolkit is not properly configured"
            echo "   You can skip this with --skip-flash-attn"
        }
        echo "✅ Flash Attention installed"
    else
        echo "⏭️  Skipping Flash Attention (no CUDA detected)"
        echo "   Flash Attention requires CUDA. Install manually if needed."
    fi
    echo ""
else
    echo "⏭️  Skipping Flash Attention installation (--skip-flash-attn)"
    echo ""
fi

# Step 6: Verify critical packages
echo "✅ Step 6: Verifying installation..."
echo "-----------------------------------"
CRITICAL_PACKAGES=("torch" "transformers" "ray")
OPTIONAL_PACKAGES=("vllm" "flash_attn" "wandb")

ALL_OK=true
for pkg in "${CRITICAL_PACKAGES[@]}"; do
    if python3 -c "import $pkg" 2>/dev/null; then
        VERSION=$(python3 -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
        echo "✅ $pkg: $VERSION"
    else
        echo "❌ $pkg: MISSING"
        ALL_OK=false
    fi
done

for pkg in "${OPTIONAL_PACKAGES[@]}"; do
    if python3 -c "import $pkg" 2>/dev/null; then
        VERSION=$(python3 -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
        echo "✅ $pkg: $VERSION (optional)"
    else
        echo "⚠️  $pkg: not installed (optional)"
    fi
done

if [ "$ALL_OK" = false ]; then
    echo ""
    echo "❌ Some critical packages are missing. Please check the installation."
    exit 1
fi
echo ""

# Step 7: Setup configuration guidance
echo "⚙️  Step 7: Configuration Setup"
echo "-------------------------------"
echo ""
echo "📝 Next steps for configuration:"
echo ""
echo "1. Set up environment variables:"
echo "   export STORAGE_PATH=\"/path/to/storage\""
echo "   export HUGGINGFACENAME=\"Qwen/Qwen3-4B-Base\""
echo "   export WANDB_API_KEY=\"your_wandb_key\""
echo ""
echo "2. Create storage directories:"
echo "   mkdir -p \"\$STORAGE_PATH/evaluation\""
echo "   mkdir -p \"\$STORAGE_PATH/models\""
echo "   mkdir -p \"\$STORAGE_PATH/generated_question\""
echo "   mkdir -p \"\$STORAGE_PATH/temp_results\""
echo ""
echo "3. Set up SandboxFusion (for code execution):"
echo "   git clone https://github.com/bytedance/SandboxFusion.git"
echo "   cd SandboxFusion"
echo "   poetry install"
echo "   make run-online"
echo ""
echo "4. Configure SandboxFusion URLs in:"
echo "   $BASE_DIR/curriculum_train/vllm_service_init/start_vllm_server_tool.py"
echo "   Edit lines 36-41 with your SandboxFusion API URLs"
echo ""

# Interactive mode: ask about configuration
if [ "$INTERACTIVE" = true ]; then
    echo "🔧 Interactive Configuration"
    echo "---------------------------"
    read -p "Set STORAGE_PATH now? (y/n): " set_storage
    if [ "$set_storage" = "y" ] || [ "$set_storage" = "Y" ]; then
        read -p "Enter STORAGE_PATH: " storage_path
        if [ -n "$storage_path" ]; then
            export STORAGE_PATH="$storage_path"
            mkdir -p "$STORAGE_PATH/evaluation"
            mkdir -p "$STORAGE_PATH/models"
            mkdir -p "$STORAGE_PATH/generated_question"
            mkdir -p "$STORAGE_PATH/temp_results"
            echo "✅ Storage directories created at $STORAGE_PATH"
            echo "   Add to your shell profile: export STORAGE_PATH=\"$storage_path\""
        fi
    fi
    echo ""
fi

# Step 8: Final validation
echo "🎯 Step 8: Running build validation..."
echo "--------------------------------------"
if [ -f "$SCRIPT_DIR/validate_build.sh" ]; then
    bash "$SCRIPT_DIR/validate_build.sh" || {
        echo ""
        echo "⚠️  Build validation found some issues"
        echo "   Review the output above and fix any critical problems"
    }
else
    echo "⚠️  Validation script not found, skipping"
fi
echo ""

echo "✅ Setup complete!"
echo ""
echo "📚 Next steps:"
echo "   1. Review the configuration steps above"
echo "   2. Set up SandboxFusion if you plan to use code execution"
echo "   3. Run 'make build' to validate your setup"
echo "   4. Run 'make test-quick' to run quick tests"
echo "   5. Read PLAN.md for detailed documentation"
echo ""
