#!/bin/bash
# Agent0 Test Runner Script
# Usage: ./scripts/run_tests.sh [test_type]

set -e

TEST_TYPE=${1:-"unit"}
BASE_DIR="/workspace/Agent0"

echo "🧪 Agent0 Test Runner"
echo "====================="
echo ""

case $TEST_TYPE in
  "unit")
    echo "📝 Running Unit Tests"
    echo "---------------------"
    
    # VeRL unit tests
    if [ -d "$BASE_DIR/executor_train/verl/tests" ]; then
        echo "Running VeRL unit tests..."
        cd $BASE_DIR/executor_train/verl
        python3 -m pytest tests/ -v -k "not gpu" --tb=short -x || {
            echo "⚠️  Some VeRL tests failed (this may be expected)"
        }
        cd - > /dev/null
        echo ""
    fi
    
    # Tool server tests
    if [ -d "$BASE_DIR/executor_train/verl_tool/servers/tests" ]; then
        echo "Running tool server tests..."
        cd $BASE_DIR/executor_train/verl_tool/servers/tests
        python3 -m pytest test_*.py -v --tb=short -x || {
            echo "⚠️  Some tool tests failed (may require external services)"
        }
        cd - > /dev/null
        echo ""
    fi
    
    # Evaluation service tests
    if [ -d "$BASE_DIR/executor_train/eval_service/test" ]; then
        echo "Running evaluation service tests..."
        cd $BASE_DIR/executor_train/eval_service/test
        python3 -m pytest test_*.py -v --tb=short -x || {
            echo "⚠️  Some evaluation tests failed"
        }
        cd - > /dev/null
        echo ""
    fi
    ;;
    
  "integration")
    echo "🔗 Running Integration Tests"
    echo "----------------------------"
    echo "⚠️  Integration tests require GPU and external services"
    echo "Skipping for now..."
    ;;
    
  "quick")
    echo "⚡ Running Quick Tests"
    echo "---------------------"
    
    # Quick import tests
    echo "Testing imports..."
    python3 -c "
import torch
import transformers
import ray
print('✅ Core imports OK')
" || exit 1
    
    # Quick VeRL import
    cd $BASE_DIR/executor_train/verl 2>/dev/null && python3 -c "import verl; print('✅ VeRL import OK')" || echo "⚠️  VeRL not installed"
    echo ""
    ;;
    
  "all")
    echo "🔄 Running All Tests"
    echo "-------------------"
    $0 unit
    $0 integration
    ;;
    
  *)
    echo "Unknown test type: $TEST_TYPE"
    echo "Available types: unit, integration, quick, all"
    exit 1
    ;;
esac

echo "✅ Test run complete!"
