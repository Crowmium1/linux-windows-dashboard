// Main JavaScript file for SSH Dashboard

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    initializeDashboard();
    updateDashboard();
    setInterval(updateDashboard, 30000); // Update every 30 seconds
});

// Dashboard initialization
function initializeDashboard() {
    // Initialize navigation
    initializeNavigation();
    
    // Initialize notifications
    initializeNotifications();
    
    // Initialize quick actions
    initializeQuickActions();
    
    // Initialize charts
    initializeCharts();
}

// Navigation handling
function initializeNavigation() {
    const navLinks = document.querySelectorAll('.nav-links li');
    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            // Remove active class from all links
            navLinks.forEach(l => l.classList.remove('active'));
            
            // Add active class to clicked link
            link.classList.add('active');
            
            // Update page content
            const page = link.getAttribute('data-page');
            updatePageContent(page);
            
            // Update page title
            document.getElementById('page-title').textContent = 
                page.charAt(0).toUpperCase() + page.slice(1);
        });
    });
}

// Update page content
async function updatePageContent(page) {
    const pageElement = document.getElementById(page);
    if (!pageElement) return;
    
    // Hide all pages
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    
    // Show selected page
    pageElement.classList.add('active');
    
    // Load page content if needed
    if (pageElement.children.length === 0) {
        try {
            const response = await fetch(`/api/pages/${page}`);
            const content = await response.text();
            pageElement.innerHTML = content;
        } catch (error) {
            console.error(`Failed to load ${page} content:`, error);
            pageElement.innerHTML = '<div class="error">Failed to load content</div>';
        }
    }
}

// Initialize notifications
function initializeNotifications() {
    const notificationIcon = document.querySelector('.notifications');
    const modal = document.getElementById('notification-modal');
    const closeBtn = modal.querySelector('.close-btn');
    
    notificationIcon.addEventListener('click', async () => {
        modal.style.display = 'block';
        await loadNotifications();
    });
    
    closeBtn.addEventListener('click', () => {
        modal.style.display = 'none';
    });
    
    window.addEventListener('click', (event) => {
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    });
}

// Load notifications
async function loadNotifications() {
    const notificationsList = document.getElementById('notifications-list');
    try {
        const response = await fetch('/api/notifications');
        const notifications = await response.json();
        
        notificationsList.innerHTML = notifications.map(notification => `
            <div class="notification-item ${notification.type}">
                <i class="fas ${getNotificationIcon(notification.type)}"></i>
                <div class="notification-content">
                    <div class="notification-title">${notification.title}</div>
                    <div class="notification-message">${notification.message}</div>
                    <div class="notification-time">${formatTime(notification.timestamp)}</div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Failed to load notifications:', error);
        notificationsList.innerHTML = '<div class="error">Failed to load notifications</div>';
    }
}

// Initialize quick actions
function initializeQuickActions() {
    const actionButtons = document.querySelectorAll('.action-btn');
    actionButtons.forEach(button => {
        button.addEventListener('click', async () => {
            const action = button.getAttribute('data-action');
            try {
                const response = await fetch(`/api/actions/${action}`, {
                    method: 'POST'
                });
                const result = await response.json();
                if (result.success) {
                    updateDashboard();
                }
            } catch (error) {
                console.error(`Failed to execute action ${action}:`, error);
            }
        });
    });
}

// Update dashboard data
async function updateDashboard() {
    try {
        // Update system status
        const statusResponse = await fetch('/api/status');
        const status = await statusResponse.json();
        
        updateSystemStatus(status);
        updateResourceUsage(status.resources);
        updateRecentEvents(status.events);
        
        // Update notification count
        const notificationCount = document.querySelector('.notification-count');
        notificationCount.textContent = status.notifications.unread;
        
        // Update status indicator
        const statusDot = document.querySelector('.status-dot');
        statusDot.style.backgroundColor = getStatusColor(status.overall);
        
    } catch (error) {
        console.error('Failed to update dashboard:', error);
    }
}

// Update system status indicators
function updateSystemStatus(status) {
    document.getElementById('services-status').textContent = status.services;
    document.getElementById('ha-status').textContent = status.ha;
    document.getElementById('security-status').textContent = status.security;
    document.getElementById('monitoring-status').textContent = status.monitoring;
}

// Update recent events
function updateRecentEvents(events) {
    const eventsList = document.getElementById('events-list');
    eventsList.innerHTML = events.map(event => `
        <div class="event-item ${event.type}">
            <i class="fas ${getEventIcon(event.type)}"></i>
            <div class="event-content">
                <div class="event-message">${event.message}</div>
                <div class="event-time">${formatTime(event.timestamp)}</div>
            </div>
        </div>
    `).join('');
}

// Utility functions
function getStatusColor(status) {
    const colors = {
        healthy: 'var(--success-color)',
        warning: 'var(--warning-color)',
        error: 'var(--error-color)'
    };
    return colors[status] || colors.warning;
}

function getNotificationIcon(type) {
    const icons = {
        info: 'fa-info-circle',
        success: 'fa-check-circle',
        warning: 'fa-exclamation-triangle',
        error: 'fa-times-circle'
    };
    return icons[type] || icons.info;
}

function getEventIcon(type) {
    const icons = {
        info: 'fa-info-circle',
        success: 'fa-check-circle',
        warning: 'fa-exclamation-triangle',
        error: 'fa-times-circle'
    };
    return icons[type] || icons.info;
}

function formatTime(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleString();
}
