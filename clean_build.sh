#!/bin/bash

# Clean Build Script for wodAI
# This script helps resolve "Multiple commands produce" errors

echo "🧹 Cleaning wodAI build artifacts..."

# 1. Clean DerivedData
echo "📁 Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/wodAI-*

# 2. Clean build folder
echo "🏗️ Cleaning build folder..."
cd "/Users/jordanlittell/IOSProjects/wodAI"
xcodebuild clean -project wodAI.xcodeproj -scheme wodAI

# 3. Clean module cache
echo "📦 Cleaning module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache

# 4. Reset package caches
echo "📚 Resetting package caches..."
cd "/Users/jordanlittell/IOSProjects/wodAI"
xcodebuild -resolvePackageDependencies

echo "✅ Clean complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Let it index the project"
echo "3. Build again"
echo ""
echo "If the error persists:"
echo "- Check Build Phases for duplicate Info.plist entries"
echo "- Ensure Info-URLSchemes.plist is not in Copy Bundle Resources"
echo "- Verify only one Info.plist path in Build Settings"
