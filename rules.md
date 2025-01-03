
# Follow these Rules

All tests reference the main codebase

Each component should exist in only one location

Adjust the files to the current config and var folder inside the tests folder and outside the tests folders.

Don't delete too much. Ask if you feel the need to and say why.

Implement appropriate pathing throughout the project, but keep the .envrc pathing in mind if it proves useful.

Consult me if you feel it necessary to create a new config file or add configuration to the .envrc file.

Refernce and update configuration files as you go
Verify paths as you go
Check all dependencies as you go

Guides go to the docs/Guides folder

Use the global .envrc file for environment variables, the local .envrc file for project-specific variables, the regular config file for configurations and the yaml file for variables thoughout where appropriate.

- Start with utils (most dependencies)
- Then monitoring
- Then security

The incomplete folder is for files which habe passed all tests. The complete folder is for files which have not.

<!-- 
You may ignore what's here for now.
Don't create new files, ask if you feel the need to. Only change existing files. It is okay to complete populate an empty file. If you see one do it appropriately.
All configurations not being tested go in the configs folder. 
All required files should already exist in the project -->
