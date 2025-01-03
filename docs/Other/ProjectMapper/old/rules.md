# Project Reconfiguration Rules

## Core Principles
1. **Single Source of Truth**
   - Each component should exist in only one location
   - No duplicate configurations or utilities
   - All tests reference the main codebase

2. **Clear Dependency Chain**
   - Follow the dependency order in file_dependency_map.md
   - Implement in order: utils → core → ssh → tests
   - Maintain critical path relationships

3. **Documentation as Truth**
   - ALWAYS refer to directory_mapping.md and file_dependency_map.md for:
     - Checking file/directory existence
     - Verifying dependencies
     - Understanding file relationships
     - Confirming directory structures
   - Never use direct filesystem checks
   - These maps are the only source of truth for project structure

4. **File Management**
   - NEVER create new files
   - Only move existing files to their correct locations
   - Only modify existing files to fix paths or dependencies
   - All required files should already exist in the project
   - If a file is needed, it must be in the mapping files

## Specific Consolidation Rules

### 1. Library Consolidation
- **Monitoring**:
  - Keep `lib/monitoring/` as primary
  - Move any unique files from `lib/monitor/` to `lib/monitoring/`
  - Remove empty `lib/monitor/` directory

- **Security**:
  - Keep `lib/security/` as primary
  - Move any unique files from `lib/ssh/` to `lib/security/`
  - Remove empty `lib/ssh/` directory

- **Utils**:
  - Keep `lib/utils/` as primary location
  - Consolidate duplicate utils from test directories
  - Maintain error_handler.sh, logger.sh, path_manager.sh

### 2. Test Organization
- **Test Structure**:
  - Keep `tests/done/` for completed tests
  - Use `tests/fixtures/` for test data
  - Keep `tests/utils/mock_bin/` as primary mock location
  - Remove empty `mock_bin/`

- **SSH Toolkit Integration**:
  - Move unique configs from `tests/ssh_toolkit/config/` to `tests/fixtures/config/`
  - Move unique monitoring scripts to main `lib/monitoring/`
  - Move unique SSH scripts to main `ssh/` directory
  - Move unique utils to `lib/utils/`

### 3. Configuration Management
- **Main Configs**:
  - Keep production configs in `config/main/`
  - Move test configs to `tests/fixtures/config/`
  - Maintain backup of critical configs

### 4. File Dependencies
Follow this order when moving files:
1. Utils (most depended upon)
2. Monitoring libraries
3. Security components
4. SSH management files
5. Test files

### 5. Validation Requirements
Before each move:
- Check file's dependencies in file_dependency_map.md
- Verify no other components will break
- Create backup if needed

After each move:
- Update all file references
- Run relevant test suite
- Document the change

## Reference Documents
- Directory Structure: docs/project_map/directory_mapping.md
- Dependencies: docs/project_map/file_dependency_map.md
- Test Analysis: docs/project_map/test_analysis_results.md

## Implementation Steps
1. Consolidate library files
   - Start with utils (most dependencies)
   - Then monitoring
   - Then security

2. Reorganize tests
   - Move test toolkit files
   - Update test configurations
   - Remove duplicates

3. Update configurations
   - Centralize main configs
   - Update test configs
   - Verify paths

4. Verify and test
   - Run test suite
   - Check all dependencies
   - Document changes
