#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting automated refactoring process...${NC}\n"

# Step 1: Run SwiftFormat
echo -e "${YELLOW}Running SwiftFormat...${NC}"
swiftformat . --config .swiftformat
if [ $? -eq 0 ]; then
    echo -e "${GREEN}SwiftFormat completed successfully${NC}\n"
else
    echo -e "${RED}SwiftFormat encountered errors${NC}\n"
    exit 1
fi

# Step 2: Run SwiftLint with auto-correct
echo -e "${YELLOW}Running SwiftLint auto-correct...${NC}"
swiftlint --fix
if [ $? -eq 0 ]; then
    echo -e "${GREEN}SwiftLint auto-correct completed successfully${NC}\n"
else
    echo -e "${RED}SwiftLint auto-correct encountered errors${NC}\n"
    exit 1
fi

# Step 3: Run SwiftLint to identify remaining issues
echo -e "${YELLOW}Running SwiftLint to identify remaining issues...${NC}"
swiftlint lint > swiftlint_report.txt
if [ $? -eq 0 ]; then
    echo -e "${GREEN}SwiftLint analysis completed successfully${NC}"
    echo -e "Report saved to swiftlint_report.txt\n"
else
    echo -e "${RED}SwiftLint analysis encountered errors${NC}\n"
    exit 1
fi

# Step 4: Generate summary report
echo -e "${YELLOW}Generating summary report...${NC}"
echo "SwiftLint Issues Summary" > refactoring_summary.txt
echo "======================" >> refactoring_summary.txt
echo "" >> refactoring_summary.txt

# Count issues by type
echo "Issues by Rule:" >> refactoring_summary.txt
grep "warning: " swiftlint_report.txt | cut -d: -f4 | sort | uniq -c | sort -nr >> refactoring_summary.txt
echo "" >> refactoring_summary.txt

# Count issues by file
echo "Issues by File:" >> refactoring_summary.txt
grep "warning: " swiftlint_report.txt | cut -d: -f1 | sort | uniq -c | sort -nr >> refactoring_summary.txt

echo -e "${GREEN}Summary report generated in refactoring_summary.txt${NC}\n"

# Step 5: Identify high-priority files
echo -e "${YELLOW}Identifying high-priority files for manual review...${NC}"
echo "" >> refactoring_summary.txt
echo "High Priority Files (>5 issues):" >> refactoring_summary.txt
grep "warning: " swiftlint_report.txt | cut -d: -f1 | sort | uniq -c | sort -nr | awk '$1 > 5' >> refactoring_summary.txt

echo -e "${GREEN}Refactoring process completed!${NC}"
