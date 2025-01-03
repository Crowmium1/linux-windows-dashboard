// Express server for SSH Dashboard API
const express = require('express');
const cors = require('cors');
const path = require('path');
const { exec } = require('child_process');
const yaml = require('js-yaml');
const fs = require('fs');

// Import service manager
const serviceManager = path.join(__dirname, '../../service/service_manager.sh');

const app = express();
app.use(cors());
app.use(express.json());

// Serve static files
app.use('/static', express.static(path.join(__dirname, '../static')));

// Serve templates
app.use('/templates', express.static(path.join(__dirname, '../templates')));

// Load configuration
function loadConfig() {
    try {
        const configPath = path.join(__dirname, '../../../config/service/service.yaml');
        return yaml.load(fs.readFileSync(configPath, 'utf8'));
    } catch (error) {
        console.error('Failed to load configuration:', error);
        return {};
    }
}

// Execute shell command
function executeCommand(command) {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject(error);
            } else {
                resolve(stdout.trim());
            }
        });
    });
}

// API Routes

// System Status
app.get('/api/status', async (req, res) => {
    try {
        const status = await executeCommand(`${serviceManager} status`);
        res.json(JSON.parse(status));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Service Management
app.post('/api/services/:service/:action', async (req, res) => {
    const { service, action } = req.params;
    
    try {
        const result = await executeCommand(`${serviceManager} ${action} ${service}`);
        res.json({ success: true, message: result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Monitoring
app.get('/api/monitoring/resources', async (req, res) => {
    try {
        const resources = await executeCommand('bash /opt/ssh_dashboard/lib/monitoring/monitor_manager.sh resources');
        res.json(JSON.parse(resources));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Security
app.get('/api/security/status', async (req, res) => {
    try {
        const status = await executeCommand('bash /opt/ssh_dashboard/lib/security/security_manager.sh status');
        res.json(JSON.parse(status));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Logs
app.get('/api/logs', async (req, res) => {
    const { service, lines = 100 } = req.query;
    
    try {
        let command = `tail -n ${lines} ${process.env.HA_LOG_DIR}/`;
        if (service) {
            command += `${service}.log`;
        } else {
            command += 'ha.log';
        }
        
        const logs = await executeCommand(command);
        res.json({ logs: logs.split('\n') });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Events
app.get('/api/events', async (req, res) => {
    try {
        const events = await executeCommand('bash /opt/ssh_dashboard/lib/monitoring/monitor_manager.sh events');
        res.json(JSON.parse(events));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// High Availability
app.get('/api/ha/status', async (req, res) => {
    try {
        const status = await executeCommand('bash /opt/ssh_dashboard/lib/ha/failover_manager.sh status');
        res.json(JSON.parse(status));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal server error' });
});

// Start server
const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`SSH Dashboard API server running on port ${port}`);
});
