// Charts configuration and initialization for SSH Dashboard

// Initialize charts when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    initializeResourceChart();
});

// Resource usage chart
function initializeResourceChart() {
    const ctx = document.getElementById('resource-chart').getContext('2d');
    
    const resourceChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [], // Will be populated with timestamps
            datasets: [
                {
                    label: 'CPU Usage',
                    borderColor: '#2ecc71',
                    data: [],
                    fill: false
                },
                {
                    label: 'Memory Usage',
                    borderColor: '#3498db',
                    data: [],
                    fill: false
                },
                {
                    label: 'Disk Usage',
                    borderColor: '#e74c3c',
                    data: [],
                    fill: false
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                x: {
                    display: true,
                    title: {
                        display: true,
                        text: 'Time'
                    }
                },
                y: {
                    display: true,
                    title: {
                        display: true,
                        text: 'Usage %'
                    },
                    suggestedMin: 0,
                    suggestedMax: 100
                }
            },
            plugins: {
                legend: {
                    position: 'top'
                },
                tooltip: {
                    mode: 'index',
                    intersect: false
                }
            }
        }
    });
    
    // Update chart data periodically
    updateResourceChart(resourceChart);
    setInterval(() => updateResourceChart(resourceChart), 30000);
}

// Update resource chart data
async function updateResourceChart(chart) {
    try {
        const response = await fetch('/api/monitoring/resources');
        const data = await response.json();
        
        // Update timestamps
        chart.data.labels = data.timestamps;
        
        // Update datasets
        chart.data.datasets[0].data = data.cpu;
        chart.data.datasets[1].data = data.memory;
        chart.data.datasets[2].data = data.disk;
        
        chart.update();
    } catch (error) {
        console.error('Failed to update resource chart:', error);
    }
}

// Create service health chart
function createServiceHealthChart(containerId, data) {
    const ctx = document.getElementById(containerId).getContext('2d');
    
    return new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Healthy', 'Warning', 'Error'],
            datasets: [{
                data: [data.healthy, data.warning, data.error],
                backgroundColor: [
                    '#2ecc71', // Green
                    '#f1c40f', // Yellow
                    '#e74c3c'  // Red
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });
}

// Create network traffic chart
function createNetworkChart(containerId, data) {
    const ctx = document.getElementById(containerId).getContext('2d');
    
    return new Chart(ctx, {
        type: 'line',
        data: {
            labels: data.timestamps,
            datasets: [
                {
                    label: 'Incoming',
                    borderColor: '#2ecc71',
                    data: data.incoming,
                    fill: false
                },
                {
                    label: 'Outgoing',
                    borderColor: '#e74c3c',
                    data: data.outgoing,
                    fill: false
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                x: {
                    display: true,
                    title: {
                        display: true,
                        text: 'Time'
                    }
                },
                y: {
                    display: true,
                    title: {
                        display: true,
                        text: 'Traffic (MB/s)'
                    }
                }
            }
        }
    });
}

// Export chart functions
export {
    initializeResourceChart,
    createServiceHealthChart,
    createNetworkChart
};
