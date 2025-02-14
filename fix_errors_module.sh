#!/bin/bash

# Format all Swift files in the Errors module
find Sources/Errors -name "*.swift" -print0 | while IFS= read -r -d '' file; do
    echo "Formatting $file..."
    
    # Run swift-format
    swift-format format -i "$file"
    
    # Run SwiftLint auto-correct
    swiftlint --fix "$file"
done

# Run SwiftLint to check remaining issues
echo -e "\nChecking remaining issues..."
swiftlint lint Sources/Errors
