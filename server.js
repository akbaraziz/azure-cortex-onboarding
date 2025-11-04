const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');
const { Mutex } = require('async-mutex');
const { z } = require('zod');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// JWT Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRY = process.env.JWT_EXPIRY || '24h';
const AUTH_ENABLED = process.env.AUTH_ENABLED === 'true';

// Load version from package.json
const packageJson = require('./package.json');
const APP_VERSION = packageJson.version;
const APP_NAME = packageJson.name;

// Zod validation schemas
const OnboardingConfigSchema = z.object({
  subscriptionId: z.string().uuid('Invalid subscription ID format'),
  tenantId: z.string().uuid('Invalid tenant ID format'),
  appName: z.string().regex(/^[a-zA-Z0-9-]+$/, 'App name must contain only alphanumeric characters and hyphens').min(3).max(100),
  cortexApiUrl: z.string().url('Invalid Cortex API URL'),
  cortexAccessKey: z.string().min(20, 'Access key too short').max(200, 'Access key too long'),
  cortexSecretKey: z.string().min(20, 'Secret key too short').max(200, 'Secret key too long'),
  azureAccountName: z.string().regex(/^[a-zA-Z0-9-]+$/, 'Azure account name must contain only alphanumeric characters and hyphens').min(3).max(100),
  environment: z.string().regex(/^[a-z]+$/, 'Environment must contain only lowercase letters').max(20).optional(),
  azureRegion: z.string().regex(/^[a-z0-9]+$/, 'Azure region must contain only lowercase alphanumeric characters').max(50).optional(),
  logRetentionDays: z.number().int().min(7, 'Log retention must be at least 7 days').max(730, 'Log retention cannot exceed 730 days').optional(),
  features: z.object({
    cloudVisibility: z.boolean().optional(),
    agentlessScanning: z.boolean().optional(),
    serverlessScanning: z.boolean().optional(),
    agentBasedProtection: z.boolean().optional(),
    remediation: z.boolean().optional()
  }).optional(),
  monitorFlowLogs: z.boolean().optional(),
  enableFlowLogs: z.boolean().optional(),
  createCustomRole: z.boolean().optional()
});

// JWT Authentication Middleware
function authenticateToken(req, res, next) {
  // Skip authentication if not enabled
  if (!AUTH_ENABLED) {
    return next();
  }

  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
}

// CORS Configuration
const NODE_ENV = process.env.NODE_ENV || 'development';
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map(origin => origin.trim())
  : ['http://localhost:3001', 'http://127.0.0.1:3001'];

const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);

    // In development mode, allow all localhost and 127.0.0.1 origins with any port
    if (NODE_ENV === 'development') {
      const localhostRegex = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;
      if (localhostRegex.test(origin)) {
        console.log(`[CORS] ✓ Development mode: Allowed origin ${origin}`);
        return callback(null, true);
      }
    }

    // Check against explicitly allowed origins
    if (allowedOrigins.indexOf(origin) !== -1) {
      console.log(`[CORS] ✓ Allowed origin ${origin}`);
      callback(null, true);
    } else {
      console.warn(`[CORS] ✗ Blocked origin ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  optionsSuccessStatus: 200
};

// Rate Limiting Configuration
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

// Stricter rate limit for authentication endpoint
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 login attempts per windowMs
  message: 'Too many login attempts, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://unpkg.com"],
      scriptSrcElem: ["'self'", "'unsafe-inline'", "https://unpkg.com"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      connectSrc: ["'self'", "ws:", "wss:"],
      imgSrc: ["'self'", "data:", "https:"],
      fontSrc: ["'self'", "data:"],
    }
  }
})); // Security headers
app.use(cors(corsOptions));
app.use(bodyParser.json());
app.use('/api/', apiLimiter); // Apply rate limiting to all API endpoints
app.use(express.static(path.join(__dirname, 'public')));

// Store active deployments and their mutexes for race condition protection
const activeDeployments = new Map();
const deploymentLocks = new Map();

// WebSocket server
const wss = new WebSocket.Server({ noServer: true });

wss.on('connection', (ws, request) => {
  const deploymentId = request.url.split('/').pop();

  // Validate deployment ID is a valid UUID (prevent path traversal attacks)
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(deploymentId)) {
    console.error(`Invalid WebSocket deployment ID: ${deploymentId}`);
    ws.close(1008, 'Invalid deployment ID format');
    return;
  }

  console.log(`WebSocket connected for deployment: ${deploymentId}`);
  ws.deploymentId = deploymentId;

  ws.on('close', () => {
    console.log(`WebSocket closed for deployment: ${deploymentId}`);
  });
});

// Broadcast to specific deployment with error handling
function sendToDeployment(deploymentId, data) {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN && client.deploymentId === deploymentId) {
      try {
        client.send(JSON.stringify(data));
      } catch (error) {
        console.error(`WebSocket send error for deployment ${deploymentId}:`, error.message);
        // Client may have disconnected, continue with other clients
      }
    }
  });
}

// Helper function to safely create directories with race condition handling
function createDirectorySafe(dirPath) {
  try {
    fs.mkdirSync(dirPath, { recursive: true });
  } catch (error) {
    // Ignore EEXIST errors (directory already exists from concurrent operation)
    if (error.code !== 'EEXIST') {
      throw error;
    }
  }
}

// Helper function to copy files with retry logic for race conditions
async function copyFileWithRetry(src, dest, maxRetries = 3) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      fs.copyFileSync(src, dest);
      return;
    } catch (error) {
      if (attempt === maxRetries - 1) {
        throw error; // Re-throw on final attempt
      }
      // Wait with exponential backoff
      await new Promise(resolve => setTimeout(resolve, 100 * (attempt + 1)));
    }
  }
}

// Helper function to sanitize sensitive data from logs
function sanitizeForLogging(obj) {
  if (!obj || typeof obj !== 'object') {
    return obj;
  }

  const sensitiveKeys = [
    'password', 'secret', 'token', 'key', 'auth', 'credential',
    'cortexSecretKey', 'cortexAccessKey', 'subscriptionId', 'tenantId'
  ];

  const sanitized = Array.isArray(obj) ? [] : {};

  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    const isSensitive = sensitiveKeys.some(sensitive => lowerKey.includes(sensitive.toLowerCase()));

    if (isSensitive && typeof value === 'string') {
      // Mask sensitive data, show only first and last 4 characters
      if (value.length > 8) {
        sanitized[key] = `${value.substring(0, 4)}...${value.substring(value.length - 4)}`;
      } else {
        sanitized[key] = '***REDACTED***';
      }
    } else if (typeof value === 'object' && value !== null) {
      sanitized[key] = sanitizeForLogging(value);
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
}

// Helper function to execute shell commands
function executeCommand(command, args, workDir, deploymentId) {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, {
      cwd: workDir,
      shell: true
    });

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data) => {
      const output = data.toString();
      stdout += output;
      sendToDeployment(deploymentId, {
        type: 'output',
        data: output
      });
    });

    proc.stderr.on('data', (data) => {
      const output = data.toString();
      stderr += output;
      sendToDeployment(deploymentId, {
        type: 'output',
        data: output
      });
    });

    proc.on('close', (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        reject(new Error(`Command failed with code ${code}: ${stderr}`));
      }
    });

    proc.on('error', (error) => {
      reject(error);
    });
  });
}

// Create terraform.tfvars file
function createTfvars(config, workDir) {
  const tfvarsContent = `# Azure Configuration
subscription_id = "${config.subscriptionId}"
tenant_id       = "${config.tenantId}"
app_name        = "${config.appName}"

# Cortex Cloud Configuration
cortex_api_url     = "${config.cortexApiUrl}"
cortex_access_key  = "${config.cortexAccessKey}"
cortex_secret_key  = "${config.cortexSecretKey}"
azure_account_name = "${config.azureAccountName}"

# Cortex Cloud Features
enable_cloud_visibility        = ${config.features?.cloudVisibility ?? true}
enable_agentless_scanning      = ${config.features?.agentlessScanning ?? true}
enable_serverless_scanning     = ${config.features?.serverlessScanning ?? true}
enable_agent_based_protection  = ${config.features?.agentBasedProtection ?? false}
enable_remediation             = ${config.features?.remediation ?? false}

# Azure Infrastructure Options
# These are automatically enabled for security best practices
monitor_flow_logs  = ${config.monitorFlowLogs ?? true}
enable_audit_logs  = true
enable_azure_ad    = true

# Optional Configuration
environment        = "${config.environment}"
azure_region       = "${config.azureRegion}"
log_retention_days = ${config.logRetentionDays}

# Infrastructure Configuration
enable_flow_logs    = ${config.enableFlowLogs ?? true}
create_custom_role  = ${config.createCustomRole ?? true}
`;

  fs.writeFileSync(path.join(workDir, 'terraform.tfvars'), tfvarsContent);
}

// Helper function to convert features object to Cortex API format
function convertFeaturesToApiFormat(features) {
  const featureMap = {
    cloudVisibility: 'Cloud Visibility Compliance and Governance',
    agentlessScanning: 'Agentless Scanning',
    serverlessScanning: 'Serverless Function Scanning',
    agentBasedProtection: 'Agent-Based Workload Protection',
    remediation: 'Remediation'
  };

  return Object.entries(features || {})
    .filter(([key, enabled]) => enabled && featureMap[key])
    .map(([key]) => ({
      name: featureMap[key],
      state: 'enabled'
    }));
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Version endpoint
app.get('/api/version', (req, res) => {
  res.json({
    name: APP_NAME,
    version: APP_VERSION,
    node: process.version,
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Authentication endpoint - Generate JWT token
app.post('/api/auth/token', authLimiter, (req, res) => {
  const { username, password } = req.body;

  // Simple authentication check (in production, verify against secure storage)
  const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
  const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'changeme';

  if (username !== ADMIN_USERNAME || password !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // Generate JWT token
  const token = jwt.sign(
    { username, role: 'admin' },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRY }
  );

  res.json({
    token,
    expiresIn: JWT_EXPIRY,
    message: 'Authentication successful'
  });
});

// Check prerequisites endpoint
app.get('/api/check-prerequisites', async (req, res) => {
  try {
    const checks = {
      azureCli: false,
      terraform: false,
      azureLogin: false
    };

    // Check Azure CLI
    try {
      await executeCommand('az', ['--version'], '.', 'check');
      checks.azureCli = true;
    } catch (error) {
      console.log('Azure CLI not found');
    }

    // Check Terraform
    try {
      await executeCommand('terraform', ['--version'], '.', 'check');
      checks.terraform = true;
    } catch (error) {
      console.log('Terraform not found');
    }

    // Check Azure login
    try {
      await executeCommand('az', ['account', 'show'], '.', 'check');
      checks.azureLogin = true;
    } catch (error) {
      console.log('Not logged into Azure');
    }

    res.json(checks);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start onboarding process (protected endpoint)
app.post('/api/start-onboarding', authenticateToken, async (req, res) => {
  const deploymentId = uuidv4();

  try {
    // Validate input using Zod schema
    const config = OnboardingConfigSchema.parse(req.body);

    // Create a working directory for this deployment (safe from race conditions)
    const workDir = path.join(__dirname, 'deployments', deploymentId);
    createDirectorySafe(workDir);

    // Copy Terraform files to work directory
    const terraformFiles = [
      'main.tf',
      'provider.tf',
      'variables.tf',
      'azure-roles.tf',
      'azure-audit-logs.tf',
      'outputs.tf'
    ];

    const sourceDir = __dirname; // Files are in the same directory as server.js

    // Copy files with retry logic for race conditions
    for (const file of terraformFiles) {
      const sourcePath = path.join(sourceDir, file);
      if (fs.existsSync(sourcePath)) {
        await copyFileWithRetry(sourcePath, path.join(workDir, file));
      } else {
        console.warn(`Warning: Terraform file not found: ${sourcePath}`);
      }
    }

    // Create mutex for this deployment
    deploymentLocks.set(deploymentId, new Mutex());

    // Store deployment info (no lock needed here as it's a new deployment)
    activeDeployments.set(deploymentId, {
      config,
      workDir,
      status: 'initializing',
      startTime: new Date()
    });

    res.json({
      deploymentId,
      message: 'Deployment started',
      wsUrl: `/ws/${deploymentId}`
    });

    // Start the deployment process asynchronously with error handling
    runDeployment(deploymentId, config, workDir).catch(error => {
      console.error(`Unhandled error in deployment ${deploymentId}:`, error.message); // Only log error message, not full object
      const deployment = activeDeployments.get(deploymentId);
      if (deployment) {
        deployment.status = 'failed';
        deployment.error = error.message || 'Internal server error';
        deployment.endTime = new Date();
      }
    });

  } catch (error) {
    // Sanitize error before logging
    console.error('Error starting deployment:', error.message);

    // Handle Zod validation errors with specific 400 response
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Invalid input data',
        details: error.errors.map(e => ({
          field: e.path.join('.'),
          message: e.message
        }))
      });
    }

    res.status(500).json({ error: error.message });
  }
});

// Get deployment status with mutex protection
app.get('/api/deployment/:id', async (req, res) => {
  const deploymentId = req.params.id;

  // Validate deployment ID is a valid UUID (prevent path traversal attacks)
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(deploymentId)) {
    return res.status(400).json({ error: 'Invalid deployment ID format' });
  }

  // Get or create mutex for this deployment
  if (!deploymentLocks.has(deploymentId)) {
    deploymentLocks.set(deploymentId, new Mutex());
  }
  const mutex = deploymentLocks.get(deploymentId);

  // Acquire lock before reading deployment state
  const release = await mutex.acquire();
  try {
    const deployment = activeDeployments.get(deploymentId);

    if (!deployment) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    res.json({
      deploymentId: req.params.id,
      status: deployment.status,
      startTime: deployment.startTime,
      endTime: deployment.endTime,
      output: deployment.output,
      error: deployment.error
    });
  } finally {
    release();
  }
});

// Main deployment function
async function runDeployment(deploymentId, config, workDir) {
  const deployment = activeDeployments.get(deploymentId);
  
  try {
    // Step 1: Create tfvars
    sendToDeployment(deploymentId, {
      type: 'step',
      step: 'Creating configuration files...'
    });
    
    createTfvars(config, workDir);
    deployment.status = 'configuring';

    // Step 2: Set Azure subscription
    sendToDeployment(deploymentId, {
      type: 'step',
      step: 'Setting Azure subscription...'
    });
    
    await executeCommand('az', ['account', 'set', '--subscription', config.subscriptionId], workDir, deploymentId);
    deployment.status = 'azure_configured';

    // Step 3: Initialize Terraform
    sendToDeployment(deploymentId, {
      type: 'step',
      step: 'Initializing Terraform...'
    });
    
    await executeCommand('terraform', ['init'], workDir, deploymentId);
    deployment.status = 'terraform_initialized';

    // Step 4: Validate Terraform
    sendToDeployment(deploymentId, {
      type: 'step',
      step: 'Validating Terraform configuration...'
    });
    
    await executeCommand('terraform', ['validate'], workDir, deploymentId);
    deployment.status = 'terraform_validated';

    // Step 5: Plan Terraform
    sendToDeployment(deploymentId, {
      type: 'step',
      step: 'Planning Terraform deployment...'
    });
    
    await executeCommand('terraform', ['plan', '-out=tfplan'], workDir, deploymentId);
    deployment.status = 'terraform_planned';

    // Step 6: Apply Terraform
    sendToDeployment(deploymentId, {
      type: 'step',
      step: 'Applying Terraform configuration...'
    });
    
    await executeCommand('terraform', ['apply', '-auto-approve', 'tfplan'], workDir, deploymentId);
    deployment.status = 'terraform_applied';

    // Step 7: Get outputs
    sendToDeployment(deploymentId, {
      type: 'step',
      step: 'Retrieving deployment outputs...'
    });
    
    const outputResult = await executeCommand('terraform', ['output', '-json'], workDir, deploymentId);
    const outputs = JSON.parse(outputResult.stdout);
    
    deployment.status = 'completed';
    deployment.endTime = new Date();
    deployment.output = outputs;

    sendToDeployment(deploymentId, {
      type: 'complete',
      outputs: outputs
    });

  } catch (error) {
    deployment.status = 'failed';
    deployment.endTime = new Date();
    deployment.error = error.message;

    sendToDeployment(deploymentId, {
      type: 'error',
      error: error.message
    });
  }
}

// Upgrade HTTP server to handle WebSocket
const server = app.listen(PORT, () => {
  console.log('');
  console.log('='.repeat(60));
  console.log(`🚀 ${APP_NAME} v${APP_VERSION}`);
  console.log('='.repeat(60));
  console.log(`📡 Server running on: http://localhost:${PORT}`);
  console.log(`🔌 WebSocket server ready`);
  console.log(`📅 Started: ${new Date().toLocaleString()}`);
  console.log('='.repeat(60));
  console.log('');
});

server.on('upgrade', (request, socket, head) => {
  if (request.url.startsWith('/ws/')) {
    wss.handleUpgrade(request, socket, head, (ws) => {
      wss.emit('connection', ws, request);
    });
  }
});

// Cleanup old deployments periodically with mutex protection
setInterval(async () => {
  const now = Date.now();
  const toDelete = [];

  // First pass: identify deployments to delete (no locks needed for read-only check)
  activeDeployments.forEach((deployment, id) => {
    if (deployment.endTime && now - deployment.endTime.getTime() > 3600000) { // 1 hour
      toDelete.push(id);
    }
  });

  // Second pass: delete with mutex protection
  for (const id of toDelete) {
    if (deploymentLocks.has(id)) {
      const mutex = deploymentLocks.get(id);
      const release = await mutex.acquire();
      try {
        activeDeployments.delete(id);
        deploymentLocks.delete(id);
        console.log(`Cleaned up old deployment: ${id}`);
        // Optionally clean up work directory
        // const workDir = path.join(__dirname, 'deployments', id);
        // if (fs.existsSync(workDir)) {
        //   fs.rmSync(workDir, { recursive: true, force: true });
        // }
      } finally {
        release();
      }
    } else {
      // No lock exists, safe to delete directly
      activeDeployments.delete(id);
    }
  }
}, 300000); // Every 5 minutes
