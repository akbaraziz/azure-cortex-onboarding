#!/bin/bash
# Fetch Cortex Cloud / Prisma Cloud API Documentation
# Uses curl to download API docs from pan.dev

OUTPUT_DIR="./cortex-api-docs"
mkdir -p "$OUTPUT_DIR"

echo "🔍 Fetching Cortex Cloud API Documentation..."
echo "================================================"
echo ""

# Main API documentation page
echo "📄 Downloading main API overview..."
curl -L -s "https://pan.dev/prisma-cloud/api/cspm/" -o "$OUTPUT_DIR/api-overview.html"

# Login endpoint
echo "🔐 Downloading authentication docs..."
curl -L -s "https://pan.dev/prisma-cloud/api/cspm/login/" -o "$OUTPUT_DIR/login-api.html"

# API URLs
echo "🌐 Downloading API URLs and regions..."
curl -L -s "https://pan.dev/prisma-cloud/api/cspm/api-urls/" -o "$OUTPUT_DIR/api-urls.html"

# Cloud accounts API
echo "☁️  Downloading cloud accounts API..."
curl -L -s "https://pan.dev/prisma-cloud/api/cspm/cloud-accounts-api/" -o "$OUTPUT_DIR/cloud-accounts-api.html"

# Onboarding endpoints
echo "📥 Downloading Azure onboarding docs..."
curl -L -s "https://pan.dev/prisma-cloud/api/cspm/add-azure-cloud-account/" -o "$OUTPUT_DIR/azure-onboarding.html"

echo ""
echo "✅ Download complete!"
echo "📁 Files saved to: $OUTPUT_DIR"
echo ""
echo "Converting HTML to readable markdown..."

# Use pandoc if available, otherwise just list the files
if command -v pandoc &> /dev/null; then
    for file in "$OUTPUT_DIR"/*.html; do
        basename="${file%.html}"
        echo "   Converting: $(basename $file)"
        pandoc -f html -t markdown "$file" -o "${basename}.md"
    done
    echo "✅ Markdown conversion complete!"
else
    echo "ℹ️  Install pandoc for markdown conversion: sudo apt install pandoc"
    echo "   For now, HTML files are available in $OUTPUT_DIR"
fi

echo ""
echo "📚 Available documentation:"
ls -lh "$OUTPUT_DIR"
