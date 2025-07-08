# Contributing to Redis Helper

Thank you for your interest in contributing to Redis Helper! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the issue templates** when available
3. **Provide detailed information** including:
   - Redis Helper version
   - Redis version
   - Operating system
   - Steps to reproduce
   - Expected vs actual behavior
   - Error messages or logs

### Suggesting Features

We welcome feature suggestions! Please:

1. **Check the roadmap** in README.md to see if it's already planned
2. **Open a feature request** with:
   - Clear description of the feature
   - Use case and benefits
   - Possible implementation approach
   - Any relevant examples or mockups

### Code Contributions

#### Getting Started

1. **Fork the repository**
   ```bash
   git clone https://github.com/CosttaCrazy/redis-helper.git
   cd redis-helper
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set up development environment**
   ```bash
   chmod +x redis-helper.sh
   ./redis-helper.sh --help
   ```

#### Development Guidelines

##### Code Style

- **Shell Script Standards**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Indentation**: Use 4 spaces (no tabs)
- **Line Length**: Maximum 120 characters
- **Functions**: Use descriptive names with underscores
- **Variables**: Use uppercase for constants, lowercase for local variables

##### Example Code Style

```bash
# Good
function analyze_memory_usage() {
    local redis_host="$1"
    local threshold="${2:-80}"
    
    if [[ -z "$redis_host" ]]; then
        log "ERROR" "Redis host not specified"
        return 1
    fi
    
    # Implementation here
}

# Constants
readonly DEFAULT_TIMEOUT=30
readonly CONFIG_FILE="config/redis-helper.conf"
```

##### Error Handling

- Always check return codes
- Use meaningful error messages
- Log errors appropriately
- Provide fallback options when possible

```bash
# Good error handling
if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping >/dev/null 2>&1; then
    log "ERROR" "Cannot connect to Redis at $REDIS_HOST:$REDIS_PORT"
    return 1
fi
```

##### Documentation

- **Function Documentation**: Document all functions
- **Inline Comments**: Explain complex logic
- **README Updates**: Update documentation for new features

```bash
# Analyze Redis memory usage and provide recommendations
# Arguments:
#   $1 - Redis host (required)
#   $2 - Memory threshold percentage (optional, default: 80)
# Returns:
#   0 - Success
#   1 - Error (connection failed, invalid parameters)
analyze_memory_usage() {
    # Implementation
}
```

#### Testing

##### Manual Testing

Before submitting:

1. **Test on multiple Redis versions** (3.0, 4.0, 5.0, 6.0+)
2. **Test on different operating systems** (Linux, macOS)
3. **Test error conditions** (connection failures, invalid inputs)
4. **Test with different configurations**

##### Test Checklist

- [ ] All menu options work correctly
- [ ] Error messages are clear and helpful
- [ ] Configuration changes persist
- [ ] Backup and restore functions work
- [ ] Performance monitoring displays correctly
- [ ] No shell script errors or warnings

#### Submitting Changes

1. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add memory optimization recommendations"
   ```

2. **Follow commit message conventions**
   - `feat:` - New features
   - `fix:` - Bug fixes
   - `docs:` - Documentation changes
   - `style:` - Code style changes
   - `refactor:` - Code refactoring
   - `test:` - Test additions or changes
   - `chore:` - Maintenance tasks

3. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create a Pull Request**
   - Use the PR template
   - Provide clear description
   - Link related issues
   - Add screenshots if applicable

## 🏗️ Project Structure

```
redis-helper/
├── redis-helper.sh          # Main script
├── lib/                     # Module libraries
│   ├── monitoring.sh        # Real-time monitoring
│   ├── performance.sh       # Performance analysis
│   ├── backup.sh           # Backup and restore
│   ├── security.sh         # Security features
│   └── cluster.sh          # Cluster management
├── config/                  # Configuration files
│   └── redis-helper.conf   # Default configuration
├── docs/                    # Documentation
├── tests/                   # Test scripts
├── install.sh              # Installation script
├── README.md               # Main documentation
├── CONTRIBUTING.md         # This file
└── LICENSE                 # GPL v3 license
```

## 🧪 Development Environment

### Prerequisites

- Bash 4.0+
- Redis server (for testing)
- Git
- Text editor with shell script support

### Recommended Tools

- **ShellCheck**: Static analysis for shell scripts
  ```bash
  # Install ShellCheck
  sudo apt-get install shellcheck  # Ubuntu/Debian
  brew install shellcheck          # macOS
  
  # Run analysis
  shellcheck redis-helper.sh
  ```

- **Bash Language Server**: For IDE integration
- **Git hooks**: For pre-commit checks

### Setting Up Development Redis

For testing, you can use Docker:

```bash
# Start Redis container
docker run -d --name redis-dev -p 6379:6379 redis:latest

# Test connection
redis-cli ping

# Stop container
docker stop redis-dev
```

## 📋 Feature Development Process

### 1. Planning Phase

- Discuss the feature in an issue
- Get feedback from maintainers
- Plan the implementation approach
- Consider backward compatibility

### 2. Implementation Phase

- Create feature branch
- Implement core functionality
- Add error handling
- Write documentation
- Add menu integration

### 3. Testing Phase

- Test manually with different scenarios
- Test error conditions
- Verify performance impact
- Test on different Redis versions

### 4. Review Phase

- Submit pull request
- Address review feedback
- Update documentation
- Ensure CI passes

## 🐛 Bug Fix Process

### 1. Reproduce the Bug

- Create minimal reproduction case
- Document steps to reproduce
- Identify root cause

### 2. Fix Implementation

- Create fix branch
- Implement minimal fix
- Add regression test if possible
- Verify fix works

### 3. Testing

- Test the specific bug scenario
- Test related functionality
- Ensure no new bugs introduced

## 📚 Documentation Guidelines

### Code Documentation

- Document all public functions
- Explain complex algorithms
- Provide usage examples
- Keep comments up to date

### User Documentation

- Update README.md for new features
- Add usage examples
- Update configuration documentation
- Include screenshots for UI changes

### Changelog

- Add entries for all user-facing changes
- Follow semantic versioning
- Group changes by type (features, fixes, etc.)

## 🔍 Code Review Process

### For Contributors

- Respond to feedback promptly
- Make requested changes
- Ask questions if unclear
- Be open to suggestions

### Review Criteria

- **Functionality**: Does it work as intended?
- **Code Quality**: Is it well-written and maintainable?
- **Performance**: Does it impact performance negatively?
- **Security**: Are there any security implications?
- **Documentation**: Is it properly documented?
- **Testing**: Has it been adequately tested?

## 🏷️ Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Version number bumped
- [ ] Release notes prepared
- [ ] Tagged in Git

## 🤔 Questions and Support

### Getting Help

- **GitHub Discussions**: For general questions
- **GitHub Issues**: For bug reports and feature requests
- **Code Review**: For implementation questions

### Communication Guidelines

- Be respectful and constructive
- Provide context and details
- Use clear and concise language
- Search before asking

## 🎯 Contribution Ideas

### Good First Issues

- Fix typos in documentation
- Add new Redis commands to utilities
- Improve error messages
- Add configuration validation
- Create additional export formats

### Advanced Contributions

- Implement cluster management features
- Add performance benchmarking
- Create web dashboard
- Add notification systems
- Implement advanced monitoring

### Documentation Improvements

- Add more usage examples
- Create video tutorials
- Improve installation guides
- Add troubleshooting sections
- Translate documentation

## 📜 License

By contributing to Redis Helper, you agree that your contributions will be licensed under the GNU General Public License v3.0.

## 🙏 Recognition

Contributors will be:

- Listed in the README.md
- Mentioned in release notes
- Added to the contributors list
- Credited in documentation

Thank you for contributing to Redis Helper! Your efforts help make Redis management easier for everyone.

---

**Questions?** Feel free to open an issue or start a discussion. We're here to help!
