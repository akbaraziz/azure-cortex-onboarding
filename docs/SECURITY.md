# Security Features Documentation

## Overview

This document describes the security features implemented in the Azure Cortex Cloud Onboarding Web UI application.

## Security Implementations

### 1. Input Validation (P2 - HIGH Priority)

**Status:** ✅ Implemented

**Description:** All user inputs are validated using Zod schemas to prevent command injection and other input-based attacks.

**Implementation Details:**
- Zod validation schema for onboarding configuration
- Validates data types, formats, and ranges
- UUID validation for subscription and tenant IDs
- Regex validation for names and regions
- Custom error messages for validation failures

**Validated Fields:**
- `subscriptionId` - Must be valid UUID
- `tenantId` - Must be valid UUID
- `appName` - Alphanumeric with hyphens only, 3-100 chars
- `cortexApiUrl` - Must be valid URL
- `cortexAccessKey` - 20-200 characters
- `cortexSecretKey` - 20-200 characters
- `azureAccountName` - Alphanumeric with hyphens only, 3-100 chars
- `environment` - Lowercase letters only, max 20 chars
- `azureRegion` - Lowercase alphanumeric only, max 50 chars
- `logRetentionDays` - Integer between 7 and 730

**Error Response Format:**
```json
{
  "error": "Invalid input data",
  "details": [
    {
      "field": "subscriptionId",
      "message": "Invalid subscription ID format"
    }
  ]
}
```

---

### 2. Authentication (P3 - HIGH Priority)

**Status:** ✅ Implemented (Optional)

**Description:** JWT-based authentication to protect sensitive endpoints.

**Implementation Details:**
- JWT tokens with configurable expiry (default: 24 hours)
- Authentication can be enabled/disabled via `AUTH_ENABLED` environment variable
- Token-based access control for deployment endpoints
- Secure token generation and verification

**Configuration:**
```bash
# .env file
AUTH_ENABLED=true
JWT_SECRET=your-strong-random-secret-key
JWT_EXPIRY=24h
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-secure-password
```

**Authentication Endpoint:**
```bash
POST /api/auth/token
Content-Type: application/json

{
  "username": "admin",
  "password": "your-password"
}

# Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "24h",
  "message": "Authentication successful"
}
```

**Using the Token:**
```bash
POST /api/start-onboarding
Authorization: Bearer your-jwt-token-here
Content-Type: application/json

{
  "subscriptionId": "...",
  ...
}
```

**Protected Endpoints:**
- `POST /api/start-onboarding` - Requires JWT token when AUTH_ENABLED=true

---

### 3. CORS Configuration (P4 - HIGH Priority)

**Status:** ✅ Implemented

**Description:** Restrictive CORS policy to prevent unauthorized cross-origin requests.

**Implementation Details:**
- Configurable allowed origins via environment variable
- Default allows only localhost for development
- Credentials support enabled
- Rejects requests from unauthorized origins

**Configuration:**
```bash
# .env file
ALLOWED_ORIGINS=http://localhost:3001,http://127.0.0.1:3001
```

**Production Configuration:**
```bash
ALLOWED_ORIGINS=https://yourdomain.com,https://admin.yourdomain.com
```

**CORS Settings:**
- `credentials: true` - Allows cookies and authentication headers
- `optionsSuccessStatus: 200` - Legacy browser support
- Origin validation on every request

---

### 4. Rate Limiting (P4 - HIGH Priority)

**Status:** ✅ Implemented

**Description:** Rate limiting to prevent DoS attacks and brute force attempts.

**Implementation Details:**

**General API Rate Limit:**
- Window: 15 minutes
- Max requests: 100 per IP
- Applies to: All `/api/*` endpoints

**Authentication Rate Limit:**
- Window: 15 minutes
- Max requests: 5 per IP
- Applies to: `POST /api/auth/token`

**Rate Limit Headers:**
```
RateLimit-Limit: 100
RateLimit-Remaining: 95
RateLimit-Reset: 1640000000
```

**Rate Limit Exceeded Response:**
```json
{
  "error": "Too many requests from this IP, please try again later."
}
```

---

### 5. Path Validation (P5 - MEDIUM Priority)

**Status:** ✅ Implemented

**Description:** UUID validation for deployment IDs to prevent path traversal attacks.

**Implementation Details:**
- Validates deployment IDs against UUID v4 format
- Applied to HTTP endpoints and WebSocket connections
- Rejects invalid UUIDs immediately

**Validated Endpoints:**
- `GET /api/deployment/:id` - HTTP endpoint
- `WebSocket /ws/:id` - WebSocket connection

**UUID Regex:**
```regex
/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
```

**Invalid ID Response:**
```json
{
  "error": "Invalid deployment ID format"
}
```

---

### 6. Log Sanitization (P6 - MEDIUM Priority)

**Status:** ✅ Implemented

**Description:** Automatic sanitization of sensitive data in logs.

**Implementation Details:**
- Sanitizes sensitive fields before logging
- Masks passwords, secrets, tokens, keys
- Shows only first and last 4 characters of long values
- Recursive sanitization for nested objects

**Sanitized Fields:**
- `password`
- `secret`
- `token`
- `key`
- `auth`
- `credential`
- `cortexSecretKey`
- `cortexAccessKey`
- `subscriptionId`
- `tenantId`

**Example:**
```javascript
// Original:
{
  cortexSecretKey: "abcdef1234567890xyz",
  subscriptionId: "f366a585-c60e-4067-b894-e1665b440c58"
}

// Sanitized in logs:
{
  cortexSecretKey: "abcd...0xyz",
  subscriptionId: "f366...0c58"
}
```

---

### 7. Security Headers (P7 - LOW Priority)

**Status:** ✅ Implemented

**Description:** HTTP security headers via Helmet.js middleware.

**Implementation Details:**
- Helmet.js with default secure settings
- Prevents common web vulnerabilities

**Headers Applied:**
- `Content-Security-Policy` - Prevents XSS attacks
- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-Content-Type-Options: nosniff` - Prevents MIME sniffing
- `Strict-Transport-Security` - Forces HTTPS
- `X-Download-Options: noopen` - Prevents file execution
- `X-DNS-Prefetch-Control: off` - Reduces privacy leaks

---

## Race Condition Prevention

**Status:** ✅ Implemented

**Description:** Mutex locks protect concurrent access to shared resources.

**Implementation Details:**
- `async-mutex` package for concurrency control
- Mutex locks for deployment state access
- Safe file operations with retry logic
- WebSocket error handling

**Protected Operations:**
- Deployment Map read/write
- Deployment status updates
- Directory creation
- File copying

---

## Configuration

### Development Setup

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Configure for local development (authentication disabled):
```bash
PORT=3001
AUTH_ENABLED=false
ALLOWED_ORIGINS=http://localhost:3001,http://127.0.0.1:3001
```

3. Start the server:
```bash
npm start
```

### Production Setup

1. Enable authentication:
```bash
AUTH_ENABLED=true
```

2. Generate a strong JWT secret:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

3. Set strong credentials:
```bash
JWT_SECRET=<generated-secret-from-step-2>
ADMIN_USERNAME=<your-admin-username>
ADMIN_PASSWORD=<your-strong-password>
```

4. Configure allowed origins:
```bash
ALLOWED_ORIGINS=https://yourdomain.com
```

5. Verify security settings:
```bash
# All these should be true in production:
- AUTH_ENABLED=true
- JWT_SECRET is not default value
- ADMIN_PASSWORD is not default value
- ALLOWED_ORIGINS contains only your domains
- HTTPS is enforced
```

---

## Security Best Practices

### For Deployment

1. ✅ **Never commit .env files** - Already protected by `.gitignore`
2. ✅ **Change default credentials** - Set strong admin password
3. ✅ **Enable authentication in production** - Set `AUTH_ENABLED=true`
4. ✅ **Use HTTPS in production** - Configure reverse proxy (nginx/Apache)
5. ✅ **Restrict CORS origins** - Only allow your domain
6. ✅ **Monitor rate limit violations** - Check logs for suspicious activity
7. ✅ **Rotate JWT secrets regularly** - Update `JWT_SECRET` periodically
8. ✅ **Keep dependencies updated** - Run `npm audit` regularly

### For Operations

1. ✅ **Use strong passwords** - 12+ characters, mixed case, numbers, symbols
2. ✅ **Limit token expiry** - Shorter expiry (e.g., 1h) for high-security environments
3. ✅ **Monitor logs** - Watch for validation errors and authentication failures
4. ✅ **Review deployments** - Audit completed deployments regularly
5. ✅ **Backup secrets** - Store JWT_SECRET and credentials securely

---

## Testing Security Features

### 1. Test Input Validation

```bash
# Invalid subscription ID (should fail)
curl -X POST http://localhost:3001/api/start-onboarding \
  -H "Content-Type: application/json" \
  -d '{"subscriptionId": "invalid-uuid"}'

# Expected: 400 Bad Request with validation errors
```

### 2. Test Authentication

```bash
# Without token (should fail if AUTH_ENABLED=true)
curl -X POST http://localhost:3001/api/start-onboarding \
  -H "Content-Type: application/json" \
  -d '{...}'

# Expected: 401 Unauthorized

# With valid token (should succeed)
TOKEN=$(curl -X POST http://localhost:3001/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"changeme"}' \
  | jq -r '.token')

curl -X POST http://localhost:3001/api/start-onboarding \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{...}'

# Expected: 200 OK with deployment ID
```

### 3. Test Rate Limiting

```bash
# Make multiple rapid requests
for i in {1..10}; do
  curl http://localhost:3001/api/health
done

# Should see rate limit headers in response
```

### 4. Test Path Validation

```bash
# Invalid deployment ID (should fail)
curl http://localhost:3001/api/deployment/invalid-id

# Expected: 400 Bad Request
```

### 5. Test CORS

```bash
# Request from unauthorized origin (should fail)
curl -H "Origin: https://evil.com" \
  http://localhost:3001/api/health

# Expected: CORS error
```

---

## Vulnerability Disclosure

If you discover a security vulnerability, please report it to:
- **Email:** security@yourdomain.com
- **Issue Tracker:** (Do NOT create public issues for security vulnerabilities)

**Please include:**
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if available)

---

## Security Checklist

Use this checklist before deploying to production:

- [ ] `.env` file created and configured
- [ ] `AUTH_ENABLED=true` in production
- [ ] `JWT_SECRET` changed from default
- [ ] `ADMIN_PASSWORD` changed from default
- [ ] `ALLOWED_ORIGINS` set to production domains only
- [ ] HTTPS enabled (via reverse proxy)
- [ ] Dependencies updated (`npm audit fix`)
- [ ] Logs reviewed for security warnings
- [ ] Rate limiting tested
- [ ] Authentication tested
- [ ] Input validation tested
- [ ] Secrets properly stored (not in code)
- [ ] `.gitignore` includes `.env` and `*.tfvars`

---

## Compliance

This implementation addresses:

- **OWASP Top 10:**
  - A03:2021 – Injection (Input validation)
  - A01:2021 – Broken Access Control (Authentication)
  - A05:2021 – Security Misconfiguration (Helmet, CORS)
  - A04:2021 – Insecure Design (Rate limiting, logging)

- **CWE:**
  - CWE-306: Missing Authentication
  - CWE-78: OS Command Injection
  - CWE-942: Permissive CORS Policy
  - CWE-532: Insertion of Sensitive Information into Log File

---

**Document Version:** 1.0
**Last Updated:** January 2025
**Maintainer:** Azure Cortex Onboarding Security Team
