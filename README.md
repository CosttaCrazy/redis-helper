# Redis Helper v1.1

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Redis](https://img.shields.io/badge/Redis-Compatible-red.svg)](https://redis.io/)
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)](https://github.com/CosttaCrazy/redis-helper/releases)

**Redis Helper** is an advanced, comprehensive Redis management and monitoring tool designed to simplify Redis operations, provide deep insights, and optimize performance. Built for developers, DevOps engineers, and database administrators who work with Redis in development, staging, and production environments.

## 🚀 Features

### 🔍 **Real-time Monitoring**
- Live dashboard with key metrics (OPS/sec, memory usage, connections)
- Visual progress bars and trend indicators
- Configurable refresh rates
- Alert system with customizable thresholds
- Memory usage tracking with fragmentation analysis
- Connection monitoring and client analysis

### 📊 **Performance Analysis**
- Slowlog analysis with detailed breakdowns
- Hot keys detection (Redis 4.0+)
- Command statistics and profiling
- Latency analysis and benchmarking
- Memory usage analysis by data type
- Performance optimization recommendations

### 💾 **Backup & Restore**
- Automated backup creation (RDB format)
- Scheduled backups with cron integration
- Backup compression and versioning
- Point-in-time restore capabilities
- Data export (JSON, CSV, RESP formats)
- Backup retention management
- Backup integrity verification

### 🔒 **Security & Audit**
- Connection security validation
- Configuration security assessment
- Audit logging for all operations
- Access pattern analysis
- Security recommendations

### 🏗️ **Cluster Management**
- Redis Cluster health monitoring
- Node status and failover detection
- Cluster rebalancing assistance
- Multi-node performance analysis

### ⚙️ **Configuration Management**
- Multiple environment support (dev/staging/prod)
- Dynamic configuration updates
- Configuration backup and restore
- Best practices validation
- Parameter optimization suggestions

### 🛠️ **Utilities & Tools**
- Interactive Redis CLI with enhanced features
- Bulk operations support
- Data migration tools
- Key pattern analysis
- TTL management utilities

### 📈 **Reports & Export**
- Comprehensive performance reports
- Historical data analysis
- Metrics export (CSV, JSON)
- Custom report generation
- Trend analysis and forecasting

## 📋 Requirements

- **Operating System**: Linux, macOS, or Unix-like systems
- **Shell**: Bash 4.0 or higher
- **Redis**: Redis 3.0+ (some features require Redis 4.0+)
- **Tools**: `redis-cli`, `bc`, `gzip` (optional for compression)
- **Permissions**: Read/write access to Redis and backup directories

## 🔧 Installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/CosttaCrazy/redis-helper.git
cd redis-helper

# Make the script executable
chmod +x redis-helper.sh

# Run the tool
./redis-helper.sh
```

### Manual Setup

1. **Download the latest release**:
   ```bash
   wget https://github.com/CosttaCrazy/redis-helper/archive/v1.0.0.tar.gz
   tar -xzf v1.0.0.tar.gz
   cd redis-helper-1.0.0
   ```

2. **Set up directories**:
   ```bash
   mkdir -p config logs backups metrics lib
   chmod +x redis-helper.sh
   ```

3. **Configure Redis connection**:
   ```bash
   # Edit config/redis-helper.conf
   vim config/redis-helper.conf
   ```

## ⚙️ Configuration

### Basic Configuration

The tool automatically creates a configuration file on first run at `config/redis-helper.conf`:

```bash
# Redis Connection Settings
REDIS_HOST="localhost"
REDIS_PORT="6379"
REDIS_PASSWORD=""
REDIS_DB="0"

# Environment Settings
ENVIRONMENT="development"
LOG_LEVEL="INFO"

# Monitoring Thresholds
MEMORY_THRESHOLD="80"
CONNECTION_THRESHOLD="100"
LATENCY_THRESHOLD="100"

# Backup Settings
BACKUP_RETENTION_DAYS="7"
BACKUP_COMPRESSION="true"
AUTO_BACKUP="false"
BACKUP_SCHEDULE="0 2 * * *"
```

### Multiple Environments

Configure multiple Redis environments:

```bash
# Environment definitions
declare -A ENVIRONMENTS
ENVIRONMENTS[development]="localhost:6379"
ENVIRONMENTS[staging]="redis-staging.local:6379"
ENVIRONMENTS[production]="redis-prod.local:6379"
```

Switch between environments:
```bash
./redis-helper.sh --env production
```

## 🚀 Usage

### Interactive Mode (Default)

```bash
./redis-helper.sh
```

This launches the interactive menu system with all features accessible through a user-friendly interface.

### Command Line Options

```bash
# Show version
./redis-helper.sh --version

# Show help
./redis-helper.sh --help

# Run specific environment
./redis-helper.sh --env staging

# Create backup
./redis-helper.sh backup-create

# Run performance analysis
./redis-helper.sh analyze-performance
```

### Quick Commands

```bash
# Test connection
./redis-helper.sh test-connection

# Show real-time dashboard
./redis-helper.sh monitor

# Create backup
./redis-helper.sh backup

# Show recommendations
./redis-helper.sh recommendations
```

## 📖 Menu System

### Main Menu
```
┌─ Main Menu ─────────────────────────────────────────────────┐
│ 1)  Connection & Basic Info                                 │
│ 2)  Real-time Monitoring                                    │
│ 3)  Performance Analysis                                     │
│ 4)  Backup & Restore                                        │
│ 5)  Security & Audit                                        │
│ 6)  Cluster Management                                      │
│ 7)  Configuration Management                                │
│ 8)  Utilities & Tools                                       │
│ 9)  Reports & Export                                        │
│ 0)  Exit                                                    │
└─────────────────────────────────────────────────────────────┘
```

### Connection & Basic Info
- Test Redis connectivity with latency measurement
- Display server information and version
- Show memory usage with visual indicators
- List active client connections
- Database statistics and key counts
- Direct Redis CLI access

### Real-time Monitoring
- Live dashboard with auto-refresh
- Operations per second tracking
- Memory usage monitoring with alerts
- Connection count monitoring
- Recent activity display
- Configurable refresh intervals

### Performance Analysis
- Slowlog analysis with detailed breakdowns
- Hot keys detection and analysis
- Memory usage analysis by data type
- Command statistics and profiling
- Latency testing and analysis
- Built-in benchmarking tools
- Optimization recommendations

## 🧪 Testing

Redis Helper includes a comprehensive testing suite with 100+ tests covering all functionality.

### Quick Test
```bash
# Run quick validation test
./run_tests.sh quick
```

### Complete Test Suite
```bash
# Run all tests (recommended)
./run_tests.sh

# Run specific test categories
./run_tests.sh unit          # Unit tests (core functionality)
./run_tests.sh integration   # Integration tests (full system)
./run_tests.sh install       # Installation tests
```

### Test Structure
```
tests/
├── unit/           # Unit tests for individual components
├── integration/    # Integration tests for full system
└── install/        # Installation and setup tests
```

### Test Coverage
- **100+ comprehensive tests** covering all modules
- **Unit tests** for individual functions and modules
- **Integration tests** for complete system functionality
- **Installation tests** for setup and configuration
- **Automated test runner** with detailed reporting

### CI/CD Ready
The test suite is designed for continuous integration:
```bash
# Exit code 0 = all tests passed
# Exit code 1 = some tests failed
./run_tests.sh && echo "All tests passed!" || echo "Tests failed!"
```

## 🔧 Advanced Features

### Automated Backups

Set up automated backups with cron:

```bash
# Schedule daily backups at 2 AM
./redis-helper.sh schedule-backup daily

# Custom cron schedule
./redis-helper.sh schedule-backup "0 */6 * * *"
```

### Performance Monitoring

Monitor specific metrics:

```bash
# Monitor memory usage
./redis-helper.sh monitor-memory

# Monitor operations per second
./redis-helper.sh monitor-ops

# Monitor slow queries
./redis-helper.sh monitor-slowlog
```

### Bulk Operations

```bash
# Export all data to JSON
./redis-helper.sh export-json

# Import data from backup
./redis-helper.sh import-backup backup_name

# Cleanup old backups
./redis-helper.sh cleanup-backups
```

## 📊 Monitoring & Alerts

### Alert Thresholds

Configure monitoring thresholds in the config file:

```bash
MEMORY_THRESHOLD="80"        # Alert when memory usage > 80%
CONNECTION_THRESHOLD="100"   # Alert when connections > 100
LATENCY_THRESHOLD="100"      # Alert when latency > 100ms
```

### Visual Indicators

The tool provides visual feedback:
- 🟢 **Green**: Normal operation
- 🟡 **Yellow**: Warning conditions
- 🔴 **Red**: Critical issues
- 📊 **Progress bars**: Visual representation of usage

## 🔒 Security Features

### Security Checks
- Password authentication validation
- SSL/TLS connection verification
- Configuration security assessment
- Access control validation

### Audit Logging
All operations are logged with timestamps:
```
[2024-01-15 10:30:45] [INFO] Backup created: redis_backup_prod_20240115_103045
[2024-01-15 10:31:02] [WARN] High memory usage detected: 85%
[2024-01-15 10:31:15] [ERROR] Connection failed to staging environment
```

## 🏗️ Cluster Support

### Cluster Monitoring
- Node health status
- Slot distribution analysis
- Failover detection
- Replication lag monitoring

### Cluster Operations
- Add/remove nodes
- Cluster rebalancing
- Failover management
- Cross-node backup coordination

## 📈 Performance Optimization

### Automatic Recommendations

The tool analyzes your Redis instance and provides recommendations:

- Memory optimization suggestions
- Configuration tuning advice
- Query optimization tips
- Infrastructure scaling recommendations

### Benchmarking

Built-in benchmarking tools:
```bash
# Run comprehensive benchmark
./redis-helper.sh benchmark

# Test specific operations
./redis-helper.sh benchmark --operations SET,GET,INCR

# Custom benchmark parameters
./redis-helper.sh benchmark --clients 50 --requests 10000
```

## 🐛 Troubleshooting

### Common Issues

**Connection Failed**
```bash
# Check Redis server status
systemctl status redis

# Verify network connectivity
telnet redis-host 6379

# Check authentication
redis-cli -h redis-host -p 6379 -a password ping
```

**Permission Denied**
```bash
# Ensure script is executable
chmod +x redis-helper.sh

# Check directory permissions
ls -la config/ logs/ backups/
```

**Missing Dependencies**
```bash
# Install required tools
sudo apt-get install redis-tools bc gzip  # Ubuntu/Debian
sudo yum install redis bc gzip            # RHEL/CentOS
```

### Debug Mode

Enable debug logging:
```bash
export LOG_LEVEL="DEBUG"
./redis-helper.sh
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Fork and clone the repository
git clone https://github.com/CosttaCrazy/redis-helper.git
cd redis-helper

# Create a feature branch
git checkout -b feature/new-feature

# Make your changes and test
./redis-helper.sh --test

# Submit a pull request
```

### Code Style

- Follow bash best practices
- Use meaningful variable names
- Add comments for complex logic
- Test on multiple Redis versions
- Update documentation for new features

## 📝 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Redis team for the excellent database
- Community contributors and testers
- DevOps engineers who provided feedback and requirements

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/CosttaCrazy/redis-helper/issues)
- **Discussions**: [GitHub Discussions](https://github.com/CosttaCrazy/redis-helper/discussions)
- **Documentation**: [Wiki](https://github.com/CosttaCrazy/redis-helper/wiki)

## 🗺️ Roadmap

### Version 1.1 (Planned)
- [ ] Web-based dashboard
- [ ] REST API for remote management
- [ ] Docker container support
- [ ] Kubernetes integration

### Version 1.5 (Future)
- [ ] Grafana integration
- [ ] Prometheus metrics export
- [ ] Slack/Discord notifications
- [ ] Multi-language support

### Version 2.0 (Long-term)
- [ ] Machine learning-based optimization
- [ ] Predictive scaling recommendations
- [ ] Advanced cluster orchestration
- [ ] Cloud provider integrations

## 📊 Statistics

- **Lines of Code**: ~2,500
- **Features**: 50+
- **Supported Redis Versions**: 3.0+
- **Tested Environments**: Linux, macOS
- **Languages**: Bash, Shell scripting

---

**Made with ❤️ for the Redis community**

*If you find this tool helpful, please consider giving it a ⭐ on GitHub!*
