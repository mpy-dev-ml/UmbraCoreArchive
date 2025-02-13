#!/bin/bash

# Directory containing permission handlers
HANDLERS_DIR="/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraCore/Services/Permission/Handlers"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Running SwiftFormat...${NC}"
swiftformat "$HANDLERS_DIR" --swiftversion 5.9.2

echo -e "${YELLOW}Step 2: Running custom fixes...${NC}"
python3 "$(dirname "$0")/fix_permission_handlers.py"

echo -e "${YELLOW}Step 3: Running SwiftLint to verify fixes...${NC}"
swiftlint lint "$HANDLERS_DIR"

echo -e "${GREEN}All steps completed!${NC}"
