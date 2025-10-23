#!/usr/bin/env node
/**
 * Test Firecrawl API Key Validity
 * Simple script to verify if your Firecrawl API key is working
 */

const FirecrawlApp = require('@mendable/firecrawl-js').default;

const apiKey = process.env.FIRECRAWL_API_KEY;

if (!apiKey) {
  console.error('❌ FIRECRAWL_API_KEY environment variable is not set');
  process.exit(1);
}

console.log('🔑 Testing Firecrawl API Key...');
console.log(`📌 Key: ${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 4)}`);
console.log(`📏 Length: ${apiKey.length} characters`);
console.log('');

const firecrawl = new FirecrawlApp({ apiKey });

// Test with a simple, reliable URL
const testUrl = 'https://example.com';

async function testFirecrawl() {
  try {
    console.log(`🌐 Testing scrape on: ${testUrl}`);
    console.log('⏳ Please wait...\n');

    const result = await firecrawl.scrape(testUrl, {
      formats: ['markdown'],
      onlyMainContent: true,
    });

    if (result && result.markdown) {
      console.log('✅ SUCCESS! Firecrawl API is working correctly!');
      console.log('');
      console.log('📊 Response Details:');
      console.log(`   - Content length: ${result.markdown.length} characters`);
      console.log(`   - Success: ${result.success !== false}`);
      console.log('');
      console.log('📝 Preview (first 200 chars):');
      console.log('   ' + result.markdown.substring(0, 200).replace(/\n/g, '\n   '));
      console.log('');
      console.log('✅ Your Firecrawl API key is valid and working!');
      return true;
    } else {
      console.log('⚠️  Unexpected response format');
      console.log(JSON.stringify(result, null, 2));
      return false;
    }

  } catch (error) {
    console.error('❌ Firecrawl API Error:');
    console.error('');

    if (error.message.includes('Unauthorized') || error.message.includes('Invalid token')) {
      console.error('🔐 Authentication Failed');
      console.error('   Your API key is invalid or expired.');
      console.error('');
      console.error('📋 To fix this:');
      console.error('   1. Visit: https://firecrawl.dev');
      console.error('   2. Sign in to your account');
      console.error('   3. Navigate to API Keys section');
      console.error('   4. Generate a new API key');
      console.error('   5. Update your ~/.zshrc file:');
      console.error('      export FIRECRAWL_API_KEY="fc-your-new-key"');
      console.error('   6. Reload: source ~/.zshrc');
    } else if (error.message.includes('rate limit')) {
      console.error('⏱️  Rate Limit Exceeded');
      console.error('   You have made too many requests.');
      console.error('   Please wait a few minutes and try again.');
    } else {
      console.error(`   Error: ${error.message}`);

      if (error.response) {
        console.error(`   Status: ${error.response.status}`);
        console.error(`   Details: ${JSON.stringify(error.response.data, null, 2)}`);
      }
    }

    console.error('');
    return false;
  }
}

// Run the test
testFirecrawl()
  .then((success) => {
    process.exit(success ? 0 : 1);
  })
  .catch((error) => {
    console.error('💥 Unexpected error:', error);
    process.exit(1);
  });
