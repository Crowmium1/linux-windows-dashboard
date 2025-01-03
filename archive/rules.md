# Project Rules and Guidelines

## Testing Rules
- All tests will abide by a global test_mode variable
- Each test file must have a corresponding test helper in utils/
- Tests should clean up after themselves
- Tests should be independent and not rely on state from other tests
- All test files should follow the pattern: test_*.sh
- Test output should be clear and indicate exactly what failed
- Test environment setup should be isolated from production environment

## Code Construction
- All shell scripts must start with proper shebang (#!/bin/bash)
- Use set -e to ensure scripts exit on error
- All functions must have clear documentation
- Use meaningful variable names that indicate purpose
- Always quote variables to prevent word splitting
- Check for required tools/dependencies at start of script
- Use readonly for constants
- Include error handling for all file operations

## Context and Search
- Keep all related files in appropriate directories (core/, utils/, ssh/, config/)
- Document dependencies at the top of each file
- Use consistent naming conventions across the project
- Maintain a clear directory structure
- Include README files in each major directory
- Document any required environment variables

## File Operations
- Always use absolute paths when possible
- Create parent directories before writing files
- Check file existence before operations
- Set appropriate permissions after file creation
- Use safe copy operations with error checking
- Handle path differences between Windows and WSL
- Back up important files before modification

## Variables and Environment
- Define all variables at the top of the script
- Use uppercase for global variables
- Use lowercase for local variables
- Export environment variables when needed
- Document required environment variables
- Use default values for optional variables
- Validate all input parameters

## Error Handling
- Provide meaningful error messages
- Log errors with appropriate context
- Include line numbers in error output
- Handle edge cases explicitly
- Fail fast and fail clearly
- Clean up resources on error
- Return appropriate exit codes

## Documentation
- Include usage examples in comments
- Document function parameters
- Explain complex logic
- Keep track of changes in current.test.md
- Document known limitations
- Include troubleshooting guides
- Maintain up-to-date requirements.txt