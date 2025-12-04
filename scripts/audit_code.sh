#!/bin/bash
# Agent0 Code Audit Script
# Usage: ./scripts/audit_code.sh [audit_type]

set -e
set -o pipefail

AUDIT_TYPE=${1:-"all"}
BASE_DIR="/workspace/Agent0"

echo "🔒 Agent0 Code Audit"
echo "===================="
echo ""

# Install audit tools if needed
install_audit_tools() {
    echo "📦 Installing audit tools..."
    pip install --quiet pylint black flake8 bandit safety 2>/dev/null || {
        echo "⚠️  Some tools may already be installed"
    }
}

case $AUDIT_TYPE in
  "all")
    install_audit_tools
    $0 security
    $0 quality
    $0 dependencies
    ;;
    
  "security")
    echo "🔐 Security Audit"
    echo "----------------"
    
    if command -v bandit &> /dev/null; then
        echo "Running Bandit security scan..."
        bandit -r "$BASE_DIR" -ll -f json -o /tmp/bandit_report.json 2>/dev/null || {
            echo "⚠️  Security issues found. Check /tmp/bandit_report.json"
        }
        echo "✅ Security scan complete"
    else
        echo "⚠️  Bandit not installed. Install with: pip install bandit"
    fi
    echo ""
    
    if command -v safety &> /dev/null; then
        echo "Checking for known vulnerabilities..."
        safety check --json 2>/dev/null || {
            echo "⚠️  Vulnerable packages found"
        }
        echo "✅ Dependency vulnerability check complete"
    else
        echo "⚠️  Safety not installed. Install with: pip install safety"
    fi
    echo ""
    ;;
    
  "quality")
    echo "📊 Code Quality Audit"
    echo "--------------------"
    
    if command -v black &> /dev/null; then
        echo "Checking code formatting with Black..."
        black --check --diff "$BASE_DIR" 2>/dev/null || {
            echo "⚠️  Code formatting issues found"
        }
        echo "✅ Formatting check complete"
    else
        echo "⚠️  Black not installed"
    fi
    echo ""
    
    if command -v flake8 &> /dev/null; then
        echo "Running Flake8 linting..."
        flake8 "$BASE_DIR" --max-line-length=120 --exclude=venv,__pycache__,*.egg-info --count --statistics 2>/dev/null || {
            echo "⚠️  Linting issues found"
        }
        echo "✅ Linting complete"
    else
        echo "⚠️  Flake8 not installed"
    fi
    echo ""
    
    if command -v pylint &> /dev/null; then
        echo "Running Pylint analysis..."
        pylint "$BASE_DIR" --disable=all --enable=E,W --max-line-length=120 2>/dev/null | head -50 || {
            echo "⚠️  Code quality issues found"
        }
        echo "✅ Pylint analysis complete"
    else
        echo "⚠️  Pylint not installed"
    fi
    echo ""
    ;;
    
  "dependencies")
    echo "📦 Dependency Audit"
    echo "-------------------"
    
    echo "Checking for outdated packages..."
    pip list --outdated 2>/dev/null | head -20 || {
        echo "⚠️  Could not check outdated packages"
    }
    echo ""
    
    echo "Checking for duplicate dependencies..."
    # Check for version conflicts in requirements files
    if [ -f "$BASE_DIR/requirements.txt" ]; then
        echo "Main requirements:"
        grep -E "^[a-zA-Z]" "$BASE_DIR/requirements.txt" | cut -d'=' -f1 | sort | uniq -d || {
            echo "  ✅ No duplicates found"
        }
    fi
    echo ""
    
    echo "Checking license compatibility..."
    echo "⚠️  Manual license check recommended"
    echo "   Verify all dependencies are compatible with Apache 2.0"
    echo ""
    ;;
    
  *)
    echo "Unknown audit type: $AUDIT_TYPE"
    echo "Available types: all, security, quality, dependencies"
    exit 1
    ;;
esac

echo "✅ Audit complete!"
