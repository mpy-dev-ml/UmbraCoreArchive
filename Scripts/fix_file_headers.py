#!/usr/bin/env python3
"""
Script to standardize file headers across the UmbraCore project.
"""

import os
import datetime
from typing import List, Optional

def get_relative_path(file_path: str, base_dir: str) -> str:
    """Get the relative path from the base directory."""
    return os.path.relpath(file_path, base_dir)

def create_file_header(file_path: str, base_dir: str) -> str:
    """Create a standardized file header."""
    relative_path = get_relative_path(file_path, base_dir)
    filename = os.path.basename(file_path)
    current_date = datetime.datetime.now().strftime("%Y-%m-%d")
    
    header = f"""//
// {filename}
// Sources/{relative_path}
//
// Created by mpy@umbracore on {current_date}
// Last updated by mpy@umbracore on {current_date}
//
// Copyright © 2025 UmbraCore. All rights reserved.
//

"""
    return header

def process_file(file_path: str, base_dir: str) -> None:
    """Process a single Swift file to update its header."""
    print(f"Processing {file_path}...")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove existing header comments
    lines = content.split('\n')
    while lines and (not lines[0].strip() or lines[0].startswith('//')):
        lines.pop(0)
    
    # Add new header
    new_content = create_file_header(file_path, base_dir) + '\n'.join(lines)
    
    # Write back to file
    with open(file_path, 'w') as f:
        f.write(new_content)
    
    print(f"Updated header for {file_path}")

def find_swift_files(directory: str) -> List[str]:
    """Find all Swift files in the given directory recursively."""
    swift_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".swift"):
                swift_files.append(os.path.join(root, file))
    return swift_files

def main():
    """Main function to process all Swift files."""
    base_dir = "/Users/mpy/CascadeProjects/UmbraCore"
    sources_dir = os.path.join(base_dir, "Sources")
    
    swift_files = find_swift_files(sources_dir)
    for file_path in swift_files:
        process_file(file_path, base_dir)
    
    print("Completed processing all files")

if __name__ == "__main__":
    main()
