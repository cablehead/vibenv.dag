# vibenv - Containerized Development Environments

## Project Overview

This project provides containerized development environments using Dagger with remote execution for persistent, resumable sessions.

## Architecture

- **Local**: MacBook with Docker client connected to remote via SSH over SSM
- **Remote**: EC2 instance with Docker engine, Dagger engine, and local registry
- **Sessions**: Persistent Docker containers that survive connection drops

## Key Files

- `vibenv.dag` - Main Dagger script for development environment
- `vibenv/mod.nu` - Nushell module with launcher functions
- `config/` - Personal configurations (Zellij, Nushell) mounted into containers

## Usage

### Setup (one-time)
```nushell
use vibenv
vibenv create launcher
```

### Launch persistent sessions
```nushell
vibenv launch my-task
docker attach vibenv-my-task
```

### Direct execution (legacy)
```nushell
vibenv remote-launch my-task
```

## Debugging the Create Launcher

When the `vibenv create launcher` function has issues, use these debugging approaches:

### Check if files are in the built container
```bash
docker run --rm localhost:5000/vibenv-launcher:latest nu -c 'ls'
docker run --rm localhost:5000/vibenv-launcher:latest nu -c 'ls vibenv'
```

### Test module loading
```bash
docker run --rm localhost:5000/vibenv-launcher:latest nu -c 'use vibenv; help vibenv'
```

### Check working directory
```bash
docker run --rm localhost:5000/vibenv-launcher:latest nu -c 'pwd'
```

### Debug failed containers
```bash
docker logs <container-name>
```

### Common Issues

1. **Files not in container**: Use `with-directory` instead of `with-mounted-directory` to copy files into the image
2. **Module not found**: Ensure the repo files are properly copied with `with-directory`
3. **Recursive calls**: `launch` should call `remote-launch` inside the container, not itself
4. **Docker CLI missing**: Install `docker.io` package in the container build
5. **Dagger connection errors**: Ensure both Docker and Dagger sockets are mounted and environment variables are correct

### Debugging Dagger Connection Issues

When containers show HTTP/2 connection errors to buildkit:

1. **Check Docker CLI availability**:
   ```bash
   docker run --rm localhost:5000/vibenv-launcher:latest which docker
   ```

2. **Test basic Docker socket access**:
   ```bash
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock localhost:5000/vibenv-launcher:latest docker ps
   ```

3. **Verify Dagger socket exists**:
   ```bash
   docker run --rm -v /run/dagger:/run/dagger localhost:5000/vibenv-launcher:latest ls -la /run/dagger/
   ```

4. **Test Dagger with both sockets**:
   ```bash
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v /run/dagger:/run/dagger localhost:5000/vibenv-launcher:latest dagger core engine local-cache entry-set entries
   ```

### Required Environment Variables

- `_EXPERIMENTAL_DAGGER_RUNNER_HOST=unix:///run/dagger/engine.sock` (not `/var/run/docker.sock`)

### Required Volume Mounts

- `-v /var/run/docker.sock:/var/run/docker.sock` (for Docker CLI)
- `-v /run/dagger:/run/dagger` (for Dagger engine access)

## Development Notes

- Use nushell syntax: round brackets `()` for multiline commands, not backslashes
- Use raw strings `r#'...'#` for dagger pipelines to avoid escaping issues
- The `create launcher` function builds and publishes the container, then pulls it to host Docker
- The `launch` function creates detached Docker containers for persistence
- The `remote-launch` function preserves the original direct dagger execution behavior