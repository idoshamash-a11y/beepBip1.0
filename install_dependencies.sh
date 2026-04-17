#!/bin/bash

echo "Installing Flutter dependencies for iOS development..."
echo ""

# Install Rosetta
echo "1. Installing Rosetta (required for Flutter on ARM Mac)..."
sudo softwareupdate --install-rosetta --agree-to-license
if [ $? -eq 0 ]; then
    echo "✓ Rosetta installed successfully"
else
    echo "✗ Failed to install Rosetta"
    exit 1
fi

echo ""

# Install CocoaPods
echo "2. Installing CocoaPods (required for iOS dependencies)..."
sudo gem install cocoapods
if [ $? -eq 0 ]; then
    echo "✓ CocoaPods installed successfully"
else
    echo "✗ Failed to install CocoaPods"
    exit 1
fi

echo ""

# Run pod install
echo "3. Installing iOS pods..."
cd ios
pod install
if [ $? -eq 0 ]; then
    echo "✓ Pods installed successfully"
else
    echo "✗ Failed to install pods"
    exit 1
fi

cd ..

echo ""
echo "=========================================="
echo "All dependencies installed successfully!"
echo "=========================================="
echo ""
echo "You can now:"
echo "  1. Open the project in Xcode: open ios/Runner.xcworkspace"
echo "  2. Or run: ~/flutter/bin/flutter run"
echo ""
