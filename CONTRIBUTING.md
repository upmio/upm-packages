# Contributing to UPM Packages

Thank you for your interest in contributing to UPM Packages! This document provides guidelines and instructions for contributors.

## Getting Started

### Prerequisites

- Docker (with buildx enabled)
- Helm 3.x
- Go 1.19+
- kubectl
- yq (command-line YAML processor)

### Development Environment Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/upmio/upm-packages.git
   cd upm-packages
   ```

2. **Install development tools**

   ```bash
   # Install yq for YAML processing
   sudo wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
   sudo chmod +x /usr/local/bin/yq

   # Install shellcheck for shell script validation
   sudo apt-get install shellcheck

   # Install yamllint for YAML validation
   pip install yamllint
   ```

3. **Set up pre-commit hooks**

   ```bash
   # Install pre-commit
   pip install pre-commit

   # Install hooks
   pre-commit install
   ```

## Development Workflow

### Adding New Components

1. **Create component directory structure**

   ```
   <component>/<version>/
   ├── image/
   │   ├── Dockerfile
   │   ├── service-ctl.sh
   │   └── supervisord.conf
   └── charts/
       ├── Chart.yaml
       ├── values.yaml
       ├── files/
       │   ├── *.tpl
       │   └── *ParametersDetail.json
       └── templates/
           ├── *.yaml
           └── _helpers.tpl
   ```

2. **Follow naming conventions**

   - Chart names: Use hyphens and include version (e.g., `mysql-community-8.4.5`)
   - Version directories: Use semantic versioning (e.g., `8.4.5`)
   - Template files: Use camelCase for Go template functions

3. **Update unified management script**
   Add your component to `upm-pkg-mgm.sh` with proper install/uninstall logic

### Building and Testing

1. **Build Docker images**

   ```bash
   # Build multi-architecture image
   docker buildx build --platform linux/amd64,linux/arm64 -t quay.io/upmio/<component>:<version> <component>/<version>/image/

   # Test locally
   docker run -it quay.io/upmio/<component>:<version> bash
   ```

2. **Validate Helm charts**

   ```bash
   # Lint chart
   helm lint <component>/<version>/charts/

   # Test installation
   helm install --dry-run --debug test-release <component>/<version>/charts/

   # Package chart
   helm package <component>/<version>/charts/
   ```

3. **Run tests**

   ```bash
   # Run all tests
   ./scripts/test.sh

   # Run specific test
   ./scripts/test.sh unit
   ./scripts/test.sh integration
   ```

### Template Development

1. **Available template functions**

   - `getenv "VAR_NAME"` - Get environment variable
   - `getv "/path/to/param"` - Get parameter from values
   - `add arg1 arg2` - Addition operation
   - `mul arg1 arg2` - Multiplication operation
   - `atoi "string"` - String to integer conversion

2. **Parameter configuration**

   - Define parameters in `*ParametersDetail.json`
   - Map values in `configValue.yaml`
   - Use templates in `*.tpl` files

3. **Validation**
   - All parameters must have default values
   - Use proper type validation (String, Integer, Boolean, Enumeration)
   - Include both English and Chinese descriptions

## Code Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -euo pipefail` for error handling
- Follow shellcheck recommendations
- Use meaningful variable names in UPPER_CASE

### Dockerfiles

- Use specific base image versions
- Combine RUN commands when possible
- Use multi-stage builds for optimization
- Set proper metadata (labels, health checks)

### Helm Charts

- Follow Kubernetes naming conventions
- Use proper resource limits and requests
- Include proper liveness/readiness probes
- Use Helm helper functions consistently

### YAML Files

- Use 2-space indentation
- Sort lists alphabetically when appropriate
- Use proper YAML syntax (no tabs)
- Include meaningful comments

## Pull Request Process

1. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**

   - Follow the coding standards
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**

   ```bash
   # Run all tests
   ./scripts/test.sh

   # Validate charts
   ./scripts/validate-charts.sh

   # Check code quality
   ./scripts/lint.sh
   ```

4. **Submit pull request**
   - Use descriptive title and clear description
   - Link to relevant issues
   - Include test results
   - Request review from maintainers

## Code Review Guidelines

### Review Checklist

- [ ] Code follows project standards
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] Security considerations are addressed
- [ ] Performance impact is considered
- [ ] Backward compatibility is maintained

### Review Process

1. Automated checks must pass
2. At least one maintainer approval required
3. Address all review comments
4. Update PR based on feedback
5. Final approval before merge

## Issue Reporting

### Bug Reports

- Use bug report template
- Include reproduction steps
- Provide environment details
- Include logs and error messages

### Feature Requests

- Use feature request template
- Describe the use case
- Explain the proposed solution
- Consider alternative approaches

## Security Guidelines

### Vulnerability Reporting

- Report security issues privately
- Use SECURITY.md for contact information
- Do not disclose vulnerabilities publicly
- Follow responsible disclosure practices

### Code Security

- Use non-root users in containers
- Implement proper resource limits
- Include security contexts
- Scan images for vulnerabilities

## Release Process

### Versioning

- Use semantic versioning (MAJOR.MINOR.PATCH)
- Chart version is always `1.0.0`
- App version matches software version

### Release Steps

1. Update version numbers
2. Update CHANGELOG.md
3. Create release branch
4. Build and test artifacts
5. Create GitHub release
6. Publish charts and images

## Community Guidelines

### Communication

- Be respectful and constructive
- Focus on technical discussions
- Help newcomers and answer questions
- Share knowledge and experience

### Meetings

- Join community calls for major discussions
- Participate in planning sessions
- Present work and get feedback

## Getting Help

- Documentation: Check project README and docs/
- Issues: Search existing issues or create new ones
- Discussions: Join GitHub discussions
- Email: Contact maintainers for private questions

## License

By contributing to this project, you agree that your contributions will be licensed under the project's license (see LICENSE file).
