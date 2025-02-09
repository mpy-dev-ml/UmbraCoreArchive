#!/bin/bash

# Script to clean up Core files and ensure proper conformance
# This script will modify Swift files in the UmbraCore directory

set -e  # Exit on error

# Colour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CORE_ROOT="/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraCore"

# Function to update Core files
update_file() {
    local file=$1
    echo -e "${YELLOW}Updating $file...${NC}"
    
    # Create backup
    cp "$file" "${file}.bak"
    
    # Extract the actual content without any headers
    awk '
        BEGIN { printing = 0; content_found = 0 }
        /^import/ { printing = 1; content_found = 1 }
        content_found && /^$/ { if (!found_first_blank) { found_first_blank = 1 } else { printing = 1 } }
        printing { print }
    ' "$file" > "${file}.content"
    
    # Create new file with proper header
    cat > "$file" << EOL
//
// $(basename "$file")
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

EOL

    # Append the content
    cat "${file}.content" >> "$file"
    rm "${file}.content"
    
    # Update protocol conformance
    if [[ $file == *"/Protocols/"* ]]; then
        # Add Sendable to async protocols
        if grep -q "async" "$file"; then
            sed -i '' 's/public protocol \([^:]*\)/public protocol \1: Sendable/g' "$file"
        fi
    fi
    
    # Update model conformance
    if [[ $file == *"/Models/"* ]]; then
        # Add Hashable and Identifiable where appropriate
        if grep -q "id:" "$file"; then
            sed -i '' 's/: Codable/: Codable, Hashable, Identifiable/g' "$file"
        fi
        
        # Add CustomStringConvertible if not present
        if ! grep -q "CustomStringConvertible" "$file"; then
            sed -i '' 's/: Codable/: Codable, CustomStringConvertible/g' "$file"
            
            # Add description implementation if needed
            if ! grep -q "description:" "$file" && grep -q "CustomStringConvertible" "$file"; then
                echo '
    public var description: String {
        return String(describing: self)
    }' >> "$file"
            fi
        fi
    fi
    
    # Update error types
    if [[ $file == *"/Errors/"* ]]; then
        # Ensure LocalizedError conformance
        sed -i '' 's/: Error/: LocalizedError/g' "$file"
        
        # Add errorDescription if needed
        if grep -q "LocalizedError" "$file" && ! grep -q "errorDescription:" "$file"; then
            echo '
    public var errorDescription: String? {
        switch self {
            default: return localizedDescription
        }
    }' >> "$file"
        fi
    fi
    
    # Update services
    if [[ $file == *"/Services/"* ]]; then
        # Add actor keyword for async services
        if grep -q "async" "$file"; then
            sed -i '' 's/public class \([^:]*\)/public actor \1/g' "$file"
        fi
        
        # Add Sendable conformance
        if grep -q "actor" "$file"; then
            sed -i '' 's/public actor \([^:]*\)/public actor \1: Sendable/g' "$file"
        fi
    fi
    
    echo -e "${GREEN}✓ Updated: $file${NC}"
}

# Process all Swift files
find "$CORE_ROOT" -name "*.swift" | while read -r file; do
    update_file "$file"
done

echo -e "${GREEN}Core cleanup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changes in Xcode"
echo "2. Ensure all protocol conformances are properly implemented"
echo "3. Verify actor isolation and Sendable conformance"
echo "4. Check that all error types have proper localization"
echo "5. Build the project to check for any remaining issues"
