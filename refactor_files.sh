#!/bin/bash

# Define project root
PROJECT_DIR="UmbraCore/Sources/UmbraCore/"
BUILD_LOG="build_log.txt"
OUTPUT_REPORT="refactor_report.txt"

# Ensure the build log exists
if [ ! -f "$BUILD_LOG" ]; then
    echo "❌ Build log not found: $BUILD_LOG"
    exit 1
fi

# Clear previous report
> "$OUTPUT_REPORT"

# 1️⃣ Identify files with errors
echo "🔍 Identifying files with build issues..."
grep -Eo "(/Users/.+\.swift)" "$BUILD_LOG" | sort | uniq > affected_files.txt
echo "📝 Affected files list generated."

# 2️⃣ Identify major issues per file
echo "🔍 Analyzing errors per file..."
while IFS= read -r file; do
    echo "🔹 File: $file" >> "$OUTPUT_REPORT"
    grep -B 2 -A 2 "$file" "$BUILD_LOG" >> "$OUTPUT_REPORT"
    echo "---------------------------------" >> "$OUTPUT_REPORT"
done < affected_files.txt
echo "✅ Error analysis completed. Report saved in $OUTPUT_REPORT."

# Cleanup
echo "🛠 Cleaning up temporary files..."
rm affected_files.txt

# Notify completion
echo "🎉 Analysis complete! Open $OUTPUT_REPORT for details."

