#!/bin/bash
# Agent0 Debug Helper Script
# Usage: ./scripts/debug_helper.sh [command] [args...]

set -e

COMMAND=${1:-"help"}
BASE_DIR="/workspace/Agent0"

case $COMMAND in
  "help")
    echo "🐛 Agent0 Debug Helper"
    echo "======================"
    echo ""
    echo "Usage: ./scripts/debug_helper.sh [command] [args...]"
    echo ""
    echo "Commands:"
    echo "  gpu-status      - Show GPU status and memory usage"
    echo "  ray-status      - Check Ray cluster status"
    echo "  check-logs      - Show recent log files"
    echo "  test-sandbox    - Test SandboxFusion connection"
    echo "  test-vllm       - Test vLLM server connection"
    echo "  memory-profile  - Profile memory usage"
    echo "  check-config    - Validate configuration files"
    echo ""
    ;;
    
  "gpu-status")
    echo "🎮 GPU Status"
    echo "------------"
    nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits || {
        echo "⚠️  nvidia-smi not available (may not have GPU)"
    }
    ;;
    
  "ray-status")
    echo "☀️  Ray Cluster Status"
    echo "---------------------"
    python3 -c "
import ray
try:
    ray.init(address='auto', ignore_reinit_error=True)
    print('✅ Ray connected')
    print(f'Nodes: {len(ray.nodes())}')
    print(f'Resources: {ray.available_resources()}')
except Exception as e:
    print(f'⚠️  Ray not initialized: {e}')
    print('Start Ray with: ray start --head')
" || echo "⚠️  Ray check failed"
    ;;
    
  "check-logs")
    echo "📋 Recent Logs"
    echo "-------------"
    LOG_DIRS=(
        "$BASE_DIR/curriculum_train"
        "$BASE_DIR/executor_train"
    )
    
    for dir in "${LOG_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "Logs in $dir:"
            find "$dir" -name "*.log" -type f -mtime -1 2>/dev/null | head -5 | grep . || echo "  No recent logs"
        fi
    done
    ;;
    
  "test-sandbox")
    SANDBOX_URL=${2:-"http://localhost:8000/run_code"}
    echo "🧪 Testing SandboxFusion"
    echo "-----------------------"
    echo "URL: $SANDBOX_URL"
    
    curl -X POST "$SANDBOX_URL" \
      -H "Content-Type: application/json" \
      -d '{"code": "print(1+1)", "language": "python"}' \
      -w "\nHTTP Status: %{http_code}\n" || {
        echo "❌ Sandbox connection failed"
        echo "Make sure SandboxFusion is running"
    }
    ;;
    
  "test-vllm")
    VLLM_URL=${2:-"http://localhost:8000/v1/completions"}
    echo "🚀 Testing vLLM Server"
    echo "---------------------"
    echo "URL: $VLLM_URL"
    
    curl -X POST "$VLLM_URL" \
      -H "Content-Type: application/json" \
      -d '{"model": "test", "prompt": "Hello", "max_tokens": 10}' \
      -w "\nHTTP Status: %{http_code}\n" || {
        echo "❌ vLLM connection failed"
        echo "Make sure vLLM server is running"
    }
    ;;
    
  "memory-profile")
    echo "💾 Memory Profiling"
    echo "-------------------"
    python3 -c "
import torch
import psutil
import os

process = psutil.Process(os.getpid())
mem_info = process.memory_info()
print(f'Process Memory: {mem_info.rss / 1024 / 1024:.2f} MB')

if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        print(f'GPU {i} Memory:')
        print(f'  Allocated: {torch.cuda.memory_allocated(i) / 1024**3:.2f} GB')
        print(f'  Reserved: {torch.cuda.memory_reserved(i) / 1024**3:.2f} GB')
else:
    print('⚠️  CUDA not available')
"
    ;;
    
  "check-config")
    echo "⚙️  Configuration Check"
    echo "----------------------"
    
    # Check environment variables
    echo "Environment Variables:"
    for var in STORAGE_PATH HUGGINGFACENAME WANDB_API_KEY; do
        if [ -n "${!var}" ]; then
            echo "  ✅ $var is set"
        else
            echo "  ⚠️  $var is not set"
        fi
    done
    echo ""
    
    # Check config files
    echo "Configuration Files:"
    CONFIG_FILES=(
        "$BASE_DIR/curriculum_train/vllm_service_init/start_vllm_server_tool.py"
        "$BASE_DIR/curriculum_train/scripts/curriculum_train.sh"
    )
    
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✅ $(basename $file) exists"
        else
            echo "  ❌ $(basename $file) missing"
        fi
    done
    ;;
    
  *)
    echo "Unknown command: $COMMAND"
    $0 help
    exit 1
    ;;
esac
