# Firecrawl API Setup Guide

## 🔐 Current Status: API Key Invalid

Your current Firecrawl API key is **expired or invalid**.

**Current Key:** `fc-6e75bf4...6d45` (35 characters)
**Status:** ❌ Unauthorized

---

## 🔧 How to Fix

### Step 1: Get a New API Key

1. **Visit Firecrawl:**
   - Go to: https://firecrawl.dev
   - Sign in to your account (or create one if needed)

2. **Navigate to API Keys:**
   - Click on your profile/settings
   - Find "API Keys" or "Developer" section
   - Generate a new API key

3. **Copy the New Key:**
   - Copy the full API key (starts with `fc-`)
   - Keep it secure!

### Step 2: Update Your Environment

#### Option A: Update .zshrc (Recommended)

```bash
# Edit your .zshrc
nano ~/.zshrc

# Find the line with FIRECRAWL_API_KEY and update it:
export FIRECRAWL_API_KEY="fc-your-new-key-here"

# Save and reload:
source ~/.zshrc
```

#### Option B: Set for Current Session Only

```bash
export FIRECRAWL_API_KEY="fc-your-new-key-here"
```

### Step 3: Test the New Key

```bash
node test-firecrawl-api.js
```

**Expected output:**
```
✅ SUCCESS! Firecrawl API is working correctly!
```

---

## 📝 Alternative: Manual Documentation Extraction

If you don't want to use Firecrawl, you can manually extract the documentation:

### Method 1: Browser + Copy/Paste

1. Visit: https://docs-cortex.paloaltonetworks.com/r/Cortex-Cloud-Platform-APIs/Cloud-Onboarding-APIs
2. Let the page fully load
3. Copy the documentation content
4. Save to a text file

### Method 2: Use Browser DevTools

1. Open the URL in Chrome/Edge
2. Open DevTools (F12)
3. Go to Console tab
4. Run:
   ```javascript
   document.body.innerText
   ```
5. Copy the output

### Method 3: Use Existing Documentation

The documentation I already created covers the Cloud Onboarding APIs:
- **CORTEX_CLOUD_ONBOARDING_API.md** - Complete API reference
- **CORTEX_API_DOCUMENTATION.md** - General Cortex APIs

These are based on the official Palo Alto Networks API documentation at:
- https://pan.dev/prisma-cloud/api/cspm/

---

## 🧪 Testing Scripts

### Test Firecrawl API Key
```bash
node test-firecrawl-api.js
```

### Scrape Cortex Cloud Onboarding APIs
```bash
node scrape-cortex-docs.js
```

---

## 📊 Firecrawl API Details

### What Firecrawl Does

Firecrawl converts web pages into clean markdown, handling:
- JavaScript-rendered content
- Dynamic loading
- Complex page structures
- Clean markdown output

### Pricing (as of 2025)

- **Free Tier:** Limited requests per month
- **Paid Plans:** More requests, faster processing
- Check current pricing at: https://firecrawl.dev/pricing

### Alternative Services

If Firecrawl doesn't work for you, consider:

1. **Jina AI Reader:**
   ```bash
   curl https://r.jina.ai/https://docs-cortex.paloaltonetworks.com/r/Cortex-Cloud-Platform-APIs/Cloud-Onboarding-APIs
   ```

2. **Playwright (requires installation):**
   ```bash
   npx playwright install chrome
   # Then use mcp__playwright tools
   ```

3. **Simple curl + html2text:**
   ```bash
   curl -sL URL | html2text > output.txt
   ```

---

## ✅ Quick Verification

After updating your API key, verify it works:

```bash
# 1. Check environment variable
echo $FIRECRAWL_API_KEY

# 2. Run test
node test-firecrawl-api.js

# 3. If successful, scrape docs
node scrape-cortex-docs.js
```

---

## 🆘 Troubleshooting

### "Module not found" Error

```bash
npm install @mendable/firecrawl-js
```

### Environment Variable Not Set

```bash
# Verify it's in .zshrc
grep FIRECRAWL ~/.zshrc

# Reload shell
source ~/.zshrc

# Verify it's loaded
echo $FIRECRAWL_API_KEY
```

### "Unauthorized" Still Appears

1. **Check the key format:**
   - Should start with `fc-`
   - Should be 30-40 characters long

2. **Regenerate a new key:**
   - Old keys may be revoked
   - Generate a completely new key from Firecrawl dashboard

3. **Check account status:**
   - Ensure your Firecrawl account is active
   - Check if free tier limits are exceeded

### Rate Limit Errors

If you see rate limit errors:
- Wait 5-10 minutes between requests
- Consider upgrading your Firecrawl plan
- Use caching to reduce API calls

---

## 📚 Documentation Status

### Already Available (No Firecrawl Needed)

You already have comprehensive API documentation:

| File | Status | Content |
|------|--------|---------|
| **CORTEX_CLOUD_ONBOARDING_API.md** | ✅ Complete | Azure onboarding APIs, authentication, endpoints, code examples |
| **CORTEX_API_DOCUMENTATION.md** | ✅ Complete | General Cortex/Prisma Cloud APIs |

### Can Be Scraped (Requires Valid Key)

| URL | Purpose |
|-----|---------|
| https://docs-cortex.paloaltonetworks.com/r/Cortex-Cloud-Platform-APIs/Cloud-Onboarding-APIs | Latest Cloud Onboarding API docs |
| https://pan.dev/prisma-cloud/api/cspm/ | Prisma Cloud CSPM APIs |

---

## 🎯 Recommendation

**You don't need to fix Firecrawl immediately.**

The documentation files I created (`CORTEX_CLOUD_ONBOARDING_API.md` and `CORTEX_API_DOCUMENTATION.md`) contain all the information you need for your azure-cortex-ui project.

**Only update Firecrawl if:**
- You need to scrape updated documentation regularly
- The API endpoints change significantly
- You want to automate documentation updates

---

**Last Updated:** October 23, 2025
**Firecrawl Version:** 4.4.1
**Test Script:** test-firecrawl-api.js
