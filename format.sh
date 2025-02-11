#!/bin/bash

echo "Running SwiftFormat..."
swiftformat . --verbose

echo "Running SwiftLint to verify changes..."
swiftlint --reporter csv > swiftlint_report_after.csv

echo "Comparing SwiftLint reports..."
if [ -f swiftlint_report.csv ]; then
    echo "Before formatting:"
    grep "Attributes" swiftlint_report.csv | wc -l
    echo "After formatting:"
    grep "Attributes" swiftlint_report_after.csv | wc -l
else
    echo "No previous SwiftLint report found for comparison"
fi
