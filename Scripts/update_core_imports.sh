#!/bin/bash

# Script to update import statements and ensure consistency in Core files
# This script will modify Swift files in the UmbraCore directory

set -e  # Exit on error

# Colour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CORE_ROOT="/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraCore"

# Function to update imports in a file
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
// Copyright © 2025 MPY Dev. All rights reserved.
//

$(cat "$file" | grep -v "//  First created:" | grep -v "//  Last updated:" | grep -v "//  rBUM")
EOL
    mv "${file}.tmp" "$file"
    
    # Update protocol conformance for models that need Codable
    if [[ $file == *"/Models/"* ]]; then
        sed -i '' 's/: Codable {/: Codable, CustomStringConvertible {/g' "$file"
        
        # Add description if it doesn't exist and the file was modified
        if grep -q "CustomStringConvertible" "$file" && ! grep -q "public var description:" "$file"; then
            echo "
    public var description: String {
        return String(describing: self)
    }" >> "$file"
        fi
    fi
    
    echo -e "${GREEN}✓ Updated: $file${NC}"
}

# Process all Swift files
find "$CORE_ROOT" -name "*.swift" | while read -r file; do
    update_file "$file"
done

echo -e "${GREEN}Updates complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changes in Xcode"
echo "2. Ensure all protocol conformances are properly implemented"
echo "3. Build the project to check for any remaining issues"
