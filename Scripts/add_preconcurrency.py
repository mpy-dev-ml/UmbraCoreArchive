#!/usr/bin/env python3
"""
Add @preconcurrency to Foundation imports in Swift files.
Also adds @unchecked Sendable where needed.
"""

import os
import sys
from pathlib import Path

def process_file(file_path: str) -> None:
    """Process a single Swift file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    modified = False
    new_lines = []
    
    for line in lines:
        if line.strip() == 'import Foundation':
            new_lines.append('@preconcurrency import Foundation\n')
            modified = True
        elif line.strip().startswith('class') and 'Sendable' in line and '@unchecked' not in line:
            # Add @unchecked Sendable for classes
            indent = line[:len(line) - len(line.lstrip())]
            new_lines.append(f'{indent}@unchecked\n')
            new_lines.append(line)
            modified = True
        else:
            new_lines.append(line)
    
    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"Updated {file_path}")

def main():
    """Main entry point."""
    if len(sys.argv) != 2:
        print("Usage: add_preconcurrency.py <source_directory>")
        sys.exit(1)
        
    source_dir = sys.argv[1]
    if not os.path.isdir(source_dir):
        print(f"Error: {source_dir} is not a directory")
        sys.exit(1)
    
    # Walk through all Swift files
    for root, _, files in os.walk(source_dir):
        for file in files:
            if file.endswith('.swift'):
                full_path = os.path.join(root, file)
                process_file(full_path)

if __name__ == '__main__':
    main()
