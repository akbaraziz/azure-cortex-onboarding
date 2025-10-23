#!/usr/bin/env node
/**
 * Firecrawl Script to Scrape Cortex Cloud API Documentation
 *
 * Usage:
 *   FIRECRAWL_API_KEY=your_key node scrape-cortex-docs.js
 *
 * Or set FIRECRAWL_API_KEY in your environment
 */

const FirecrawlApp = require('@mendable/firecrawl-js').default;
const fs = require('fs');
const path = require('path');

// Configuration
const CORTEX_API_DOCS_URL = 'https://docs-cortex.paloaltonetworks.com/r/Cortex-Cloud-Platform-APIs/Cloud-Onboarding-APIs';
const OUTPUT_DIR = './cortex-cloud-onboarding-docs';
const OUTPUT_FILE = path.join(OUTPUT_DIR, 'cortex-cloud-onboarding-api.md');

// Check for API key
const apiKey = process.env.FIRECRAWL_API_KEY;
if (!apiKey) {
  console.error('❌ Error: FIRECRAWL_API_KEY environment variable is not set');
  console.error('\nUsage:');
  console.error('  FIRECRAWL_API_KEY=your_key node scrape-cortex-docs.js');
  process.exit(1);
}

// Initialize Firecrawl
const firecrawl = new FirecrawlApp({ apiKey });

async function scrapeCortexDocs() {
  console.log('🔥 Starting Firecrawl scraping...');
  console.log(`📄 Target URL: ${CORTEX_API_DOCS_URL}\n`);

  try {
    // Create output directory
    if (!fs.existsSync(OUTPUT_DIR)) {
      fs.mkdirSync(OUTPUT_DIR, { recursive: true });
      console.log(`✅ Created output directory: ${OUTPUT_DIR}`);
    }

    // Scrape the documentation page
    console.log('🌐 Scraping Cortex Cloud Onboarding API documentation...');
    console.log('⏳ This may take 30-60 seconds for JavaScript to render...\n');

    const scrapeResult = await firecrawl.scrape(CORTEX_API_DOCS_URL, {
      formats: ['markdown'],
      waitFor: 10000, // Wait longer for JavaScript-heavy pages
      timeout: 60000, // 60 second timeout
    });

    console.log('📡 Received response from Firecrawl');
    console.log(`   Success: ${scrapeResult.success}`);

    if (scrapeResult.error) {
      console.log(`   Error: ${scrapeResult.error}`);
    }

    if (!scrapeResult.success && !scrapeResult.markdown) {
      throw new Error(`Scraping failed: ${scrapeResult.error || JSON.stringify(scrapeResult)}`);
    }

    console.log('✅ Successfully scraped the page\n');

    // Extract the markdown content
    const markdown = scrapeResult.markdown || scrapeResult.data?.markdown || scrapeResult.content || '';

    if (!markdown || markdown.length < 100) {
      console.log('\n⚠️  Warning: Content appears to be empty or too short');
      console.log('   This might be a JavaScript-heavy page that needs different scraping');
      console.log('   Full response:', JSON.stringify(scrapeResult, null, 2));
    }

    // Save to file
    fs.writeFileSync(OUTPUT_FILE, markdown);
    console.log(`📝 Saved documentation to: ${OUTPUT_FILE}`);
    console.log(`📊 Document size: ${(markdown.length / 1024).toFixed(2)} KB\n`);

    // Also save the raw HTML for reference
    const html = scrapeResult.html || scrapeResult.data?.html;
    if (html) {
      const htmlFile = path.join(OUTPUT_DIR, 'cortex-api-documentation.html');
      fs.writeFileSync(htmlFile, html);
      console.log(`📝 Saved HTML to: ${htmlFile}`);
    }

    // Display a preview
    console.log('📖 Preview (first 500 characters):');
    console.log('─'.repeat(80));
    console.log(markdown.substring(0, 500) + '...');
    console.log('─'.repeat(80));
    console.log('\n✅ Scraping completed successfully!');

    // Try to map related pages
    console.log('\n🕷️  Attempting to map related documentation pages...');
    const mapResult = await firecrawl.map(CORTEX_API_DOCS_URL, {
      search: 'API',
      limit: 20,
    });

    const links = mapResult.links || mapResult.data?.links || [];
    if (links.length > 0) {
      console.log(`\n📑 Found ${links.length} related pages:`);
      links.forEach((link, index) => {
        console.log(`   ${index + 1}. ${link}`);
      });

      // Save links to file
      const linksFile = path.join(OUTPUT_DIR, 'related-pages.json');
      fs.writeFileSync(linksFile, JSON.stringify(links, null, 2));
      console.log(`\n📝 Saved related pages to: ${linksFile}`);
    }

    return {
      success: true,
      markdown,
      outputFile: OUTPUT_FILE,
    };

  } catch (error) {
    console.error('\n❌ Error during scraping:');
    console.error(error.message);

    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }

    process.exit(1);
  }
}

// Run the scraper
scrapeCortexDocs()
  .then(() => {
    console.log('\n🎉 All done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Unexpected error:', error);
    process.exit(1);
  });
