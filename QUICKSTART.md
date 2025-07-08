# Redis Helper - Quick Start Guide

Get up and running with Redis Helper in minutes!

## 🚀 Quick Installation

### Option 1: Automatic Installation
```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/CosttaCrazy/redis-helper/main/install.sh | bash

# Or with wget
wget -qO- https://raw.githubusercontent.com/CosttaCrazy/redis-helper/main/install.sh | bash
```

### Option 2: Manual Installation
```bash
# Clone repository
git clone https://github.com/CosttaCrazy/redis-helper.git
cd redis-helper

# Run installer
./install.sh

# Or run directly
chmod +x redis-helper.sh
./redis-helper.sh
```

## ⚡ First Run

1. **Start Redis Helper**:
   ```bash
   redis-helper
   ```

2. **Configure your Redis connection**:
   - Edit `config/redis-helper.conf`
   - Or use the interactive configuration menu

3. **Test connection**:
   - Select option 1 from main menu
   - Choose "Test Connection"

## 🎯 Common Use Cases

### Monitor Redis Performance
```bash
# Real-time dashboard
redis-helper
# Select: 2) Real-time Monitoring → 1) Real-time Dashboard
```

### Create Backup
```bash
# Quick backup
redis-helper backup-create

# Or through menu
redis-helper
# Select: 4) Backup & Restore → 1) Create Backup
```

### Analyze Performance Issues
```bash
redis-helper
# Select: 3) Performance Analysis → 1) Slowlog Analysis
```

### Check Memory Usage
```bash
redis-helper
# Select: 1) Connection & Basic Info → 3) Memory Usage
```

## 📋 Essential Configuration

Edit `config/redis-helper.conf`:

```bash
# Basic Redis connection
REDIS_HOST="your-redis-host"
REDIS_PORT="6379"
REDIS_PASSWORD="your-password"  # if needed

# Set your environment
ENVIRONMENT="production"  # or "development", "staging"

# Adjust monitoring thresholds
MEMORY_THRESHOLD="80"      # Alert when memory > 80%
CONNECTION_THRESHOLD="100" # Alert when connections > 100
LATENCY_THRESHOLD="100"    # Alert when latency > 100ms
```

## 🔧 Command Line Usage

```bash
# Interactive menu (default)
redis-helper

# Quick commands
redis-helper test-connection    # Test Redis connection
redis-helper backup-create      # Create backup
redis-helper monitor           # Real-time monitoring

# Get help
redis-helper --help
redis-helper --version
```

## 📊 Menu Navigation

```
Main Menu:
├── 1) Connection & Basic Info     # Test connection, view server info
├── 2) Real-time Monitoring       # Live dashboard, alerts
├── 3) Performance Analysis       # Slowlog, hot keys, optimization
├── 4) Backup & Restore          # Create/restore backups
├── 5) Security & Audit          # Security checks, audit logs
├── 6) Cluster Management        # Redis cluster operations
├── 7) Configuration Management   # Manage settings
├── 8) Utilities & Tools         # Additional tools
└── 9) Reports & Export          # Generate reports
```

## 🚨 Troubleshooting

### Connection Issues
```bash
# Check Redis is running
systemctl status redis
# or
docker ps | grep redis

# Test manual connection
redis-cli -h your-host -p 6379 ping

# Check network connectivity
telnet your-host 6379
```

### Permission Issues
```bash
# Make script executable
chmod +x redis-helper.sh

# Check directory permissions
ls -la config/ logs/ backups/
```

### Missing Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install redis-tools bc gzip

# RHEL/CentOS
sudo yum install redis bc gzip

# macOS
brew install redis bc
```

## 💡 Pro Tips

1. **Use aliases** for quick access:
   ```bash
   alias rh='redis-helper'
   alias rhm='redis-helper monitor'
   alias rhb='redis-helper backup-create'
   ```

2. **Set up automatic backups**:
   ```bash
   redis-helper
   # Go to: 4) Backup & Restore → 4) Schedule Automatic Backup
   ```

3. **Monitor in production**:
   - Set appropriate thresholds in config
   - Use real-time dashboard for live monitoring
   - Set up automated backups

4. **Performance optimization**:
   - Regular slowlog analysis
   - Memory usage monitoring
   - Use optimization recommendations

## 📚 Next Steps

- Read the full [README.md](README.md) for detailed features
- Check [CONTRIBUTING.md](CONTRIBUTING.md) to contribute
- Explore all menu options to discover features
- Set up monitoring thresholds for your environment
- Configure automatic backups

## 🆘 Getting Help

- **Issues**: [GitHub Issues](https://github.com/CosttaCrazy/redis-helper/issues)
- **Discussions**: [GitHub Discussions](https://github.com/CosttaCrazy/redis-helper/discussions)
- **Documentation**: [Full README](README.md)

---

**Ready to optimize your Redis management? Start with `redis-helper` now!** 🚀
