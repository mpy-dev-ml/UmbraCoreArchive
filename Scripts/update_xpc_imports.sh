#!/bin/bash

# Script to update import statements and ensure XPC compliance
# This script will modify Swift files in the UmbraXPC directory

set -e  # Exit on error

# Colour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

XPC_ROOT="/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraXPC"

# Function to update imports in a file
update_file() {
    local file=$1
    echo -e "${YELLOW}Updating $file...${NC}"
    
    # Create backup
    cp "$file" "${file}.bak"
    
    # Update module imports
    sed -i '' 's/import rBUM/import UmbraCore/g' "$file"
    
    # Ensure @objc for protocols
    if [[ $file == *"Protocol.swift" ]]; then
        sed -i '' 's/public protocol/\@objc public protocol/g' "$file"
    fi
    
    # Add NSSecureCoding for model classes
    if [[ $file == *"/Models/"* && ! $(grep -l "NSSecureCoding" "$file") ]]; then
        sed -i '' 's/: NSObject/: NSObject, NSSecureCoding/g' "$file"
    fi
    
    # Add standard header
    cat > "${file}.tmp" << EOL
//
// $(basename "$file")
// UmbraCore
//
// Created by Migration Script
// Copyright © 2025 MPY Dev. All rights reserved.
//

$(cat "$file")
EOL
    mv "${file}.tmp" "$file"
    
    echo -e "${GREEN}✓ Updated: $file${NC}"
}

# Process all Swift files
find "$XPC_ROOT" -name "*.swift" | while read -r file; do
    update_file "$file"
done

echo -e "${GREEN}Updates complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changes in Xcode"
echo "2. Ensure all NSSecureCoding implementations are complete"
echo "3. Verify @objc marking on all required methods"
echo "4. Build the project to check for any remaining issues"
