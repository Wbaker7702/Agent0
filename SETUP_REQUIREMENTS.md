# Agent0 Series - Setup Requirements

## 📋 Complete Setup Checklist

### ✅ System Requirements

#### Hardware
- **CPU**: Multi-core processor (8+ cores recommended)
- **RAM**: 32GB+ recommended (16GB minimum)
- **GPU**: NVIDIA GPU with CUDA support (optional but highly recommended)
  - CUDA 12.x compatible GPU
  - 16GB+ VRAM recommended for training
  - Multiple GPUs for distributed training

#### Software
- **OS**: Linux (Ubuntu 20.04+ recommended) or macOS
- **Python**: 3.8, 3.9, 3.10, 3.11, or 3.12
- **CUDA Toolkit**: 12.x (if using GPU)
- **NCCL**: For distributed training (usually comes with CUDA)

### 📦 Python Dependencies

#### Core Dependencies (Required)
- PyTorch 2.7-2.8
- Transformers 4.52-4.57
- Ray 2.46-2.51
- Accelerate
- HuggingFace Hub

#### Important Dependencies (Recommended)
- vLLM 0.9-0.11 (for inference)
- Flash Attention 2.7-2.8 (for GPU acceleration)
- WandB (for experiment tracking)
- SGLang (for multi-turn interactions)

#### Optional Dependencies
- SandboxFusion (for code execution - external service)
- Poetry (for SandboxFusion setup)

### 🔧 Installation Methods

#### Method 1: Automated Setup (Recommended)
```bash
# Run the setup script
./scripts/setup.sh

# Or with options
./scripts/setup.sh --interactive    # Interactive mode
./scripts/setup.sh --skip-flash-attn # Skip Flash Attention (if no CUDA)
./scripts/setup.sh --minimal         # Minimal installation
```

#### Method 2: Manual Installation
```bash
# 1. Base requirements
cd Agent0
pip install -r requirements.txt

# 2. Curriculum training requirements
cd curriculum_train
pip install -r requirements.txt
cd ..

# 3. VeRL framework
cd executor_train/verl
pip install -e .
cd ..

# 4. Flash Attention (if GPU available)
pip install "flash-attn==2.8.3" --no-build-isolation
```

#### Method 3: Using Makefile
```bash
make install
```

### 🌐 External Services

#### 1. SandboxFusion (Required for Code Execution)

SandboxFusion is required for the curriculum agent to execute generated code.

**Setup:**
```bash
git clone https://github.com/bytedance/SandboxFusion.git
cd SandboxFusion
poetry install
make run-online
```

**Configuration:**
Edit `Agent0/curriculum_train/vllm_service_init/start_vllm_server_tool.py`:
```python
SANDBOX_API_URLS = [
    'http://localhost:8000/run_code',  # Update with your SandboxFusion URLs
    # Add more URLs for load balancing
]
```

#### 2. vLLM Server (Optional)

For running inference servers separately:
```bash
cd Agent0/curriculum_train/vllm_service_init/
bash start.sh
```

#### 3. Ray Cluster (For Distributed Training)

**Local (single machine):**
```bash
ray start --head
```

**Distributed (multiple machines):**
```bash
# On head node
ray start --head --port=6379

# On worker nodes
ray start --address=HEAD_NODE_IP:6379
```

### 🔐 Environment Variables

#### Required Variables
```bash
export STORAGE_PATH="/path/to/storage"           # Storage for models and data
export HUGGINGFACENAME="Qwen/Qwen3-4B-Base"       # HuggingFace model name
```

#### Optional Variables
```bash
export WANDB_API_KEY="your_wandb_key"            # For experiment tracking
export VLLM_DISABLE_COMPILE_CACHE=1               # Disable vLLM cache
export NCCL_DEBUG=INFO                            # NCCL debugging
export TORCH_NCCL_AVOID_RECORD_STREAMS=1         # NCCL optimization
export TOKENIZERS_PARALLELISM=true               # Tokenizer parallelism
```

#### Storage Directory Structure
```bash
mkdir -p "$STORAGE_PATH/evaluation"
mkdir -p "$STORAGE_PATH/models"
mkdir -p "$STORAGE_PATH/generated_question"
mkdir -p "$STORAGE_PATH/temp_results"
```

### 📁 File Structure Requirements

The following directories must exist:
```
Agent0/
├── curriculum_train/
│   ├── scripts/
│   ├── question_generate/
│   ├── question_evaluate/
│   └── vllm_service_init/
├── executor_train/
│   ├── verl/
│   ├── verl_tool/
│   └── examples/
└── requirements.txt
```

### 🐳 Containerization (Optional)

Docker files are available in `Agent0/executor_train/verl/docker/` for containerized deployments.

**Example:**
```bash
# Build Docker image
docker build -f Agent0/executor_train/verl/docker/Dockerfile.ngc.vllm0.8 -t agent0:latest .

# Run container
docker run --gpus all -it agent0:latest
```

### 🔍 Verification

After installation, verify your setup:

```bash
# Run build validation
make build

# Or use the script directly
./scripts/validate_build.sh

# Run quick tests
make test-quick
```

### ⚠️ Common Issues

#### 1. CUDA Not Available
- **Issue**: PyTorch installed but CUDA not detected
- **Solution**: Install PyTorch with CUDA support from https://pytorch.org/

#### 2. Flash Attention Installation Fails
- **Issue**: Flash Attention requires CUDA and specific build tools
- **Solution**: 
  - Ensure CUDA toolkit is installed
  - Install build essentials: `apt-get install build-essential`
  - Or skip with: `./scripts/setup.sh --skip-flash-attn`

#### 3. Ray Connection Issues
- **Issue**: Cannot connect to Ray cluster
- **Solution**: 
  - Check if Ray is running: `ray status`
  - Start Ray: `ray start --head`
  - Check firewall settings for distributed setups

#### 4. SandboxFusion Connection Fails
- **Issue**: Cannot connect to SandboxFusion
- **Solution**:
  - Verify SandboxFusion is running
  - Check URLs in `start_vllm_server_tool.py`
  - Test connection: `curl http://SANDBOX_URL/run_code`

#### 5. Out of Memory
- **Issue**: CUDA out of memory errors
- **Solution**:
  - Reduce batch size in config files
  - Use gradient checkpointing
  - Use smaller models
  - Enable CPU offloading

### 📚 Additional Resources

- **Setup Script**: `./scripts/setup.sh`
- **Validation Script**: `./scripts/validate_build.sh`
- **Quick Reference**: `QUICK_REFERENCE.md`
- **Comprehensive Plan**: `PLAN.md`
- **Project README**: `Agent0/README.md`

### 🆘 Getting Help

1. Run diagnostics: `make debug-config`
2. Check logs: `make debug-logs`
3. Validate setup: `make build`
4. Review documentation: `PLAN.md`

---

*Last Updated: 2025-01-XX*
