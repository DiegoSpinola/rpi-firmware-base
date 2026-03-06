# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the Alloy framework template.

## Alloy Framework Overview

**Alloy** is a Docker-based development framework designed to provide consistent, isolated development environments across teams. The name represents combining different technologies (like an alloy combines metals) to create enhanced development capabilities.

### Core Philosophy
- **Containerized Development**: All work happens inside Docker containers
- **Consistency**: Eliminates "works on my machine" issues
- **Collaboration**: Standardized environments across team members
- **Infrastructure as Code**: Development environment defined in Docker images

## Template Architecture

This template provides a starting point for Alloy-based projects with the following structure:

```
alloy-template/
├── .config              # Dependency configuration (JSON)
├── .gitignore          # Git ignore patterns
├── alloy.sh            # Container launch script
├── build.sh            # Build automation script
├── deploy.sh           # Deployment script
├── run.sh              # Service run script
├── docker-compose.yml  # Docker services definition
├── demo/               # Demo dependency (fetched via alloy clone)
└── README.md           # Basic documentation
```

### Key Files Explained

- **`.config`**: JSON file defining project dependencies and deployable services
- **`alloy.sh`**: Launches the Alloy Docker container with proper mounts and networking
- **`build.sh`**: Builds Docker images with git commit hash tagging
- **`deploy.sh`**: Pushes images to the internal registry (push.igmify.com)
- **`run.sh`**: Starts services using docker-compose
- **`docker-compose.yml`**: Defines services, ports, and build configurations

## Environment Setup & Commands

### Starting the Environment
```bash
./alloy.sh
```

This script:
1. Pulls the latest Alloy image from `registry.igmify.com/igma/rd/alloy:latest`
2. Starts a container with Docker-in-Docker capabilities
3. Mounts your project directory as `/root/<directory-name>/`
4. Enables network admin capabilities for VPN functionality

### Inside the Container
Once inside the Alloy container, you have access to these commands:

- **`alloy init`**: Initializes environment (VPN check, SSH keys, Docker setup)
- **`alloy clone`**: Fetches all dependencies defined in `.config`
- **`alloy login`**: Authenticates with Docker registries
- **`alloy exit`**: Properly shuts down the environment
- **`alloy help`**: Lists all available commands

### Environment Checks
All scripts verify they're running inside Alloy by checking:
```bash
if [[ "$CUSTOM_HOSTNAME" != "alloy" ]]; then
  echo "ERROR: This script must be run inside the Alloy environment."
  exit 1
fi
```

## Development Workflow

### 1. Initial Setup
```bash
# Outside container - start Alloy environment
./alloy.sh

# Inside container - fetch dependencies
alloy clone

# Build the project
./build.sh
```

### 2. Development Cycle
```bash
# Make changes to your code
# Build with automatic git commit hash tagging
./build.sh

# Run services locally
./run.sh

# Deploy to registry when ready
./deploy.sh
```

### 3. Git Integration
- Clean repository: Uses actual git commit hash for image tagging
- Dirty repository: Uses "WIP" tag to indicate work-in-progress
- Images tagged as "WIP" are not promoted to "latest" during deployment

## Configuration Deep Dive

### .config File Format
The `.config` file uses the "igma-alloy-1.0" format:

```json
{
  "version": "igma-alloy-1.0",
  "dependencies": [
    {
      "repourl": "git@github.com:igma-company/alloy-dummy-helloworld.git",
      "branch": "master",
      "commitHash": "latest",
      "path": "./demo/"
    }
  ],
  "deployable-service": "demo-webserver"
}
```

#### Configuration Options
- **`repourl`**: Git repository URL (SSH format)
- **`branch`**: Target branch to clone
- **`commitHash`**: Specific commit or "latest" for HEAD
- **`path`**: Local directory to clone dependency into
- **`deployable-service`**: Service name(s) to deploy to registry

### Dependency Management
- Dependencies are cloned into your project directory
- Automatically added to `.gitignore` to avoid committing dependencies
- Supports recursive dependency resolution
- Checks for circular dependencies

## Docker & Infrastructure

### CRITICAL: Docker-in-Docker Networking

**Important**: Alloy runs in a Docker-in-Docker environment where the Docker daemon is on the host machine, not inside the Alloy container. This has important networking implications:

#### Port Access
- Services expose ports on the **host machine**, not inside the Alloy container
- To access running services, you need the **actual host IP address**
- **DO NOT assume localhost/127.0.0.1 will work**

#### Example
```yaml
# docker-compose.yml
services:
  demo-webserver:
    ports:
      - "8080:80"  # This exposes port 8080 on the HOST machine
```

To access this service:
- ❌ Wrong: `http://localhost:8080`
- ✅ Correct: `http://[HOST_IP]:8080`

**Always ask the user for their host IP address when they need to access running services.**

#### Volume Mounts in Docker-in-Docker

**Critical**: In Docker-in-Docker environments, **bind mounts will not work** for containers defined in docker-compose files. Only **named volumes** should be used.

```yaml
# ❌ This will NOT work in DinD:
services:
  myservice:
    volumes:
      - ./local-folder:/container/path  # Bind mount - will fail

# ✅ This WILL work in DinD:
services:
  myservice:
    volumes:
      - mydata:/container/path  # Named volume - works correctly

volumes:
  mydata:  # Define the named volume
```

**Why**: The Docker daemon runs on the host, not inside the Alloy container. Bind mounts reference paths that don't exist in the host's filesystem context. Always use named volumes for persistent data in docker-compose stacks.

### Image Naming Convention
All images follow this pattern:
```
push.igmify.com/[project-name]/[service-name]:${COMMIT_HASH}
```

### Registry & VPN Requirements
- Internal registry: `push.igmify.com`
- Requires IGMA R&D VPN connection
- Automatic authentication via `alloy login`
- Registry connectivity checked before deployment

### Environment Variables
- **`COMMIT_HASH`**: Set automatically by build scripts
- **`CUSTOM_HOSTNAME`**: Set to "alloy" inside containers
- **Docker socket**: Mounted as `/var/run/docker.sock`

## Best Practices & Patterns

### Error Handling
All scripts include proper error checking:
```bash
# Environment verification
if [[ "$CUSTOM_HOSTNAME" != "alloy" ]]; then
  echo "ERROR: This script must be run inside the Alloy environment."
  exit 1
fi

# Registry connectivity
if ! ping -4 -c 1 "$REGISTRY_URL" > /dev/null; then
  echo "ERROR: Registry not reachable. Check VPN connection."
  exit 1
fi
```

### Build Process
1. Check for clean git repository
2. Generate commit hash or "WIP" tag
3. Export `COMMIT_HASH` environment variable
4. Build Docker images with hash tagging
5. Optional: Push to registry if not WIP

### Deployment Process
1. Verify Alloy environment
2. Check registry connectivity
3. Build images
4. Read deployable services from `.config`
5. Push images to registry
6. Tag non-WIP images as "latest"

## Creating New Projects

### From Template
1. Copy the alloy-template directory
2. Update `.config` with your dependencies
3. Modify `docker-compose.yml` for your services
4. Update image names to match your project
5. Customize build/run/deploy scripts as needed

### Java Projects (Maven/Gradle)
- Use `alloy-mvn` base image
- Extend hsCmdLine framework for CLI tools
- Include Maven shade plugin for executable JARs
- Follow package naming: `com.igma.rd.[project]`

### Node.js Projects
- Standard npm/yarn workflow
- Include Dockerfile for containerization
- Use multi-stage builds for optimization

### Python Projects
- Standard pip/poetry workflow
- Include requirements.txt or pyproject.toml
- Consider virtual environments in containers

### Integration with hsCmdLine Framework
For Java CLI tools extending the hsCmdLine framework:
- Extend `hsCmdLine` base class
- Use `@Option` annotations for arguments
- Use `@hsEnvVar` for environment variables
- Implement `run()` method for main logic
- Use `log()` for output, `exec` for shell commands
- Call `feedWatchDog()` for long-running operations

## Network Troubleshooting

### Common Issues
1. **Can't access running services**: Remember to use host IP, not localhost
2. **Registry unreachable**: Check VPN connection
3. **Docker commands fail**: Ensure Docker daemon is running on host
4. **Port conflicts**: Check if ports are already in use on host

### Debugging Commands
```bash
# Check Docker connectivity
docker info

# Check registry connectivity
ping push.igmify.com

# Check running containers
docker ps

# Check exposed ports
docker-compose ps
```

### Getting Host IP
When users need to access services, ask them to provide their host machine's IP address. Common ways to find it:
- `ip addr show` (Linux)
- `ifconfig` (macOS/Linux)
- `ipconfig` (Windows)
- Network settings in OS

## Internal Infrastructure

- **Maven Repository**: http://maven.igmify.com:8080/
- **Docker Registry**: push.igmify.com
- **LLM API**: http://llm.igmify.com:8080/
- **Alloy Base Images**: registry.igmify.com/igma/rd/alloy
- **VPN Required**: For all internal resources
- **SSH Keys**: Fetched automatically via VPN from userium.igmify.com