# Agent0 Series - Quick Reference Guide

## 🚀 Quick Start

### 1. Setup Environment
```bash
# Install dependencies
make install

# Validate build
make build
```

### 2. Explore Codebase
```bash
# Full exploration
make explore

# Specific components
make explore-training
make explore-tools
```

### 3. Run Tests
```bash
# Quick tests
make test-quick

# Full test suite
make test-all
```

### 4. Debug Issues
```bash
# Check GPU
make debug-gpu

# Check Ray cluster
make debug-ray

# Check configuration
make debug-config
```

## 📋 Common Commands

### Exploration
```bash
./scripts/explore_codebase.sh [component]
# Components: all, training, tools, evaluation, dependencies
```

### Build Validation
```bash
./scripts/validate_build.sh
```

### Testing
```bash
./scripts/run_tests.sh [type]
# Types: unit, integration, quick, all
```

### Debugging
```bash
./scripts/debug_helper.sh [command]
# Commands: gpu-status, ray-status, check-logs, test-sandbox, 
#           test-vllm, memory-profile, check-config
```

### Auditing
```bash
./scripts/audit_code.sh [type]
# Types: all, security, quality, dependencies
```

## 🔧 Configuration

### Required Environment Variables
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

## 🏗️ Training Workflow

### 1. Train Curriculum Agent
```bash
cd Agent0/curriculum_train/
bash scripts/curriculum_train.sh \
    Qwen/Qwen3-4B-Base \
    Qwen/Qwen3-4B-Base \
    qwen3_4b_curriculum_v1
```

### 2. Generate Questions
```bash
curriculum_agent_path=${STORAGE_PATH}/models/qwen3_4b_curriculum_v1/global_step_5/actor/huggingface
experiment_name=qwen3_4b_executor_v1

bash question_generate/question_generate.bash \
    $curriculum_agent_path 1000 $experiment_name
```

### 3. Evaluate Questions
```bash
executor_agent_path=Qwen/Qwen3-4B-Base
bash question_evaluate/evaluate.sh \
    $executor_agent_path $experiment_name
```

### 4. Train Executor Agent
```bash
cd ../executor_train
bash examples/train/math_tir/train_qwen3_4b_adpo.sh
```

## 🐛 Troubleshooting

### GPU Memory Issues
```bash
# Monitor GPU
watch -n 1 nvidia-smi

# Reduce batch size in config files
# Look for: batch_size, micro_batch_size
```

### Ray Connection Issues
```bash
# Start Ray cluster
ray start --head

# Check status
ray status

# Debug
make debug-ray
```

### SandboxFusion Issues
```bash
# Test connection
make debug-sandbox

# Check configuration
grep SANDBOX_API_URLS Agent0/curriculum_train/vllm_service_init/start_vllm_server_tool.py
```

### Model Loading Issues
```bash
# Verify model access
python3 -c "from transformers import AutoModel; \
    AutoModel.from_pretrained('Qwen/Qwen3-4B-Base')"

# Check checkpoint
python3 Agent0/curriculum_train/scripts/model_merger.py --check-only
```

## 📊 Monitoring

### Training Metrics
- **WandB**: Automatic logging during training
- **TensorBoard**: Local logs in `logs/` directory
- **Ray Dashboard**: `http://localhost:8265` (if Ray is running)

### System Monitoring
```bash
# GPU usage
make debug-gpu

# Memory usage
make debug-memory

# Check logs
make debug-logs
```

## 🔗 Integration Points

### Load Trained Model
```python
from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("path/to/checkpoint")
tokenizer = AutoTokenizer.from_pretrained("path/to/checkpoint")
```

### Use Evaluation API
```python
from eval_service import EvaluationAPI

api = EvaluationAPI(endpoint="http://eval-service:8000")
score = api.evaluate(model_output, ground_truth)
```

### Use Tool Integration
```python
from verl_tool.servers import SandboxFusionTool

tool = SandboxFusionTool(config=config)
result = tool.execute(code="print(1+1)")
```

## 📚 Key Files

### Training Scripts
- `Agent0/curriculum_train/scripts/curriculum_train.sh`
- `Agent0/executor_train/examples/train/math_tir/train_qwen3_4b_adpo.sh`

### Configuration
- `Agent0/curriculum_train/vllm_service_init/start_vllm_server_tool.py`
- `Agent0/curriculum_train/examples/config.yaml`

### Evaluation
- `Agent0/curriculum_train/question_evaluate/evaluate.sh`
- `Agent0/executor_train/eval_service/scripts/start_api_service.sh`

## 🆘 Getting Help

1. **Check Documentation**: See `PLAN.md` for comprehensive guide
2. **Run Diagnostics**: `make debug-config`
3. **Check Logs**: `make debug-logs`
4. **Validate Setup**: `make validate`

## 📝 Notes

- Always check GPU availability before training
- Ensure SandboxFusion is running before curriculum training
- Set all required environment variables before starting
- Monitor disk space for checkpoints and generated data
