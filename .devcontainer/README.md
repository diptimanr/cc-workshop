# 🚀 GitHub Codespaces Setup for Confluent Cloud Workshop

This directory contains the development container configuration for running the Confluent Cloud Workshop in GitHub Codespaces.

## 🏗️ What's Included

### Base Environment
- **Ubuntu 22.04** base image
- **Zsh** with Oh My Zsh configuration
- **Node.js 18** for web development
- **Python 3.11** with workshop packages
- **Java 17** with Maven and Gradle

### Workshop Tools
- **Confluent CLI** - Latest version for Confluent Cloud management
- **DuckDB** - For analytics queries on Iceberg tables
- **VSCode Extensions** - Confluent Cloud extension and development tools

### Pre-installed Python Packages
- `confluent-kafka[avro]` - Kafka client with Avro support
- `requests` - HTTP client for API calls
- `pandas` - Data manipulation
- `duckdb-engine` - DuckDB SQLAlchemy engine

## 🎯 Quick Start

1. **Open in Codespaces**: Click the "Code" button → "Codespaces" → "Create codespace"
2. **Wait for setup**: The bootstrap script will automatically install all dependencies
3. **Validate environment**: Run `workshop-validate` 
4. **Login to Confluent**: Run `workshop-login`
5. **Start workshop**: Follow `guides/01-setup-confluent-cloud.adoc`

## 🔧 Workshop Commands

The devcontainer includes helpful aliases and functions:

### Aliases
```bash
cc                 # confluent
ccenv              # confluent environment  
cccluster          # confluent kafka cluster
cctopic            # confluent kafka topic
ccconnector        # confluent connect connector
ccflink            # confluent flink
```

### Helper Functions
```bash
workshop-status    # Check environment status
workshop-validate  # Run prerequisites validation
workshop-login     # Login to Confluent Cloud
```

## 📁 Directory Structure

```
.devcontainer/
├── devcontainer.json    # Main configuration
├── bootstrap.sh         # Setup script
└── README.md           # This file
```

## 🔍 Configuration Details

### Port Forwarding
- **8080** - Application Server
- **3000** - Development Server  
- **5000** - Flask/Python apps
- **8000** - Alternative web server

### Environment Variables
- `WORKSHOP_ENV=codespaces` - Identifies Codespaces environment
- `CONFLUENT_DISABLE_UPDATES=true` - Prevents CLI update prompts

### VSCode Extensions
- Confluent Cloud extension for cluster management
- Python development tools (Black, Flake8)
- Java development pack
- Markdown and JSON support

## 🚨 Troubleshooting

### Bootstrap Issues
If the bootstrap script fails:
```bash
# Re-run bootstrap manually
.devcontainer/bootstrap.sh

# Check logs
cat /tmp/bootstrap.log
```

### Missing Tools
If tools aren't available after setup:
```bash
# Reload shell configuration
source ~/.zshrc

# Check PATH
echo $PATH

# Verify installations
confluent version
duckdb --version
```

### Permission Issues
```bash
# Fix script permissions
find scripts -name "*.sh" -exec chmod +x {} \;
```

## 🔄 Updates

To update the devcontainer configuration:
1. Modify `devcontainer.json` or `bootstrap.sh`
2. Rebuild container: Command Palette → "Codespaces: Rebuild Container"

## 📚 Workshop Resources

- **Guides**: `/guides/` - Step-by-step instructions
- **Scripts**: `/scripts/` - Automation helpers  
- **Data**: `/data/` - Sample datasets
- **Configs**: `/configs/` - Configuration templates
- **Troubleshooting**: `/troubleshooting/` - Issue resolution

---

**Ready to start?** Run `workshop-validate` to ensure everything is working! 🎉
