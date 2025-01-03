# SSH Dashboard Monitor Troubleshooting Guide

## Common Issues and Solutions

### SSH Setup Issues

#### Key Generation Failures
```
! SSH key already exists
✗ Adding key to agent
```
**Solution**:
1. Check key permissions: `chmod 600 ~/.ssh/id_ed25519`
2. Restart SSH agent: `eval $(ssh-agent -s)`
3. Add key manually: `ssh-add ~/.ssh/id_ed25519`

#### Connection Issues
```
Permission denied (publickey)
```
**Solution**:
1. Verify key copied to remote: `ssh-copy-id user@host`
2. Check remote permissions: `chmod 700 ~/.ssh`
3. Verify key in authorized_keys: `cat ~/.ssh/authorized_keys`

### Sync Issues

#### File Transfer Failures
```
rsync: connection unexpectedly closed
```
**Solution**:
1. Check SSH connection: `ssh user@host`
2. Verify paths exist: `mkdir -p destination_path`
3. Check disk space: `df -h`

#### Permission Denied
```
rsync: send_files failed to open
```
**Solution**:
1. Check file permissions: `ls -la`
2. Set correct ownership: `chown -R user:group directory`
3. Add write permissions: `chmod u+w directory`

### WSL-Specific Issues

#### Path Translation
```
No such file or directory
```
**Solution**:
1. Use WSL paths: `/mnt/c/...`
2. Check path exists in WSL: `ls -la /mnt/c/path`
3. Verify Windows permissions

#### Service Management
```
Failed to restart ssh.service
```
**Solution**:
1. Use sudo: `sudo service ssh restart`
2. Check service status: `service ssh status`
3. Verify WSL SSH installation

## Test Environment Issues

### Test Mode

#### Simulation Failures
```
Test mode: Failed to simulate sync
```
**Solution**:
1. Check test directory permissions
2. Verify test configuration
3. Clean test environment: `./test_cleanup.sh`

#### Directory Creation
```
mkdir: cannot create directory
```
**Solution**:
1. Check parent directory exists
2. Verify write permissions
3. Clean old test directories

### Recovery Testing

#### Service Control
```
Failed to stop ssh.service
```
**Solution**:
1. Use correct service name
2. Check sudo privileges
3. Verify service installed

#### File Verification
```
diff: No such file or directory
```
**Solution**:
1. Check file creation
2. Verify sync completed
3. Check path translation

## Performance Issues

### Slow Operations

#### Sync Delays
```
rsync: timeout after XX seconds
```
**Solution**:
1. Check network connection
2. Reduce file size/count
3. Adjust timeout settings

#### Test Execution
```
Test suite took too long
```
**Solution**:
1. Clean test environment
2. Reduce test data size
3. Optimize test operations

## Debug Tools

### Logging

#### Enable Debug Logs
```bash
export DEBUG=1
./script.sh
```

#### View Logs
```bash
tail -f /var/log/syslog
journalctl -u ssh
```

### Network Tools

#### Check Connectivity
```bash
ping host
nc -zv host 22
ssh -vv user@host
```

#### Monitor Transfer
```bash
iotop
nethogs
```

## Best Practices

### Prevention

1. Regular cleanup
2. Permission checks
3. Path verification
4. Service monitoring
5. Log review

### Maintenance

1. Update scripts
2. Clean test data
3. Verify configurations
4. Check dependencies
5. Monitor resources

## Getting Help

### Resources
1. Documentation
2. Issue tracker
3. Log files
4. Test results
5. System status

### Support
1. File issues
2. Include logs
3. Describe steps
4. Show configurations
5. List environment
