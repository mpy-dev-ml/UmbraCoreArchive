#!/bin/bash

# Script to clean up XPC-related files and ensure proper XPC compliance
# This script will modify Swift files in the UmbraXPC directory

set -e  # Exit on error

# Colour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

XPC_ROOT="/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraXPC"

# Function to update XPC files
update_file() {
    local file=$1
    echo -e "${YELLOW}Updating $file...${NC}"
    
    # Create backup
    cp "$file" "${file}.bak"
    
    # Update module imports
    sed -i '' 's/import rBUM/import UmbraCore/g' "$file"
    
    # Add standard header
    cat > "${file}.tmp" << EOL
//
// $(basename "$file")
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

$(cat "$file" | grep -v "//  First created:" | grep -v "//  Last updated:" | grep -v "//  rBUM")
EOL
    mv "${file}.tmp" "$file"
    
    # Ensure @objc for protocols
    if [[ $file == *"Protocol.swift" ]]; then
        sed -i '' 's/public protocol/\@objc public protocol/g' "$file"
        # Add NSObject requirement for XPC protocols
        sed -i '' 's/@objc public protocol \([^:]*\)/\@objc public protocol \1: NSObject/g' "$file"
    fi
    
    # Add NSSecureCoding for model classes if they don't already have it
    if [[ $file == *"/Models/"* && ! $(grep -l "NSSecureCoding" "$file") ]]; then
        sed -i '' 's/: NSObject/: NSObject, NSSecureCoding/g' "$file"
        
        # Add supportsSecureCoding if it doesn't exist
        if ! grep -q "supportsSecureCoding" "$file"; then
            sed -i '' '/public class/a\
    public static var supportsSecureCoding: Bool { true }\
' "$file"
        fi
    fi
    
    # Add error handling requirements for XPC errors
    if [[ $file == *"/Errors/"* ]]; then
        sed -i '' 's/: Error/: NSError/g' "$file"
        sed -i '' 's/public enum/\@objc public enum/g' "$file"
    fi
    
    echo -e "${GREEN}✓ Updated: $file${NC}"
}

# Process all Swift files
find "$XPC_ROOT" -name "*.swift" | while read -r file; do
    update_file "$file"
done

echo -e "${GREEN}XPC cleanup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changes in Xcode"
echo "2. Ensure all NSSecureCoding implementations are complete"
echo "3. Verify @objc marking on all required methods"
echo "4. Check that all XPC protocols inherit from NSObject"
echo "5. Verify error types are properly bridged to NSError"
echo "6. Build the project to check for any remaining issues"
