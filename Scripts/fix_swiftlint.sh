#!/bin/bash

echo "\n=== SwiftLint Auto-fix Script ===\n"

# Directory containing the error files
ERRORS_DIR="Sources/Errors"

# Run SwiftFormat first
echo "Running SwiftFormat..."
if command -v swiftformat &> /dev/null; then
    swiftformat "$ERRORS_DIR" \
        --indent 4 \
        --maxwidth 120 \
        --wraparguments before-first \
        --wrapcollections before-first \
        --stripunusedargs closure-only \
        --header strip \
        --swiftversion 6.0.3
else
    echo "SwiftFormat not found. Please install with: brew install swiftformat"
    exit 1
fi

# Run SwiftLint auto-correct
echo "\nRunning SwiftLint auto-correct..."
if command -v swiftlint &> /dev/null; then
    swiftlint --fix "$ERRORS_DIR"
else
    echo "SwiftLint not found. Please install with: brew install swiftlint"
    exit 1
fi

# Run SwiftLint to check remaining issues
echo "\nChecking remaining issues..."
swiftlint lint "$ERRORS_DIR"

echo "\nScript completed. Please review changes before committing."
