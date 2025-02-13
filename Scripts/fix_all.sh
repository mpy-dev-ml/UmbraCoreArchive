#!/bin/bash

# Make scripts executable
chmod +x fix_swiftlint_violations.py

# Run SwiftFormat first
swiftformat ../Sources

# Run our custom SwiftLint fixes
./fix_swiftlint_violations.py

# Run SwiftLint to check remaining issues
swiftlint lint ../Sources
