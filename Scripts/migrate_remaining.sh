#!/bin/bash

# Migration script for remaining UmbraCore components
# This script migrates remaining components from rBUM to UmbraCore

set -e  # Exit on error

# Colour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source and destination paths
SOURCE_ROOT="/Users/mpy/CascadeProjects/rBUM/Core"
CORE_ROOT="/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraCore"
TEST_ROOT="/Users/mpy/CascadeProjects/UmbraCore/Tests"

# Create necessary directories
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p "$CORE_ROOT"/{Models,Protocols,Services,Errors,Extensions,Logging}/{Performance,Security,Maintenance}
mkdir -p "$TEST_ROOT"/{Mocks,XPCTests,CoreTests}

# File lists
declare -a PERFORMANCE_MODELS=(
    "Sources/Models/PerformanceAlert.swift"
    "Sources/Models/PerformanceMetrics.swift"
    "Sources/Models/ResourceUsage.swift"
    "Sources/Models/SystemResources.swift"
    "Sources/Models/OperationThresholds.swift"
)

declare -a SECURITY_MODELS=(
    "Sources/Models/SecurityMetrics.swift"
    "Sources/Models/SecurityOperation.swift"
    "Sources/Models/SecurityOperationRecorder.swift"
    "Sources/Models/SecurityOperationStatus.swift"
    "Sources/Models/SecurityOperationType.swift"
    "Sources/Models/SecuritySimulator.swift"
)

declare -a MAINTENANCE_MODELS=(
    "Sources/Models/MaintenanceSchedule.swift"
    "Sources/Models/MaintenanceTaskPriority.swift"
    "Sources/Models/LockMetrics.swift"
)

declare -a ADDITIONAL_MODELS=(
    "Sources/Models/BackupTypes.swift"
    "Sources/Models/DiscoveredRepository.swift"
    "Sources/Models/KeychainCredentials.swift"
    "Sources/Models/Notifications.swift"
    "Sources/Models/PreparedCommand.swift"
    "Sources/Models/ProgressTracker.swift"
    "Sources/Models/ResticError.swift"
    "Sources/Models/SidebarItem.swift"
    "Sources/Models/Snapshot.swift"
)

declare -a ERRORS=(
    "Sources/Errors/SandboxError.swift"
)

declare -a TEST_FILES=(
    "Tests/Mocks/MockLogger.swift"
    "Tests/Mocks/MockResticXPCService.swift"
    "Tests/XPCTests/ResticXPCServiceTests.swift"
)

# Function to copy files with verification
copy_files() {
    local category=$1
    local dest_dir=$2
    shift 2
    local files=("$@")
    local success_count=0
    local fail_count=0
    
    echo -e "${YELLOW}Copying $category...${NC}"
    
    for file in "${files[@]}"; do
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$dest_dir/$(basename "$file")")"
        
        if [ -f "$SOURCE_ROOT/$file" ]; then
            if cp -p "$SOURCE_ROOT/$file" "$dest_dir/$(basename "$file")"; then
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
echo -e "${GREEN}Starting remaining components migration...${NC}"
echo ""

copy_files "Performance Models" "$CORE_ROOT/Models/Performance" "${PERFORMANCE_MODELS[@]}"
copy_files "Security Models" "$CORE_ROOT/Models/Security" "${SECURITY_MODELS[@]}"
copy_files "Maintenance Models" "$CORE_ROOT/Models/Maintenance" "${MAINTENANCE_MODELS[@]}"
copy_files "Additional Models" "$CORE_ROOT/Models" "${ADDITIONAL_MODELS[@]}"
copy_files "Additional Errors" "$CORE_ROOT/Errors" "${ERRORS[@]}"
copy_files "Test Files" "$TEST_ROOT" "${TEST_FILES[@]}"

echo -e "${GREEN}Remaining components migration complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open the UmbraCore Xcode project"
echo "2. Add the migrated files to the appropriate targets"
echo "3. Update any import statements as needed"
echo "4. Build the project to verify the migration"
