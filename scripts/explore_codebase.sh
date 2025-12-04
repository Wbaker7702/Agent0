#!/bin/bash
# Agent0 Codebase Explorer Script
# Usage: ./scripts/explore_codebase.sh [component]

set -e

COMPONENT=${1:-"all"}
BASE_DIR="/workspace/Agent0"

echo "🔍 Agent0 Codebase Explorer"
echo "============================"
echo ""

case $COMPONENT in
  "all")
    echo "📊 Overall Statistics"
    echo "---------------------"
    echo "Python files: $(find $BASE_DIR -name "*.py" | wc -l)"
    echo "Shell scripts: $(find $BASE_DIR -name "*.sh" | wc -l)"
    echo "Config files: $(find $BASE_DIR -name "*.yaml" | wc -l)"
    echo ""
    
    echo "🏗️ Key Components"
    echo "-----------------"
    echo "Curriculum Training:"
    find $BASE_DIR/curriculum_train -maxdepth 2 -type d | head -10
    echo ""
    echo "Executor Training:"
    find $BASE_DIR/executor_train -maxdepth 2 -type d | head -10
    echo ""
    
    echo "📝 Entry Points"
    echo "---------------"
    grep -r "if __name__" $BASE_DIR --include="*.py" | head -10
    echo ""
    ;;
    
  "training")
    echo "🎓 Training Scripts"
    echo "-------------------"
    find $BASE_DIR -name "*train*.sh" -type f
    echo ""
    
    echo "📋 Training Configs"
    echo "------------------"
    find $BASE_DIR -name "*.yaml" -path "*/train*" -o -name "*config*.yaml" | head -20
    echo ""
    ;;
    
  "tools")
    echo "🔧 Tool Servers"
    echo "--------------"
    find $BASE_DIR/executor_train/verl_tool/servers -name "*.py" -type f | grep -v test | grep -v __pycache__
    echo ""
    
    echo "🧪 Tool Tests"
    echo "-------------"
    find $BASE_DIR/executor_train/verl_tool/servers/tests -name "test_*.py" -type f
    echo ""
    ;;
    
  "evaluation")
    echo "📊 Evaluation Components"
    echo "-----------------------"
    find $BASE_DIR -path "*/eval*" -name "*.py" -type f | head -20
    echo ""
    
    echo "📈 Evaluation Scripts"
    echo "--------------------"
    find $BASE_DIR -name "*evaluate*.sh" -o -name "*evaluate*.py" | head -10
    echo ""
    ;;
    
  "dependencies")
    echo "📦 Dependencies"
    echo "--------------"
    echo "Main requirements:"
    cat $BASE_DIR/requirements.txt | head -20
    echo ""
    echo "Curriculum requirements:"
    cat $BASE_DIR/curriculum_train/requirements.txt | head -20
    echo ""
    ;;
    
  *)
    echo "Unknown component: $COMPONENT"
    echo "Available components: all, training, tools, evaluation, dependencies"
    exit 1
    ;;
esac

echo "✅ Exploration complete!"
