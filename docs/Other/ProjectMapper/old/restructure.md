# SSH Dashboard Monitor - Directory Restructure Analysis

## Current Directory Structure Analysis

### Core Directories (Keep)

1. `core/` - Essential, Keep
   - Contains primary functionality
   - No redundancy found
   - Critical for system operation

2. `config/` - Essential, Keep
   - Central configuration storage
   - Should be enhanced with templates from test files
   - Required for system configuration

3. `ssh/` - Essential, Keep
   - Core SSH functionality
   - Should absorb relevant files from tests/done
   - Critical for SSH operations

4. `utils/` - Essential, Keep
   - Utility functions
   - Should absorb relevant files from tests/done
   - Required for common operations

### Redundant Directories (Consolidate/Remove)

1. `archive/` - Redundant, Remove
   - Contains:
     - orchestrator_copy.sh
     - orchestrator_small.sh
     - test_orchestrator_small.sh
   - Action: Move relevant content to core/ or tests/
   - Reason: Duplicate/old versions of existing files

2. `PROJECT_MAP/` - Redundant with Documentation
   - Action: Merge into docs/
   - Reason: Project structure documentation should be centralized

3. `scripts/` - Redundant with core/
   - Action: Move relevant scripts to core/ or utils/
   - Reason: Separate scripts directory adds unnecessary complexity

4. `lib/` - Partially Redundant
   - Action: Analyze contents and distribute to core/ or utils/
   - Reason: Library functions should be in utils/ or core/

### Temporary/Generated Directories (Standardize)

1. `tmp/` - Keep but Standardize
   - Action: 
     - Create clear structure for test/production temp files
     - Add to .gitignore
     - Document cleanup procedures

2. `log/` - Keep but Standardize
   - Action:
     - Create clear structure for test/production logs
     - Add to .gitignore
     - Implement log rotation

3. `var/` - Redundant with tmp/
   - Action: Merge into tmp/
   - Reason: Both serve as temporary storage

### Test and Documentation Directories

1. `tests/` - Keep but Reorganize
   - Current structure:
     - done/ (completed tests)
     - Various test files
   - Action:
     - Move implementation files to appropriate directories
     - Organize tests by component
     - Create clear test hierarchy

2. `docs/` - Keep but Enhance
   - Action:
     - Absorb PROJECT_MAP/
     - Create clear documentation structure
     - Update with current implementation details

## Proposed New Structure

```
ssh_dashboard_monitor/
├── core/                     # Core functionality
│   ├── system/              # System monitoring
│   ├── ssh/                 # SSH operations
│   └── orchestrator/        # System orchestration
│
├── utils/                   # Utility functions
│   ├── common/             # Common utilities
│   ├── security/           # Security utilities
│   └── monitoring/         # Monitoring utilities
│
├── config/                  # Configuration
│   ├── templates/          # Configuration templates
│   └── production/         # Production configs
│
├── tests/                   # Test files
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   └── security/          # Security tests
│
├── docs/                    # Documentation
│   ├── api/               # API documentation
│   ├── setup/             # Setup guides
│   └── architecture/      # Architecture docs
│
└── var/                    # Variable data
    ├── log/               # Log files
    └── tmp/               # Temporary files
```

## Implementation Plan

### Phase 1: Core Structure
1. Create new directory structure
2. Move core files to appropriate locations
3. Update import paths

### Phase 2: Test Reorganization
1. Extract implementation from tests
2. Move test files to new structure
3. Update test paths

### Phase 3: Documentation
1. Move PROJECT_MAP to docs/
2. Update documentation structure
3. Generate new documentation

### Phase 4: Cleanup
1. Remove redundant directories
2. Update .gitignore
3. Verify all paths

## Migration Steps

### 1. Core Files
```bash
# Create new structure
mkdir -p core/{system,ssh,orchestrator}
mkdir -p utils/{common,security,monitoring}
mkdir -p config/{templates,production}

# Move files
mv core/*.sh core/system/
mv ssh/*.sh core/ssh/
mv archive/orchestrator*.sh core/orchestrator/
```

### 2. Test Files
```bash
# Create test structure
mkdir -p tests/{unit,integration,security}

# Move test files
mv tests/done/test_*.sh tests/unit/
mv tests/test_*.sh tests/integration/
```

### 3. Documentation
```bash
# Create doc structure
mkdir -p docs/{api,setup,architecture}

# Move documentation
mv PROJECT_MAP/* docs/architecture/
mv *.md docs/
```

### 4. Cleanup
```bash
# Remove redundant directories
rm -rf archive PROJECT_MAP scripts lib var

# Create new var structure
mkdir -p var/{log,tmp}
```

## Post-Migration Tasks

1. Update Paths:
   - Fix all import statements
   - Update configuration paths
   - Update test references

2. Documentation:
   - Update README
   - Create directory structure documentation
   - Update setup guides

3. Testing:
   - Verify all tests pass in new structure
   - Update test environment setup
   - Add new structure tests

4. Cleanup:
   - Remove empty directories
   - Update .gitignore
   - Clean up temporary files
