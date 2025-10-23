#!/usr/bin/env python3
"""
Scrape Cortex Cloud Onboarding APIs documentation
Uses requests-html for JavaScript rendering
"""

import json
import sys

try:
    from requests_html import HTMLSession
except ImportError:
    print("❌ requests-html not installed")
    print("Install with: pip install requests-html")
    sys.exit(1)

def scrape_cortex_docs():
    url = "https://docs-cortex.paloaltonetworks.com/r/Cortex-Cloud-Platform-APIs/Cloud-Onboarding-APIs"

    print(f"🔍 Fetching: {url}")
    print("⏳ Rendering JavaScript...")

    session = HTMLSession()
    try:
        response = session.get(url, timeout=30)

        # Render JavaScript
        response.html.render(timeout=20, sleep=3)

        # Extract text content
        text_content = response.html.text

        # Save to file
        output_file = "cortex-cloud-onboarding-api-content.txt"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(text_content)

        print(f"✅ Saved to: {output_file}")
        print(f"📊 Content length: {len(text_content)} characters")

        # Show preview
        print("\n📖 Preview (first 1000 characters):")
        print("=" * 80)
        print(text_content[:1000])
        print("=" * 80)

        # Try to extract API endpoint information
        if "API" in text_content or "endpoint" in text_content.lower():
            print("\n✅ Found API-related content")

        return text_content

    except Exception as e:
        print(f"❌ Error: {e}")
        return None
    finally:
        session.close()

if __name__ == "__main__":
    scrape_cortex_docs()
