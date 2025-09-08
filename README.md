# My Scratch Pad - VM vs Container Performance Comparison

A Flask web application designed to demonstrate and compare performance characteristics between Virtual Machine (VM) and container deployments. This project provides a systematic approach to benchmarking startup times, resource utilization, and response performance.

## 🎯 Project Purpose

This repository demonstrates:
- **Container vs VM Performance Analysis**: Systematic comparison of deployment methods
- **Automated CI/CD Pipeline**: GitHub Actions integration with Docker Hub
- **Benchmarking Methodology**: 2-minute automated performance testing
- **Infrastructure as Code**: Reproducible environments using Docker and Vagrant

## 📁 Repository Structure

```
my-scratch-pad/
├── README.md                 # This comprehensive guide
├── app.py                    # Flask web application
├── requirements.txt          # Python dependencies
├── pyproject.toml           # Modern Python project configuration
├── schema.sql               # Database schema
├── init_db.py               # Database initialization
├── test_app.py              # Unit tests
├── templates/               # HTML templates
│   ├── base.html
│   ├── index.html
│   ├── create.html
│   ├── edit.html
│   └── post.html
├── Dockerfile               # Container deployment
├── Vagrantfile             # VM deployment
├── scripts/                 # Deployment and benchmarking
│   ├── docker-deploy.sh
│   ├── vagrant-deploy.sh
│   └── benchmark.sh
├── .github/workflows/       # CI/CD automation
│   └── ci-cd.yml
└── .gitignore              # Clean repository practices
```

## 🚀 Quick Start

### Prerequisites

**For Container Testing:**
- Docker Desktop installed and running
- Modern Python 3.12+ with uv package manager

**For VM Testing:**
- Vagrant installed (2.4+)
- VirtualBox or VMware provider

**For CI/CD:**
- GitHub account
- Docker Hub account

### Local Development

```bash
# Clone and setup
git clone https://github.com/mkennedy85/my-scratch-pad.git
cd my-scratch-pad

# Install dependencies with uv
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync

# Initialize database
uv run python init_db.py

# Run application
uv run python app.py
```

Visit `http://localhost:5001` to access the application.

### Run Tests

```bash
# Execute test suite
uv run python -m unittest test_app.py -v
```

## 🐳 Container Deployment

### Build and Run Docker Container

```bash
# Build container image
./scripts/docker-deploy.sh

# Or manually:
docker build -t my-scratch-pad:latest .
docker run -p 5001:5001 my-scratch-pad:latest
```

### Container Features
- **Multi-stage optimization**: Efficient layer caching
- **Security hardening**: Non-root user execution
- **Health monitoring**: Built-in container health checks
- **Minimal footprint**: Python 3.12-slim base image

## 🖥️ VM Deployment

### Launch Virtual Machine

```bash
# Deploy and provision VM
./scripts/vagrant-deploy.sh

# Or manually:
vagrant up
vagrant ssh
```

### VM Configuration
- **Base OS**: Ubuntu 22.04 LTS
- **Resources**: 1GB RAM, 2 CPU cores
- **Network**: Port forwarding 5001:5001
- **Provisioning**: Automated Python and Flask setup

## 📊 Performance Benchmarking

### Automated 2-Minute Benchmarks

```bash
# Run comprehensive benchmarks
./scripts/benchmark.sh docker  # Test container performance
./scripts/benchmark.sh vm      # Test VM performance
./scripts/benchmark.sh compare # Compare results side-by-side
```

### Benchmark Metrics

The benchmarking system measures:

**Startup Performance:**
- **Cold start time**: Time from deployment command to application ready
- **First response**: Time to first successful HTTP response
- **Memory initialization**: RAM usage during startup

**Runtime Performance:**
- **Response times**: Average, median, 95th percentile over 2 minutes
- **Throughput**: Requests per second sustained load
- **Resource utilization**: CPU, memory, disk I/O patterns
- **Stability**: Response time variance and error rates

**Resource Efficiency:**
- **Memory footprint**: Peak and average RAM consumption
- **CPU utilization**: Average and peak processor usage
- **Storage impact**: Disk space and I/O characteristics
- **Network overhead**: Bandwidth and latency measurements

### Understanding Performance Differences

**Expected Container Advantages:**
- ⚡ **Faster startup**: ~2-5 seconds vs ~30-60 seconds for VM
- 💾 **Lower memory**: ~50-100MB vs ~500MB+ for full VM
- 📦 **Smaller footprint**: ~100MB image vs ~2GB VM disk
- 🔄 **Better density**: Run multiple containers vs single VM per resource unit

**Expected VM Advantages:**
- 🔒 **Complete isolation**: Full OS separation vs shared kernel
- 🛠️ **OS flexibility**: Different kernels vs host OS dependency
- 🔧 **System-level control**: Full administrative access vs container limitations
- 🏗️ **Legacy compatibility**: Support for older applications vs container constraints

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The repository includes automated CI/CD:

```yaml
Triggers: Push to main, Pull Requests
Pipeline: Test → Build → Security Scan → Deploy
Registry: Automatic Docker Hub publishing
Security: Vulnerability scanning with Docker Scout
```

### Setup CI/CD

1. **Fork this repository**
2. **Configure Docker Hub secrets:**
   - Go to Repository Settings → Secrets and Variables → Actions
   - Add `DOCKERHUB_USERNAME`: Your Docker Hub username
   - Add `DOCKERHUB_TOKEN`: Docker Hub access token
3. **Push to main branch** triggers the full pipeline

### Docker Hub Integration

Images are automatically published as:
- `your-username/my-scratch-pad:latest` (main branch)
- `your-username/my-scratch-pad:sha-abcd123` (tagged by commit)

## 📈 Performance Analysis Guide

### Running Comparative Analysis

1. **Baseline System**: Ensure no other applications running
2. **Multiple Runs**: Execute benchmarks 3-5 times for statistical accuracy
3. **Consistent Conditions**: Same network, same hardware state
4. **Document Environment**: Note system specs, OS version, resource availability

### Interpreting Results

**Startup Time Analysis:**
- Container should show 5-10x faster startup
- VM includes full OS boot time
- Consider "time to first request" vs "deployment complete"

**Memory Usage Patterns:**
- Container: Application + runtime dependencies only
- VM: Full OS + application + overhead
- Monitor peak vs sustained usage

**Response Time Characteristics:**
- Both should show similar application response times
- Network overhead differences minimal for localhost
- Focus on consistency and stability metrics

**Resource Utilization:**
- Container: Shared kernel, lower overhead
- VM: Dedicated resources, full isolation
- CPU usage patterns may differ under load

### Sample Performance Report Template

```markdown
## Performance Comparison Results

### Test Environment
- Host OS: macOS 14.x / Ubuntu 22.04 / Windows 11
- Hardware: [CPU, RAM, SSD specifications]
- Docker: Version X.Y.Z
- Vagrant: Version A.B.C

### Startup Performance
| Metric | Container | VM | Ratio |
|--------|-----------|----|----- |
| Cold Start | 3.2s | 45.1s | 14.1x faster |
| First Response | 3.8s | 47.3s | 12.4x faster |
| Memory at Start | 78MB | 512MB | 6.6x lower |

### Runtime Performance (2-minute sustained load)
| Metric | Container | VM | Difference |
|--------|-----------|----|----- |
| Avg Response | 45ms | 48ms | 6.7% faster |
| 95th Percentile | 89ms | 94ms | 5.3% faster |
| Requests/sec | 22.1 | 20.8 | 6.3% higher |
| CPU Usage | 12% | 15% | 20% lower |
| Memory Peak | 124MB | 578MB | 78.5% lower |
```

## 🛠️ Development and Customization

### Adding Custom Benchmarks

Extend `scripts/benchmark.sh` with additional metrics:

```bash
# Example: Custom database performance test
measure_database_performance() {
    echo "Testing database operations..."
    # Add your database performance tests here
}
```

### Modifying Application

The Flask application is designed for easy customization:
- Update `app.py` for new routes or functionality
- Modify templates in `templates/` for UI changes
- Extend `test_app.py` for additional test coverage

### Environment Variants

Create different deployment scenarios:
- Add `docker-compose.yml` for multi-container deployments
- Create `Vagrantfile.windows` for Windows VM testing
- Implement `Dockerfile.alpine` for minimal Linux containers

## 🔧 Troubleshooting

### Common Issues

**Container Build Fails:**
```bash
# Check Docker daemon
docker version

# Clean build cache
docker system prune -a

# Verify dependencies
uv sync
```

**VM Won't Start:**
```bash
# Check Vagrant status
vagrant status

# Reload VM configuration
vagrant reload --provision

# Check VirtualBox/VMware
vagrant box list
```

**Benchmark Scripts Fail:**
```bash
# Verify permissions
chmod +x scripts/*.sh

# Check system resources
free -h && df -h

# Monitor during execution
htop  # or Activity Monitor on macOS
```

**Performance Inconsistencies:**
- Ensure no background applications consuming resources
- Run multiple benchmark iterations
- Check for thermal throttling on laptops
- Verify adequate disk space and memory

### Getting Help

1. **Check logs**: `docker logs container-name` or `vagrant ssh -c "journalctl -f"`
2. **Verify environment**: Ensure Docker/Vagrant versions match requirements
3. **Resource monitoring**: Use system monitors during benchmarks
4. **Clean slate**: `docker system prune` and `vagrant destroy` for fresh start

## 📝 Best Practices Demonstrated

### Repository Management
- ✅ **Clean structure**: No build artifacts, logs, or temporary files committed
- ✅ **Comprehensive .gitignore**: Excludes all generated content
- ✅ **Semantic commits**: Clear, descriptive commit messages
- ✅ **Documentation**: README-driven development

### Security
- ✅ **Non-root containers**: Principle of least privilege
- ✅ **Updated dependencies**: Latest secure package versions
- ✅ **Vulnerability scanning**: Automated security checks
- ✅ **Secret management**: No hardcoded credentials

### Performance
- ✅ **Multi-stage builds**: Optimized container layers
- ✅ **Resource limits**: Defined memory and CPU constraints
- ✅ **Health checks**: Application availability monitoring
- ✅ **Efficient provisioning**: Minimal installation footprint

## 🎓 Educational Value

This project demonstrates key cloud computing concepts:

- **Containerization vs Virtualization**: Practical comparison of deployment strategies
- **Infrastructure as Code**: Reproducible environments through configuration
- **Performance Engineering**: Systematic benchmarking and analysis
- **DevOps Practices**: Automated testing, building, and deployment
- **Resource Optimization**: Understanding trade-offs between different deployment methods

## 🔗 Related Resources

- [Docker Documentation](https://docs.docker.com/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Flask Framework](https://flask.palletsprojects.com/)
- [Performance Testing Best Practices](https://martinfowler.com/articles/practical-test-pyramid.html)

## 📄 License

This project is released under the MIT License. See LICENSE file for details.

---

**Created for CMPE-272 Cloud Computing coursework demonstrating VM vs Container performance analysis.**