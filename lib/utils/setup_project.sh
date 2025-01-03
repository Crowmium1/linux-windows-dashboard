#!/bin/bash

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create main project directories
mkdir -p "$PROJECT_ROOT"/{lib,var,tmp,log,config,tests}

# Create subdirectories
# lib - for shared libraries and modules
mkdir -p "$PROJECT_ROOT/lib"/{ssh,monitor,recovery,utils}

# var - for variable data
mkdir -p "$PROJECT_ROOT/var"/{run,lock,state,cache}

# tmp - for temporary files
mkdir -p "$PROJECT_ROOT/tmp"/{ssh,monitor,recovery}

# log - for log files
mkdir -p "$PROJECT_ROOT/log"/{ssh,monitor,recovery,test}

# config - for configuration files
mkdir -p "$PROJECT_ROOT/config"/{ssh,monitor,recovery}

# tests - for test files and mock data
mkdir -p "$PROJECT_ROOT/tests"/{mock_bin,utils,data,fixtures}

# Set permissions
chmod -R 755 "$PROJECT_ROOT"/{lib,scripts}
chmod -R 777 "$PROJECT_ROOT"/{var,tmp,log}

echo "Project directory structure created successfully!"
