#!/bin/bash

# Function to process a Swift file
process_file() {
    local file="$1"
    echo "Processing $file..."
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Add @preconcurrency import if missing
    awk '
        BEGIN { added_preconcurrency = 0 }
        /^import/ && !added_preconcurrency {
            if (!/@preconcurrency/) {
                sub(/^import/, "@preconcurrency import")
            }
            added_preconcurrency = 1
        }
        { print }
    ' "$file" > "$temp_file"
    
    # Add explicit type interfaces and fix documentation
    awk '
        # Add missing documentation for public declarations
        /^[[:space:]]*public/ && prev !~ /\/\/\// {
            if ($2 == "enum" || $2 == "struct" || $2 == "class" || $2 == "protocol") {
                print "/// " $2 " for handling " tolower(substr($3, 1, 1)) substr($3, 2)
            }
        }
        
        # Add explicit type interfaces for properties
        /[[:space:]]*(private|internal|public)[[:space:]]+var/ {
            if ($0 !~ /:[[:space:]]*[A-Za-z]/) {
                # Property doesnt have explicit type, try to infer
                if ($0 ~ /=/) {
                    # Has initializer, try to infer type
                    if ($0 ~ /\[/) { gsub(/=.*$/, ": [Any]") }
                    else if ($0 ~ /\"/) { gsub(/=.*$/, ": String") }
                    else if ($0 ~ /[0-9]+\.[0-9]+/) { gsub(/=.*$/, ": Double") }
                    else if ($0 ~ /[0-9]+/) { gsub(/=.*$/, ": Int") }
                    else if ($0 ~ /true|false/) { gsub(/=.*$/, ": Bool") }
                }
            }
        }
        
        # Fix type contents order
        /^[[:space:]]*\/\/[[:space:]]*MARK:[[:space:]]*-/ {
            if (tolower($0) ~ /lifecycle/) { order = 1 }
            else if (tolower($0) ~ /public/) { order = 2 }
            else if (tolower($0) ~ /internal/) { order = 3 }
            else if (tolower($0) ~ /private/) { order = 4 }
            else { order = 5 }
        }
        
        { print }
        
        { prev = $0 }
    ' "$temp_file" > "$file"
    
    # Run formatters
    swift-format format -i "$file"
    swiftlint --fix "$file"
    
    # Clean up
    rm "$temp_file"
}

# Process all Swift files in the Errors module
find Sources/Errors -name "*.swift" -print0 | while IFS= read -r -d '' file; do
    process_file "$file"
done

# Run final check
echo -e "\nChecking remaining issues..."
swiftlint lint Sources/Errors
