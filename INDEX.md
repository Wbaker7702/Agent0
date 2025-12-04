# Agent0 Series - Development Tools Index

## 📚 Documentation

### Main Documents
1. **[PLAN.md](./PLAN.md)** - Comprehensive development and deployment plan
   - Complete guide covering all aspects: explore, search, build, debug, validate, audit, deploy, integrate
   - Detailed procedures and best practices
   - Architecture diagrams and configurations

2. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Quick reference guide
   - Common commands and workflows
   - Troubleshooting tips
   - Configuration examples

3. **[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)** - Implementation summary
   - Overview of created tools and scripts
   - Usage instructions
   - Coverage and next steps

4. **[README.md](./README.md)** - Project README
   - Project overview and features
   - Results and benchmarks
   - Citation information

## 🛠️ Tools & Scripts

### Scripts Directory: `/workspace/scripts/`

| Script | Purpose | Usage |
|--------|---------|-------|
| `explore_codebase.sh` | Explore codebase structure | `./scripts/explore_codebase.sh [component]` |
| `validate_build.sh` | Validate build environment | `./scripts/validate_build.sh` |
| `run_tests.sh` | Run test suites | `./scripts/run_tests.sh [type]` |
| `debug_helper.sh` | Debugging utilities | `./scripts/debug_helper.sh [command]` |
| `audit_code.sh` | Code quality audits | `./scripts/audit_code.sh [type]` |

### Makefile Commands

Use `make help` to see all available commands, or:

```bash
# Exploration
make explore              # Explore codebase
make explore-training     # Explore training components
make explore-tools        # Explore tool servers

# Build & Setup
make build               # Validate build environment
make install             # Install dependencies

# Testing
make test                # Run unit tests
make test-quick          # Run quick tests
make validate            # Full validation

# Debugging
make debug-gpu           # Check GPU status
make debug-ray           # Check Ray cluster
make debug-config        # Validate configuration

# Auditing
make audit               # Run all audits
make audit-security      # Security audit
make audit-quality       # Code quality audit
```

## 🚀 Quick Start

### 1. First Time Setup
```bash
# Install dependencies
make install

# Validate build
make build

# Explore codebase
make explore
```

### 2. Daily Development
```bash
# Quick validation
make test-quick

# Check status
make debug-config

# Run tests
make test
```

### 3. Before Deployment
```bash
# Full validation
make validate

# Security audit
make audit-security

# Deployment check
make deploy-check
```

## 📋 Workflow Guide

### Exploration Phase
1. Run `make explore` to understand codebase structure
2. Use `make explore-training` to find training components
3. Check `PLAN.md` Section 1 (Explorer) for detailed analysis

### Build Phase
1. Run `make build` to validate environment
2. Use `make install` to install dependencies
3. See `PLAN.md` Section 3 (Build) for setup procedures

### Development Phase
1. Use `make test-quick` for rapid validation
2. Use `make debug-*` commands for troubleshooting
3. Refer to `PLAN.md` Section 4 (Debug) for debugging strategies

### Validation Phase
1. Run `make test` for unit tests
2. Run `make validate` for full validation
3. See `PLAN.md` Section 5 (Validate) for testing procedures

### Audit Phase
1. Run `make audit` for comprehensive audit
2. Review security findings
3. See `PLAN.md` Section 6 (Audit) for audit procedures

### Deployment Phase
1. Run `make deploy-check` for readiness check
2. Review deployment configuration
3. See `PLAN.md` Section 7 (Deploy) for deployment guide

### Integration Phase
1. Run `make integrate-check` for integration validation
2. Test API endpoints
3. See `PLAN.md` Section 8 (Integrate) for integration guide

## 🎯 Use Cases

### I want to understand the codebase
→ Read `PLAN.md` Section 1 (Explorer)  
→ Run `make explore`

### I want to set up my environment
→ Read `PLAN.md` Section 3 (Build)  
→ Run `make build` and `make install`

### I'm having build issues
→ Run `make debug-config`  
→ Check `QUICK_REFERENCE.md` Troubleshooting section

### I want to run tests
→ Read `PLAN.md` Section 5 (Validate)  
→ Run `make test` or `make test-quick`

### I want to check code quality
→ Read `PLAN.md` Section 6 (Audit)  
→ Run `make audit`

### I want to deploy
→ Read `PLAN.md` Section 7 (Deploy)  
→ Run `make deploy-check`

### I need quick help
→ Check `QUICK_REFERENCE.md`  
→ Run `make help`

## 📊 File Structure

```
/workspace/
├── PLAN.md                      # Comprehensive plan
├── QUICK_REFERENCE.md           # Quick reference
├── IMPLEMENTATION_SUMMARY.md    # Implementation summary
├── INDEX.md                     # This file
├── Makefile                     # Convenient commands
├── scripts/                     # All utility scripts
│   ├── explore_codebase.sh
│   ├── validate_build.sh
│   ├── run_tests.sh
│   ├── debug_helper.sh
│   └── audit_code.sh
├── Agent0/                      # Agent0 codebase
│   ├── curriculum_train/
│   ├── executor_train/
│   └── requirements.txt
└── Agent0-VL/                   # Agent0-VL codebase
    └── README.md
```

## 🔗 Related Resources

- **Project Repository**: [Agent0 GitHub](https://github.com/aiming-lab/Agent0)
- **Agent0 Paper**: [arXiv:2511.16043](https://arxiv.org/abs/2511.16043)
- **Agent0-VL Paper**: [arXiv:2511.19900](https://arxiv.org/abs/2511.19900)
- **Documentation Website**: [Agent0 Website](https://aiming-lab.github.io/Agent0)

## 💡 Tips

1. **Start with exploration**: Use `make explore` to understand the codebase
2. **Validate early**: Run `make build` before starting development
3. **Use quick tests**: `make test-quick` for rapid feedback
4. **Check configuration**: `make debug-config` when things don't work
5. **Read the plan**: `PLAN.md` has detailed procedures for everything

## 🆘 Getting Help

1. **Quick help**: Run `make help` or check `QUICK_REFERENCE.md`
2. **Detailed guide**: Read `PLAN.md` for comprehensive documentation
3. **Troubleshooting**: Use `make debug-*` commands and check logs
4. **Configuration**: Run `make debug-config` to validate setup

---

*Last Updated: 2025-01-XX*  
*For the latest information, see the individual documentation files.*
