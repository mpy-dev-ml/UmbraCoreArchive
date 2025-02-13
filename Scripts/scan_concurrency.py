#!/usr/bin/env python3
"""
Scan Swift files for potential concurrency issues that might need @preconcurrency import.
This script looks for:
1. Files using Foundation
2. Files with async/await
3. Files with actors
4. Files using Sendable
"""

import os
import sys
from pathlib import Path

def should_check_file(file_path: str) -> bool:
    """Check if we should process this file."""
    return file_path.endswith('.swift') and not file_path.endswith('Tests.swift')

def scan_file(file_path: str) -> tuple[bool, list[str]]:
    """Scan a file for potential concurrency markers."""
    needs_attention = False
    reasons = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Check for Foundation import without @preconcurrency
        if 'import Foundation' in content and '@preconcurrency import Foundation' not in content:
            needs_attention = True
            reasons.append("Uses Foundation without @preconcurrency")
            
        # Check for async/await usage
        if 'async' in content or 'await' in content:
            needs_attention = True
            reasons.append("Uses async/await")
            
        # Check for actor usage
        if 'actor' in content:
            needs_attention = True
            reasons.append("Contains actor definition")
            
        # Check for Sendable usage
        if 'Sendable' in content:
            needs_attention = True
            reasons.append("Uses Sendable protocol")
    
    return needs_attention, reasons

def main():
    """Main entry point."""
    if len(sys.argv) != 2:
        print("Usage: scan_concurrency.py <source_directory>")
        sys.exit(1)
        
    source_dir = sys.argv[1]
    if not os.path.isdir(source_dir):
        print(f"Error: {source_dir} is not a directory")
        sys.exit(1)
    
    files_to_update = []
    
    # Walk through all Swift files
    for root, _, files in os.walk(source_dir):
        for file in files:
            if should_check_file(file):
                full_path = os.path.join(root, file)
                needs_attention, reasons = scan_file(full_path)
                
                if needs_attention:
                    rel_path = os.path.relpath(full_path, source_dir)
                    files_to_update.append((rel_path, reasons))
    
    # Print results
    if files_to_update:
        print("\nFiles that may need @preconcurrency or other concurrency updates:")
        print("=" * 80)
        for file_path, reasons in sorted(files_to_update):
            print(f"\n{file_path}:")
            for reason in reasons:
                print(f"  - {reason}")
    else:
        print("\nNo files found that need concurrency updates.")

if __name__ == '__main__':
    main()
