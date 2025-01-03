// API client for SSH Dashboard

class DashboardAPI {
    constructor(baseURL = '') {
        this.baseURL = baseURL;
    }
    
    // Helper method for making API requests
    async request(endpoint, options = {}) {
        try {
            const response = await fetch(`${this.baseURL}/api${endpoint}`, {
                ...options,
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                }
            });
            
            if (!response.ok) {
                throw new Error(`API request failed: ${response.statusText}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error('API request error:', error);
            throw error;
        }
    }
    
    // System Status
    async getSystemStatus() {
        return this.request('/status');
    }
    
    async getServiceStatus(service) {
        return this.request(`/services/${service}/status`);
    }
    
    // Service Management
    async startService(service) {
        return this.request(`/services/${service}/start`, {
            method: 'POST'
        });
    }
    
    async stopService(service) {
        return this.request(`/services/${service}/stop`, {
            method: 'POST'
        });
    }
    
    async restartService(service) {
        return this.request(`/services/${service}/restart`, {
            method: 'POST'
        });
    }
    
    // Monitoring
    async getResourceUsage() {
        return this.request('/monitoring/resources');
    }
    
    async getServiceMetrics(service) {
        return this.request(`/monitoring/services/${service}/metrics`);
    }
    
    async getAlerts() {
        return this.request('/monitoring/alerts');
    }
    
    // Security
    async getSecurityStatus() {
        return this.request('/security/status');
    }
    
    async getSSHKeys() {
        return this.request('/security/ssh-keys');
    }
    
    async addSSHKey(key) {
        return this.request('/security/ssh-keys', {
            method: 'POST',
            body: JSON.stringify(key)
        });
    }
    
    async removeSSHKey(keyId) {
        return this.request(`/security/ssh-keys/${keyId}`, {
            method: 'DELETE'
        });
    }
    
    // Logs
    async getLogs(options = {}) {
        const params = new URLSearchParams(options);
        return this.request(`/logs?${params}`);
    }
    
    async getServiceLogs(service, options = {}) {
        const params = new URLSearchParams(options);
        return this.request(`/services/${service}/logs?${params}`);
    }
    
    // Events
    async getEvents(options = {}) {
        const params = new URLSearchParams(options);
        return this.request(`/events?${params}`);
    }
    
    // Notifications
    async getNotifications() {
        return this.request('/notifications');
    }
    
    async markNotificationRead(notificationId) {
        return this.request(`/notifications/${notificationId}/read`, {
            method: 'POST'
        });
    }
    
    // Settings
    async getSettings() {
        return this.request('/settings');
    }
    
    async updateSettings(settings) {
        return this.request('/settings', {
            method: 'PUT',
            body: JSON.stringify(settings)
        });
    }
    
    // High Availability
    async getHAStatus() {
        return this.request('/ha/status');
    }
    
    async switchHANode(node) {
        return this.request('/ha/switch', {
            method: 'POST',
            body: JSON.stringify({ node })
        });
    }
    
    // Backup
    async createBackup() {
        return this.request('/backup', {
            method: 'POST'
        });
    }
    
    async getBackups() {
        return this.request('/backups');
    }
    
    async restoreBackup(backupId) {
        return this.request(`/backups/${backupId}/restore`, {
            method: 'POST'
        });
    }
}

// Create and export API instance
const api = new DashboardAPI();
export default api;
