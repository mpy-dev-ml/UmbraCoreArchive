#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting advanced code cleanup...${NC}"

# Function to process Swift files
process_file() {
    local file=$1
    echo -e "${YELLOW}Processing ${file}...${NC}"
    
    # Create a temporary file
    tmp_file=$(mktemp)
    
    # Fix line lengths by breaking at natural points
    awk '
    length($0) > 100 {
        if ($0 ~ /^[[:space:]]*\/\//) next  # Skip comments
        gsub(/,[[:space:]]*/, ",\n    ")    # Break after commas
        gsub(/\([[:space:]]*/, "(\n    ")   # Break after opening parentheses
        gsub(/[[:space:]]*\)/, "\n)")       # Break before closing parentheses
    }
    { print }
    ' "$file" > "$tmp_file"
    
    # Replace NSString with String, etc
    sed -i '' \
        -e 's/NSString/String/g' \
        -e 's/NSArray/Array/g' \
        -e 's/NSDictionary/Dictionary/g' \
        -e 's/NSData/Data/g' \
        -e 's/NSDate/Date/g' \
        -e 's/NSError/Error/g' \
        "$tmp_file"
    
    # Add explicit type interfaces where missing
    awk '
    /let|var/ && !/:[[:space:]]*[A-Za-z]/ {
        # Skip if line contains type annotation or is part of string
        if ($0 ~ /:/ || $0 ~ /\"/) print
        else {
            # Try to infer type and add annotation
            if ($0 ~ /=.*\"/) sub(/=/, ": String =")
            else if ($0 ~ /=.*[0-9]+\.[0-9]+/) sub(/=/, ": Double =")
            else if ($0 ~ /=.*[0-9]+/) sub(/=/, ": Int =")
            else if ($0 ~ /=.*true|false/) sub(/=/, ": Bool =")
            else if ($0 ~ /=.*\[/) sub(/=/, ": [Any] =")
            else if ($0 ~ /=.*\{/) sub(/=/, ": () -> Void =")
            print
        }
    }
    !(/let|var/ && !/:[[:space:]]*[A-Za-z]/) { print }
    ' "$tmp_file" > "${tmp_file}.new"
    
    # Standardize deployment target declarations
    sed -i '' \
        -e 's/@available(macOS [0-9.]*/@available(macOS 14.0/g' \
        "${tmp_file}.new"
    
    # Move the processed file back
    mv "${tmp_file}.new" "$file"
    rm "$tmp_file"
}

# Process all Swift files in the Errors module
find Sources/Errors -name "*.swift" -type f | while read -r file; do
    process_file "$file"
done

# Process XPCServiceProtocol specifically
if [ -f "Sources/UmbraCore/Services/XPC/XPCServiceProtocol.swift" ]; then
    process_file "Sources/UmbraCore/Services/XPC/XPCServiceProtocol.swift"
fi

echo -e "${GREEN}Code cleanup complete!${NC}"
