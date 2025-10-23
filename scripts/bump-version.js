#!/usr/bin/env node
/**
 * Automatic Version Bumping Script
 * Increments patch version on every build/start
 * Usage: node scripts/bump-version.js [patch|minor|major]
 */

const fs = require('fs');
const path = require('path');

const PACKAGE_JSON_PATH = path.join(__dirname, '..', 'package.json');
const VERSION_LOG_PATH = path.join(__dirname, '..', 'VERSION_HISTORY.txt');

function bumpVersion(type = 'patch') {
  try {
    // Read package.json
    const packageJson = JSON.parse(fs.readFileSync(PACKAGE_JSON_PATH, 'utf8'));
    const currentVersion = packageJson.version;

    // Parse version
    const [major, minor, patch] = currentVersion.split('.').map(Number);

    // Bump version based on type
    let newVersion;
    switch (type) {
      case 'major':
        newVersion = `${major + 1}.0.0`;
        break;
      case 'minor':
        newVersion = `${major}.${minor + 1}.0`;
        break;
      case 'patch':
      default:
        newVersion = `${major}.${minor}.${patch + 1}`;
        break;
    }

    // Update package.json
    packageJson.version = newVersion;
    fs.writeFileSync(
      PACKAGE_JSON_PATH,
      JSON.stringify(packageJson, null, 2) + '\n',
      'utf8'
    );

    // Log version change
    const timestamp = new Date().toISOString();
    const logEntry = `${timestamp} | ${currentVersion} → ${newVersion} (${type})\n`;
    fs.appendFileSync(VERSION_LOG_PATH, logEntry, 'utf8');

    console.log(`✅ Version bumped: ${currentVersion} → ${newVersion}`);
    console.log(`📝 Logged to: VERSION_HISTORY.txt`);

    return newVersion;
  } catch (error) {
    console.error('❌ Error bumping version:', error.message);
    process.exit(1);
  }
}

// Get bump type from command line argument
const bumpType = process.argv[2] || 'patch';

// Validate bump type
if (!['patch', 'minor', 'major'].includes(bumpType)) {
  console.error('❌ Invalid bump type. Use: patch, minor, or major');
  process.exit(1);
}

// Bump version
bumpVersion(bumpType);
