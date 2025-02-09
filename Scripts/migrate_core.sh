#!/bin/bash

# Migration script for UmbraCore
# This script migrates core components from rBUM to UmbraCore

set -e  # Exit on error

# Colour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source and destination paths
SOURCE_ROOT="/Users/mpy/CascadeProjects/rBUM/Core/Sources"
DEST_ROOT="/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraCore"

# Verify source exists
if [ ! -d "$SOURCE_ROOT" ]; then
    echo -e "${RED}Error: Source directory $SOURCE_ROOT does not exist${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p "$DEST_ROOT"/{Models,Protocols,Services,Errors,Extensions,Logging}

# File lists
declare -a PROTOCOLS=(
    "Protocols/BackupServiceProtocol.swift"
    "Protocols/BookmarkServiceProtocol.swift"
    "Protocols/DateProviderProtocol.swift"
    "Protocols/FileManagerProtocol.swift"
    "Protocols/FileSearchServiceProtocol.swift"
    "Protocols/HealthCheckable.swift"
    "Protocols/KeychainServiceProtocol.swift"
    "Protocols/LoggingService.swift"
    "Protocols/NotificationCenterProtocol.swift"
    "Protocols/RepositoryServiceProtocol.swift"
    "Protocols/SecurityServiceProtocol.swift"
    "Protocols/StorageServiceProtocol.swift"
)

declare -a MODELS=(
    "Models/Repository.swift"
    "Models/RepositoryCredentials.swift"
    "Models/ProcessResult.swift"
    "Models/ResticSnapshot.swift"
    "Models/ResticCommand.swift"
    "Models/ProcessError.swift"
    "Models/SecurityScopedAccess.swift"
    "Models/RepositoryHealth.swift"
    "Models/RepositoryStatus.swift"
)

declare -a ERRORS=(
    "Errors/BookmarkError.swift"
    "Errors/KeychainError.swift"
    "Errors/RepositoryDiscoveryError.swift"
    "Errors/SecurityError.swift"
    "Errors/ServiceError.swift"
)

declare -a SERVICES=(
    "Services/KeychainService.swift"
    "Services/SecurityService.swift"
    "Services/RepositoryDiscoveryService.swift"
    "Services/LoggerFactory.swift"
    "Services/PermissionManager.swift"
)

declare -a EXTENSIONS=(
    "Extensions/FileManager+DiskSpace.swift"
)

declare -a LOGGING=(
    "Logging/LoggerProtocol.swift"
    "Logging/OSLogger.swift"
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
echo -e "${GREEN}Starting migration...${NC}"
echo ""

copy_files "Protocols" "${PROTOCOLS[@]}"
copy_files "Models" "${MODELS[@]}"
copy_files "Errors" "${ERRORS[@]}"
copy_files "Services" "${SERVICES[@]}"
copy_files "Extensions" "${EXTENSIONS[@]}"
copy_files "Logging" "${LOGGING[@]}"

echo -e "${GREEN}Migration complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open the UmbraCore Xcode project"
echo "2. Add the migrated files to the appropriate targets"
echo "3. Update any import statements as needed"
echo "4. Build the project to verify the migration"
