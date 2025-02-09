#!/bin/bash

# Migration script for UmbraCore XPC components
# This script migrates XPC-related components from rBUM to UmbraCore

set -e  # Exit on error

# Colour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source and destination paths
SOURCE_ROOT="/Users/mpy/CascadeProjects/rBUM/Core/Sources"
DEST_ROOT="/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraXPC"

# Verify source exists
if [ ! -d "$SOURCE_ROOT" ]; then
    echo -e "${RED}Error: Source directory $SOURCE_ROOT does not exist${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p "$DEST_ROOT"/{Models,Protocols,Services,Errors}

# File lists
declare -a XPC_MODELS=(
    "Models/XPCCommandConfig.swift"
    "Models/XPCConnectionState.swift"
    "Models/XPCHealthStatus.swift"
    "Models/XPCMessageQueue.swift"
)

declare -a XPC_PROTOCOLS=(
    "Protocols/RepositoryDiscoveryXPCProtocol.swift"
    "Protocols/ResticXPCProtocol.swift"
    "Protocols/ResticXPCServiceProtocol.swift"
)

declare -a XPC_SERVICES=(
    "Services/ResticXPCService.swift"
    "Services/ResticXPCService+Commands.swift"
    "Services/ResticXPCService+Connection.swift"
    "Services/ResticXPCService+ErrorHandling.swift"
    "Services/ResticXPCService+HealthCheck.swift"
    "Services/ResticXPCService+Operations.swift"
    "Services/ResticXPCService+Queue.swift"
    "Services/ResticXPCService+Resources.swift"
    "Services/ResticXPCService+Validation.swift"
    "Services/XPCConnectionManager.swift"
    "Services/XPCHealthMonitor.swift"
)

declare -a XPC_ERRORS=(
    "Errors/ResticXPCError.swift"
)

# Function to copy files with verification
copy_files() {
    local category=$1
    shift
    local files=("$@")
    local success_count=0
    local fail_count=0
    
    echo -e "${YELLOW}Copying $category...${NC}"
    
    for file in "${files[@]}"; do
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$DEST_ROOT/$file")"
        
        if [ -f "$SOURCE_ROOT/$file" ]; then
            if cp -p "$SOURCE_ROOT/$file" "$DEST_ROOT/$file"; then
                echo -e "${GREEN}✓ Copied: $file${NC}"
                ((success_count++))
            else
                echo -e "${RED}✗ Failed to copy: $file${NC}"
                ((fail_count++))
            fi
        else
            echo -e "${RED}✗ Source file not found: $file${NC}"
            ((fail_count++))
        fi
    done
    
    echo -e "${GREEN}$category: Successfully copied $success_count files${NC}"
    if [ $fail_count -gt 0 ]; then
        echo -e "${RED}$category: Failed to copy $fail_count files${NC}"
    fi
    echo ""
}

# Main migration
echo -e "${GREEN}Starting XPC component migration...${NC}"
echo ""

copy_files "XPC Models" "${XPC_MODELS[@]}"
copy_files "XPC Protocols" "${XPC_PROTOCOLS[@]}"
copy_files "XPC Services" "${XPC_SERVICES[@]}"
copy_files "XPC Errors" "${XPC_ERRORS[@]}"

echo -e "${GREEN}XPC Migration complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open the UmbraCore Xcode project"
echo "2. Add the migrated XPC files to the appropriate targets"
echo "3. Update any import statements as needed"
echo "4. Build the project to verify the migration"
