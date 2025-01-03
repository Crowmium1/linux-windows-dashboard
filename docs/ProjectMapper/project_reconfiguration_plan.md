# SSH Dashboard Monitor - Project Reconfiguration Plan

## Overview
This document outlines the step-by-step plan for reconfiguring the SSH Dashboard Monitor project, with references to detailed documentation for each step.

## Phase 1: Analysis & Planning
1. Review current directory structure
   - Reference: `docs/project_map/directory_mapping.md`
   - Focus on: Current Directory Issues section

2. Understand file dependencies
   - Reference: `docs/project_map/file_dependency_map.md`
   - Focus on: Critical Path Analysis section

3. Review test requirements
   - Reference: `docs/project_map/current_test.md`
   - Focus on: Test Coverage and Dependencies sections

## Phase 2: Core Restructuring
1. Library Consolidation
   - Reference: `docs/project_map/restructure.md`
   - Key tasks:
     - Consolidate monitoring libraries
     - Merge security components
     - Centralize utility functions

2. Test Framework Reorganization
   - Reference: `docs/project_map/test_analysis_results.md`
   - Key tasks:
     - Consolidate test directories
     - Update test dependencies
     - Migrate test configurations

3. System Architecture Updates
   - Reference: `docs/project_map/orchestrator_explanation.txt`
   - Key tasks:
     - Update orchestrator components
     - Revise monitoring chain
     - Restructure SSH management

## Phase 3: Implementation Order
1. Core Components
   ```
   1. Utility Libraries
   2. Security Components
   3. Monitoring System
   4. SSH Management
   ```

2. Support Systems
   ```
   1. Configuration Management
   2. Logging System
   3. Test Framework
   4. Documentation
   ```

## Phase 4: Verification
1. System Testing
   - Reference: `docs/project_map/test_analysis_results.md`
   - Verify each component after migration

2. Integration Testing
   - Reference: `docs/project_map/file_dependency_map.md`
   - Test critical chains and dependencies

## Phase 5: Cleanup and Consolidation

### Empty Directories to Remove
1. `lib/monitor/` - Empty directory, redundant with lib/monitoring/
2. `config/monitor/` - Empty directory
3. `config/recovery/` - Empty directory
4. `config/ssh/` - Empty directory
5. `tests/fixtures/` - Empty directory
6. `tests/mock_bin/` - Empty directory
7. `docs/New/` - Empty directory

### Duplicate Files Analysis
1. In archive/:
   - `orchestrator_copy.sh` - Duplicate of core/orchestrator.sh
   - `orchestrator_small.sh` - Another duplicate of core/orchestrator.sh
   - `test_orchestrator_small.sh` - Duplicate of tests/test_orchestrator.sh

2. In tests/ssh_toolkit/:
   - `ssh_manager.sh` duplicates functionality from lib/ssh/
   - `setup_passwordless_ssh.sh` duplicates functionality from lib/ssh/

3. In tests/done/:
   - Test files should be consolidated with main test files where duplicated

### Dependencies to Preserve
1. Core Dependencies:
   - utils.sh is required by all components
   - logger.sh and error_handler.sh are critical dependencies
   - main_config.conf is required for system configuration

2. SSH Management:
   - ssh_config is essential for SSH connections
   - keyring_diagnostic.sh for SSH key management

3. Test Framework:
   - run_tests.sh is the primary test runner
   - test data and configurations in tests/data/

## Phase 6: Final Verification
1. Verify all empty directories are removed
2. Confirm no critical files were removed
3. Test system functionality after cleanup
4. Update documentation to reflect changes

## Critical Success Factors
1. Maintain all existing functionality
2. Zero downtime during migration
3. Complete test coverage
4. Updated documentation

## Next Steps
1. Begin with Phase 1 Analysis
2. Create detailed migration scripts
3. Set up test environments
4. Schedule implementation phases

For detailed implementation steps of each phase, refer to the corresponding documents in the `docs/project_map` directory.
