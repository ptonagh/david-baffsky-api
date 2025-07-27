#!/bin/bash

# Recovery Coach App - Test Script
# Run this to test the web previews

echo "🚀 Starting Recovery Coach Web Preview Server..."
echo ""
echo "Available previews:"
echo "1. Main App Preview: http://localhost:8000/web-preview-enhanced.html"
echo "2. Onboarding Flow: http://localhost:8000/onboarding-preview.html"
echo "3. Project Overview: http://localhost:8000/index.html"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start Python HTTP server
python3 -m http.server 8000