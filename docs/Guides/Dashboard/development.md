# SSH Dashboard Development Guide

This guide explains how to develop and extend the SSH Dashboard web interface.

## Development Environment

### Prerequisites
- Node.js 14.x or higher
- npm 6.x or higher
- Git

### Setup

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd ssh_dashboard_monitor
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Configure Environment**
   ```bash
   cp .envrc.example .envrc
   direnv allow
   ```

## Project Structure

```
lib/web/
├── api/              # Backend API
│   └── server.js     # Express server
├── static/           # Static assets
│   ├── css/         # Stylesheets
│   │   └── main.css
│   └── js/          # JavaScript
│       ├── main.js
│       ├── api.js
│       └── charts.js
└── templates/        # HTML templates
    └── index.html
```

## Frontend Development

### JavaScript Architecture

1. **Main Application (`main.js`)**
   - Dashboard initialization
   - Event handling
   - UI updates
   - Page management

2. **API Client (`api.js`)**
   - RESTful API client
   - Request handling
   - Response processing
   - Error management

3. **Charts (`charts.js`)**
   - Chart.js integration
   - Data visualization
   - Real-time updates
   - Chart configurations

### CSS Structure

1. **Variables**
   ```css
   :root {
       --primary-color: #2c3e50;
       --secondary-color: #3498db;
       /* ... */
   }
   ```

2. **Components**
   ```css
   /* Card component */
   .card {
       background-color: white;
       border-radius: 8px;
       /* ... */
   }
   ```

### HTML Templates

1. **Main Template**
   ```html
   <!DOCTYPE html>
   <html>
     <head>
       <!-- Meta tags -->
       <!-- Stylesheets -->
     </head>
     <body>
       <!-- Content -->
     </body>
   </html>
   ```

## Backend Development

### API Server (`server.js`)

1. **Middleware**
   ```javascript
   app.use(cors());
   app.use(express.json());
   app.use(auth);
   ```

2. **Route Handlers**
   ```javascript
   app.get('/api/status', async (req, res) => {
       try {
           // Handler logic
       } catch (error) {
           // Error handling
       }
   });
   ```

### Service Integration

1. **Execute Commands**
   ```javascript
   function executeCommand(command) {
       return new Promise((resolve, reject) => {
           exec(command, (error, stdout, stderr) => {
               if (error) reject(error);
               else resolve(stdout.trim());
           });
       });
   }
   ```

2. **Parse Results**
   ```javascript
   function parseServiceStatus(output) {
       try {
           return JSON.parse(output);
       } catch (error) {
           throw new Error('Invalid service output');
       }
   }
   ```

## Testing

### Frontend Tests

1. **Setup Jest**
   ```javascript
   // jest.config.js
   module.exports = {
       testEnvironment: 'jsdom',
       setupFilesAfterEnv: ['./jest.setup.js']
   };
   ```

2. **Component Tests**
   ```javascript
   describe('Dashboard', () => {
       test('renders status indicators', () => {
           // Test logic
       });
   });
   ```

### API Tests

1. **Setup Supertest**
   ```javascript
   const request = require('supertest');
   const app = require('../server');
   ```

2. **Endpoint Tests**
   ```javascript
   describe('GET /api/status', () => {
       it('returns system status', async () => {
           const response = await request(app)
               .get('/api/status')
               .expect(200);
           // Assertions
       });
   });
   ```

## Building for Production

1. **Optimize Assets**
   ```bash
   # Minify JavaScript
   npm run build:js
   
   # Compile CSS
   npm run build:css
   ```

2. **Environment Configuration**
   ```bash
   # Set production variables
   export NODE_ENV=production
   export API_URL=https://api.example.com
   ```

## Adding New Features

### 1. Frontend Components

1. **Create Component**
   ```javascript
   class NewFeature {
       constructor() {
           this.initialize();
       }
       
       initialize() {
           // Setup code
       }
   }
   ```

2. **Add Styles**
   ```css
   .new-feature {
       /* Component styles */
   }
   ```

### 2. API Endpoints

1. **Add Route**
   ```javascript
   app.get('/api/new-feature', async (req, res) => {
       try {
           const data = await getFeatureData();
           res.json(data);
       } catch (error) {
           res.status(500).json({ error: error.message });
       }
   });
   ```

2. **Add Service Integration**
   ```javascript
   async function getFeatureData() {
       const result = await executeCommand('...');
       return parseResult(result);
   }
   ```

## Best Practices

1. **Code Quality**
   - Use ESLint
   - Follow style guide
   - Write tests
   - Document code

2. **Performance**
   - Optimize assets
   - Use caching
   - Minimize requests
   - Lazy load components

3. **Security**
   - Validate input
   - Sanitize output
   - Use CSRF protection
   - Implement rate limiting

## Related Documentation

- [Overview](overview.md)
- [Installation Guide](installation.md)
- [Configuration Guide](configuration.md)
- [API Reference](api_reference.md)
