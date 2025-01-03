1. Enabling direnv
To enable direnv in a shell, add the following line to your shell's configuration file (e.g., .bashrc, .bash_profile, .zshrc):

bash
Copy code
eval "$(direnv hook bash)"
This line initializes direnv each time a shell session is started, allowing it to load environment variables defined in .envrc files.

After editing the configuration file, reload the shell configuration to apply the changes:

bash
Copy code
source ~/.bashrc    # or ~/.zshrc, depending on your shell
2. Disabling direnv for a Session
To temporarily disable direnv in the current shell session, run:

bash
Copy code
direnv deactivate
This will unload the environment variables that direnv was managing for that session. If you want to restore the session, simply re-enable direnv:

bash
Copy code
eval "$(direnv hook bash)"
3. Blocking and Allowing .envrc Files
When you create a .envrc file, direnv will block it for safety until you approve it. If a .envrc is blocked, you will see an error like:

vbnet
Copy code
direnv: error .envrc file is blocked. Run `direnv allow` to approve its content
To approve and allow the .envrc file in the current directory, run:

bash
Copy code
direnv allow
This will allow direnv to execute the contents of .envrc and load any environment variables defined there.

If you want to block a previously allowed .envrc file, use:

bash
Copy code
direnv deny
4. Reloading Environment Variables
After modifying the .envrc file or when switching directories, you can reload the environment variables by running:

bash
Copy code
direnv reload
This reloads the .envrc and applies any changes to the environment.

You can also add the --debug flag to get more verbose output while reloading:

bash
Copy code
direnv --debug reload
5. Viewing Environment Variables Managed by direnv
To check if direnv is properly managing an environment variable (e.g., $SSH_USER), simply use:

bash
Copy code
echo $SSH_USER
If direnv is correctly managing the environment, this will show the value set in the .envrc file.

6. Global Environment Variables with direnv
If you want to define environment variables globally (across multiple projects), create a global .envrc file in your home directory. For example, you can create a file like ~/.envrc and define environment variables there.

Make sure to allow the global .envrc file using:

bash
Copy code
direnv allow ~/.envrc
Then, any time you start a new shell session or move between directories, direnv will automatically apply the variables from that file, unless overridden by local .envrc files.

7. Deactivating and Reactivating direnv for a Session
To deactivate direnv for a session, you can either:

Run direnv deactivate to remove the environment variables for that session.
Remove the eval "$(direnv hook bash)" line from your shell configuration file to completely stop direnv from running automatically in future sessions.
If you choose the second option, don’t forget to re-enable direnv when needed by adding that line back to your shell configuration file and reloading the shell.

8. Troubleshooting
"direnv: command not found": This error occurs when direnv is not installed or not found in your $PATH. Verify your installation and $PATH settings.
"direnv: error .envrc file is blocked": You need to approve the .envrc file by running direnv allow in the directory.
Environment variables not being loaded: Ensure the eval "$(direnv hook bash)" line is correctly added to your shell configuration and reload the shell.
Summary of Key Commands
Enable direnv:
Add eval "$(direnv hook bash)" to your shell's configuration file (e.g., .bashrc, .bash_profile).

Disable direnv temporarily:
direnv deactivate

Block or Allow .envrc:
direnv allow (to approve a blocked .envrc)
direnv deny (to block an allowed .envrc)

Reload environment variables:
direnv reload

Check environment variables:
echo $VAR_NAME