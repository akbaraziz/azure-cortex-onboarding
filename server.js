const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3001;

// Load version from package.json
const packageJson = require('./package.json');
const APP_VERSION = packageJson.version;
const APP_NAME = packageJson.name;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

// Store active deployments
const activeDeployments = new Map();

// WebSocket server
const wss = new WebSocket.Server({ noServer: true });

wss.on('connection', (ws, request) => {
  const deploymentId = request.url.split('/').pop();
  console.log(`WebSocket connected for deployment: ${deploymentId}`);
  
  ws.deploymentId = deploymentId;
  
  ws.on('close', () => {
    console.log(`WebSocket closed for deployment: ${deploymentId}`);
  });
});

// Broadcast to specific deployment
function sendToDeployment(deploymentId, data) {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN && client.deploymentId === deploymentId) {
      client.send(JSON.stringify(data));
    }
  });
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

// Start onboarding process
app.post('/api/start-onboarding', async (req, res) => {
  const deploymentId = uuidv4();
  const config = req.body;

  // Create a working directory for this deployment
  const workDir = path.join(__dirname, 'deployments', deploymentId);
  fs.mkdirSync(workDir, { recursive: true });

  // Copy Terraform files to work directory
  const terraformFiles = [
    'variables.tf',
    'azure-roles.tf',
    'azure-audit-logs.tf',
    'outputs.tf'
  ];

  const sourceDir = path.join(__dirname, '..', '..'); // Adjust based on actual location
  
  try {
    terraformFiles.forEach(file => {
      const sourcePath = path.join(sourceDir, file);
      if (fs.existsSync(sourcePath)) {
        fs.copyFileSync(sourcePath, path.join(workDir, file));
      }
    });
  } catch (error) {
    console.error('Error copying Terraform files:', error);
  }

  // Store deployment info
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

  // Start the deployment process asynchronously
  runDeployment(deploymentId, config, workDir);
});

// Get deployment status
app.get('/api/deployment/:id', (req, res) => {
  const deployment = activeDeployments.get(req.params.id);
  
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

// Cleanup old deployments periodically
setInterval(() => {
  const now = Date.now();
  activeDeployments.forEach((deployment, id) => {
    if (deployment.endTime && now - deployment.endTime.getTime() > 3600000) { // 1 hour
      activeDeployments.delete(id);
      // Optionally clean up work directory
    }
  });
}, 300000); // Every 5 minutes
