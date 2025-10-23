# Version Management System

This project uses automatic version bumping on every build and deployment.

---

## Overview

The version is automatically incremented every time you:
- Start the server (`npm start`)
- Run a build (`npm run build`)
- Manually bump version with npm commands

---

## Automatic Version Bumping

### On Every Start/Build

The version automatically increments the **patch** version:
- `1.0.0` → `1.0.1`
- `1.0.1` → `1.0.2`
- etc.

This happens via the `prestart` and `prebuild` hooks in `package.json`.

---

## Manual Version Bumping

### Patch Version (x.x.X)
```bash
npm run version:patch
```
Increments: `1.0.0` → `1.0.1`

Use for: Bug fixes, minor updates

### Minor Version (x.X.0)
```bash
npm run version:minor
```
Increments: `1.0.5` → `1.1.0`

Use for: New features, non-breaking changes

### Major Version (X.0.0)
```bash
npm run version:major
```
Increments: `1.5.2` → `2.0.0`

Use for: Breaking changes, major releases

---

## Version Display

### Server Startup

When the server starts, you'll see:
```
============================================================
🚀 azure-cortex-onboarding-ui v1.0.5
============================================================
📡 Server running on: http://localhost:3001
🔌 WebSocket server ready
📅 Started: 10/23/2025, 12:30:45 PM
============================================================
```

### API Endpoint

Query the version via API:

**Request:**
```bash
curl http://localhost:3001/api/version
```

**Response:**
```json
{
  "name": "azure-cortex-onboarding-ui",
  "version": "1.0.5",
  "node": "v23.6.1",
  "uptime": 123.45,
  "timestamp": "2025-10-23T19:30:45.123Z"
}
```

---

## Version History

All version changes are logged to `VERSION_HISTORY.txt`:

```
2025-10-23T19:25:32.456Z | 1.0.0 → 1.0.1 (patch)
2025-10-23T19:30:45.789Z | 1.0.1 → 1.0.2 (patch)
2025-10-23T20:15:12.345Z | 1.0.2 → 1.1.0 (minor)
```

---

## How It Works

### 1. Package.json Scripts

```json
{
  "scripts": {
    "prestart": "npm run version:bump",
    "start": "node server.js",
    "prebuild": "npm run version:bump",
    "build": "echo 'Build complete - Version updated'",
    "version:bump": "node scripts/bump-version.js"
  }
}
```

- `prestart` runs **before** `npm start`
- `prebuild` runs **before** `npm run build`
- Both trigger `scripts/bump-version.js`

### 2. Bump Version Script

Located at `scripts/bump-version.js`, this script:
1. Reads current version from `package.json`
2. Increments the version based on type (patch/minor/major)
3. Writes the new version back to `package.json`
4. Logs the change to `VERSION_HISTORY.txt`

### 3. Server Integration

The server (`server.js`):
1. Loads version from `package.json` on startup
2. Displays version in console
3. Exposes version via `/api/version` endpoint

---

## Disable Automatic Bumping

If you need to disable automatic version bumping temporarily:

### Option 1: Use Dev Mode
```bash
npm run dev
```
Dev mode bypasses the `prestart` hook.

### Option 2: Edit package.json
Remove the `prestart` and `prebuild` hooks temporarily:

```json
{
  "scripts": {
    "start": "node server.js",
    "build": "echo 'Build complete'"
  }
}
```

---

## Best Practices

### Semantic Versioning

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): New features, backwards compatible
- **PATCH** (0.0.X): Bug fixes, backwards compatible

### When to Bump Manually

Use manual version bumping for:
- **Minor releases**: After adding significant features
- **Major releases**: After breaking changes or major refactors

### Let Auto-Bump Handle

Let automatic bumping handle:
- Daily development iterations
- Small fixes and tweaks
- Testing and staging deployments

---

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Bump version
        run: npm run version:patch

      - name: Build
        run: npm run build

      - name: Commit version bump
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add package.json VERSION_HISTORY.txt
          git commit -m "chore: bump version [skip ci]"
          git push
```

---

## Files Modified

- `package.json` - Version number and scripts
- `server.js` - Version display on startup
- `scripts/bump-version.js` - Version bumping logic
- `VERSION_HISTORY.txt` - Version change log (auto-generated)

---

## Troubleshooting

### Version not updating on start

**Problem:** Version stays the same after `npm start`

**Solution:**
1. Check that `prestart` hook exists in `package.json`
2. Verify `scripts/bump-version.js` is executable
3. Check for errors in the version bump script

### Version history file not created

**Problem:** `VERSION_HISTORY.txt` doesn't exist

**Solution:**
The file is created automatically on first version bump. If it doesn't exist, run:
```bash
npm run version:bump
```

### Server shows old version

**Problem:** Server displays outdated version after bump

**Solution:**
Restart the server. The version is loaded from `package.json` at startup.

---

## Version Format

Current version format: **MAJOR.MINOR.PATCH**

Example progression:
```
1.0.0  → Initial release
1.0.1  → Bug fix
1.0.2  → Bug fix
1.1.0  → New feature
1.1.1  → Bug fix
2.0.0  → Breaking change
```

---

**Last Updated:** October 2025
**Current Version System:** v1.0.0
