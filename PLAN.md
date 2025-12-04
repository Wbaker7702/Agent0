# Agent0 Series: Comprehensive Development & Deployment Plan

## 📋 Table of Contents
1. [Explorer](#explorer)
2. [Search](#search)
3. [Build](#build)
4. [Debug](#debug)
5. [Validate](#validate)
6. [Audit](#audit)
7. [Deploy](#deploy)
8. [Integrate](#integrate)

---

## 🔍 Explorer

### 1.1 Codebase Structure Analysis

#### Agent0 (Language Agent)
- **Location**: `/workspace/Agent0/`
- **Components**:
  - `curriculum_train/`: Curriculum agent training pipeline
    - `question_generate/`: Task generation module
    - `question_evaluate/`: Task evaluation and filtering
    - `scripts/`: Training scripts
    - `verl/`: VeRL framework integration
  - `executor_train/`: Executor agent training pipeline
    - `verl_tool/`: Tool-integrated RL framework
    - `eval_service/`: Evaluation API service
    - `examples/`: Training examples and configurations

#### Agent0-VL (Vision-Language Agent)
- **Location**: `/workspace/Agent0-VL/`
- **Status**: Code release coming soon (per README)
- **Components**: Currently documentation only

### 1.2 Key Dependencies
- **Core ML**: PyTorch 2.7-2.8, Transformers 4.52-4.57
- **RL Framework**: VeRL (custom), Ray 2.46-2.51
- **Inference**: vLLM 0.9-0.11, SGLang
- **Tools**: Flash Attention 2.7-2.8, SandboxFusion
- **Monitoring**: WandB, TensorBoard

### 1.3 Architecture Patterns
- **Co-evolution**: Curriculum Agent ↔ Executor Agent
- **Tool Integration**: Code interpreter, search, vision APIs
- **Multi-turn RL**: ADPO, GRPO, DAPO algorithms
- **Distributed Training**: FSDP, Megatron-LM support

---

## 🔎 Search

### 2.1 Component Discovery Strategy

#### Search Patterns
```bash
# Find all training scripts
find . -name "*train*.sh" -type f

# Find configuration files
find . -name "*.yaml" -type f | grep -E "(config|train)"

# Find entry points
grep -r "if __name__" --include="*.py"

# Find API endpoints
grep -r "@app\." --include="*.py"
grep -r "FastAPI\|Flask" --include="*.py"
```

#### Key Components to Locate
1. **Training Entry Points**:
   - `curriculum_train/scripts/curriculum_train.sh`
   - `executor_train/examples/train/math_tir/train_qwen3_4b_adpo.sh`
   - `executor_train/verl_tool/trainer/main.py`

2. **Evaluation Services**:
   - `executor_train/eval_service/`
   - `curriculum_train/question_evaluate/evaluate.py`

3. **Tool Servers**:
   - `executor_train/verl_tool/servers/`
   - SandboxFusion integration points

4. **Model Checkpoints**:
   - Checkpoint managers: `verl/utils/checkpoint/`
   - Model merging: `curriculum_train/scripts/model_merger.py`

### 2.2 Dependency Mapping
- **External Services**: SandboxFusion, vLLM servers, Ray cluster
- **Model Sources**: HuggingFace (Qwen models)
- **Storage**: WandB, local filesystem, S3 (via boto3)

---

## 🏗️ Build

### 3.1 Environment Setup

#### Prerequisites
```bash
# System Requirements
- CUDA 12.x compatible GPUs
- Python 3.8+
- CUDA toolkit 12.x
- NCCL for distributed training
```

#### Installation Steps

**Step 1: Install Dependencies**
It is recommended to use the provided `Makefile` to install all dependencies. This ensures a consistent and correct setup.

```bash
make install

### 3.2 External Service Setup

#### SandboxFusion Service
```bash
# Clone and setup SandboxFusion
git clone https://github.com/bytedance/SandboxFusion.git
cd SandboxFusion
poetry install
make run-online

# Configure in Agent0
# Edit: curriculum_train/vllm_service_init/start_vllm_server_tool.py
# Lines 36-41: Add sandbox API URLs
```

#### vLLM Server Initialization
```bash
cd curriculum_train/vllm_service_init/
bash start.sh
```

### 3.3 Build Validation
```bash
# Verify installations
python -c "import torch; print(torch.__version__)"
python -c "import flash_attn; print('Flash Attention OK')"
python -c "import ray; print(ray.__version__)"
python -c "import vllm; print(vllm.__version__)"

# Test VeRL installation
cd executor_train/verl
python -m pytest tests/ -v -k "test_basic" --tb=short
```

---

## 🐛 Debug

### 4.1 Debugging Tools & Strategies

#### Logging Infrastructure
- **WandB**: Training metrics and visualization
- **TensorBoard**: Local training logs
- **Python Logging**: Structured logging via `verl/utils/logger/`

#### Debug Configuration
```python
# Enable debug mode in training scripts
export DEBUG=1
export LOG_LEVEL=DEBUG

# Ray debugging
export RAY_BACKEND_LOG_LEVEL=debug
```

#### Common Debug Scenarios

**1. CUDA Memory Issues**
```bash
# Monitor GPU memory
watch -n 1 nvidia-smi

# Reduce batch size in config files
# Look for: batch_size, micro_batch_size, gradient_accumulation_steps
```

**2. Distributed Training Issues**
```bash
# Test Ray cluster
ray status

# Check worker connectivity
python -c "import ray; ray.init(); print(ray.nodes())"
```

**3. Tool Execution Failures**
```bash
# Test SandboxFusion connection
curl -X POST http://SANDBOX_IP:PORT/run_code \
  -H "Content-Type: application/json" \
  -d '{"code": "print(1+1)"}'

# Check tool server logs
tail -f verl_tool/servers/logs/*.log
```

**4. Model Loading Issues**
```bash
# Verify model access
python -c "from transformers import AutoModel; AutoModel.from_pretrained('Qwen/Qwen3-4B-Base')"

# Check checkpoint integrity
python curriculum_train/scripts/model_merger.py --check-only
```

### 4.2 Debugging Scripts
- **Profile Training**: Use `py-spy` for performance profiling
- **Trace Execution**: Enable detailed logging in `verl/utils/logger/`
- **Memory Profiling**: Use `torch.profiler` for memory analysis

---

## ✅ Validate

### 5.1 Testing Strategy

#### Unit Tests
```bash
# Run VeRL unit tests
cd executor_train/verl
pytest tests/ -v

# Run tool server tests
cd verl_tool/servers/tests/
pytest test_*.py -v

# Run evaluation service tests
cd executor_train/eval_service/test/
pytest test_api.py -v
```

#### Integration Tests
```bash
# Test curriculum training pipeline
cd curriculum_train/
bash scripts/curriculum_train.sh Qwen/Qwen3-4B-Base Qwen/Qwen3-4B-Base test_run --dry-run

# Test executor training (small scale)
cd executor_train/
bash examples/train/math_tir/train_qwen3_4b_adpo.sh --test-mode
```

#### End-to-End Validation
```bash
# Full pipeline test (requires GPU)
# 1. Train curriculum agent (1 iteration)
# 2. Generate questions
# 3. Evaluate questions
# 4. Train executor agent (1 step)
# 5. Validate checkpoint
```

### 5.2 Benchmark Validation

#### Mathematical Reasoning Benchmarks
- **MATH**: Verify accuracy > 78%
- **GSM8K**: Verify accuracy > 89%
- **AMC**: Verify accuracy > 52%

#### General Reasoning Benchmarks
- **MMLU-Pro**: Verify accuracy > 51%
- **SuperGPQA**: Verify accuracy > 28%

### 5.3 CI/CD Validation
- **Pre-commit**: Code formatting and linting
- **GitHub Actions**: Automated testing (see `.github/workflows/`)
- **Type Checking**: mypy validation
- **Security Scanning**: Dependabot, secret scanning

---

## 🔒 Audit

### 5.1 Code Quality Audit

#### Static Analysis
```bash
# Install audit tools
pip install pylint black flake8 mypy bandit safety

# Code formatting check
black --check --diff .

# Linting
flake8 . --max-line-length=120 --exclude=venv,__pycache__

# Type checking
mypy . --ignore-missing-imports

# Security audit
bandit -r . -ll
safety check
```

#### Code Review Checklist
- [ ] Security: No hardcoded credentials
- [ ] Performance: Efficient data loading and batching
- [ ] Error Handling: Proper exception handling
- [ ] Documentation: Docstrings for public APIs
- [ ] Testing: Unit tests for critical paths

### 5.2 Dependency Audit

#### Vulnerability Scanning
```bash
# Check for known vulnerabilities
pip install pip-audit
pip-audit

# Update dependencies
pip list --outdated
```

#### License Compliance
- Verify all dependencies are compatible with Apache 2.0
- Check for GPL dependencies that may require disclosure

### 5.3 Performance Audit

#### Training Efficiency
- Monitor GPU utilization (target: >80%)
- Check for data loading bottlenecks
- Verify distributed training scaling

#### Memory Audit
- Profile memory usage during training
- Check for memory leaks in long-running processes
- Optimize batch sizes for available hardware

---

## 🚀 Deploy

### 6.1 Deployment Architecture

#### Training Deployment
```
┌─────────────────┐
│  Ray Cluster    │
│  (Controller)   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌──▼────┐
│Actor  │ │Critic │
│Worker │ │Worker │
└───────┘ └───────┘
```

#### Service Deployment
- **vLLM Servers**: Model inference endpoints
- **SandboxFusion**: Code execution sandboxes
- **Evaluation API**: `executor_train/eval_service/`

### 6.2 Deployment Configurations

#### Development Environment
```bash
# Single GPU, local Ray
export RAY_ADDRESS=""
ray start --head

# Local vLLM server
cd curriculum_train/vllm_service_init/
bash start.sh
```

#### Production Environment
```bash
# Multi-node Ray cluster
ray start --head --port=6379
# On worker nodes:
ray start --address=HEAD_NODE_IP:6379

# Distributed vLLM (multiple GPUs)
# Configure in vllm_service_init/start_vllm_server_tool.py
```

### 6.3 Containerization (Future)

#### Docker Setup
```dockerfile
# Base image with CUDA
FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

# Install Python and dependencies
RUN apt-get update && apt-get install -y python3.10 python3-pip
COPY requirements.txt .
RUN pip install -r requirements.txt

# Install Flash Attention
RUN pip install flash-attn==2.8.3 --no-build-isolation

# Copy application
COPY . /app
WORKDIR /app
```

#### Kubernetes Deployment
- **Training Jobs**: Kubernetes Jobs for training runs
- **Services**: Deployments for inference and evaluation APIs
- **Storage**: Persistent volumes for checkpoints and data

### 6.4 Monitoring & Observability

#### Metrics Collection
- **WandB**: Training metrics, hyperparameters
- **Prometheus**: System metrics (via prometheus-fastapi-instrumentator)
- **Ray Dashboard**: Distributed training monitoring

#### Logging
- Centralized logging for all services
- Structured JSON logs for parsing
- Log aggregation (ELK stack or similar)

---

## 🔗 Integrate

### 7.1 Integration Points

#### 1. Model Integration
```python
# Load trained Agent0 model
from transformers import AutoModelForCausalLM, AutoTokenizer

model_path = "path/to/agent0/checkpoint"
model = AutoModelForCausalLM.from_pretrained(model_path)
tokenizer = AutoTokenizer.from_pretrained(model_path)
```

#### 2. Tool Integration
```python
# Use tool-integrated reasoning
from verl_tool.servers import SandboxFusionTool

tool = SandboxFusionTool(config=config)
result = tool.execute(code="print(1+1)")
```

#### 3. Evaluation Integration
```python
# Use evaluation service
from eval_service import EvaluationAPI

api = EvaluationAPI(endpoint="http://eval-service:8000")
score = api.evaluate(model_output, ground_truth)
```

### 7.2 External System Integration

#### HuggingFace Hub
```python
# Upload checkpoints
from huggingface_hub import HfApi

api = HfApi()
api.upload_folder(
    folder_path="checkpoints/agent0",
    repo_id="username/agent0-model",
    repo_type="model"
)
```

#### WandB Integration
```python
# Logging to WandB
import wandb

wandb.init(project="agent0-training")
wandb.log({"metric": value})
```

#### Ray Integration
```python
# Distributed training with Ray
import ray

@ray.remote
def train_worker(config):
    # Training logic
    pass

ray.init()
futures = [train_worker.remote(config) for _ in range(num_workers)]
results = ray.get(futures)
```

### 7.3 API Integration

#### Evaluation API
```bash
# Start evaluation service
cd executor_train/eval_service/
bash scripts/start_api_service.sh

# API endpoints
POST /evaluate - Evaluate model outputs
GET /health - Health check
GET /metrics - Prometheus metrics
```

#### Model Serving API
```python
# vLLM OpenAI-compatible API
from vllm import LLM, SamplingParams

llm = LLM(model="path/to/model")
sampling_params = SamplingParams(temperature=0.7, top_p=0.95)
outputs = llm.generate(prompts, sampling_params)
```

### 7.4 CI/CD Integration

#### GitHub Actions Workflows
- **Pre-commit**: Code quality checks
- **Unit Tests**: Automated test execution
- **Integration Tests**: End-to-end validation
- **Deployment**: Automated deployment on release

#### Workflow Triggers
- Push to main: Run full test suite
- Pull requests: Run pre-commit and unit tests
- Tags: Trigger deployment pipeline

---

## 📊 Implementation Checklist

### Phase 1: Exploration & Setup
- [ ] Complete codebase exploration
- [ ] Document architecture and data flows
- [ ] Set up development environment
- [ ] Verify all dependencies

### Phase 2: Build & Validation
- [ ] Build all components successfully
- [ ] Run unit test suite
- [ ] Validate integration tests
- [ ] Benchmark performance baseline

### Phase 3: Debug & Audit
- [ ] Set up debugging infrastructure
- [ ] Run code quality audits
- [ ] Security vulnerability scan
- [ ] Performance profiling

### Phase 4: Deploy & Integrate
- [ ] Set up production environment
- [ ] Deploy services
- [ ] Configure monitoring
- [ ] Test integrations
- [ ] Document deployment procedures

---

## 📝 Notes

### Key Configuration Files
- Training: `examples/train/math_tir/train_qwen3_4b_adpo.sh`
- Curriculum: `curriculum_train/scripts/curriculum_train.sh`
- Evaluation: `curriculum_train/question_evaluate/evaluate.sh`
- Tools: `curriculum_train/vllm_service_init/start_vllm_server_tool.py`

### Critical Environment Variables
```bash
export STORAGE_PATH="/path/to/storage"
export HUGGINGFACENAME="Qwen/Qwen3-4B-Base"
export WANDB_API_KEY="your_key"
export VLLM_DISABLE_COMPILE_CACHE=1
```

### Storage Structure
```
$STORAGE_PATH/
├── evaluation/
├── models/
├── generated_question/
└── temp_results/
```

---

## 🔄 Maintenance

### Regular Tasks
- Weekly dependency updates
- Monthly security audits
- Quarterly performance reviews
- Continuous monitoring of training jobs

### Update Procedures
1. Test in development environment
2. Run full test suite
3. Deploy to staging
4. Validate in staging
5. Deploy to production
6. Monitor for issues

---

*Last Updated: 2025-01-XX*
*Version: 1.0*
