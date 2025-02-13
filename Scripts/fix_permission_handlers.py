#!/usr/bin/env python3
"""
Script to fix SwiftLint violations in Permission Handlers.
Handles:
- Adding explicit deinit methods
- Fixing line lengths
- Adding consistent spacing in switch cases
- Adding explicit type annotations
"""

import os
import re
from typing import List, Tuple

HANDLERS_DIR = "/Users/mpy/CascadeProjects/UmbraCore/Sources/UmbraCore/Services/Permission/Handlers"

def find_swift_files(directory: str) -> List[str]:
    """Find all Swift files in the given directory recursively."""
    swift_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".swift"):
                swift_files.append(os.path.join(root, file))
    return swift_files

def add_deinit_method(content: str) -> str:
    """Add deinit method if missing in the class."""
    if "deinit" not in content and "class" in content:
        # Find the last closing brace of the class
        last_brace = content.rstrip().rfind("}")
        if last_brace != -1:
            deinit_method = "\n    // MARK: - Deinitialization\n\n    deinit {\n        logger.debug(\"Deinitializing \(String(describing: self))\")\n    }\n"
            return content[:last_brace] + deinit_method + content[last_brace:]
    return content

def fix_line_length(content: str, max_length: int = 100) -> str:
    """Break long lines into multiple lines."""
    lines = content.split("\n")
    fixed_lines = []
    
    for line in lines:
        if len(line) <= max_length:
            fixed_lines.append(line)
            continue
            
        # Handle long function declarations
        if "func" in line and "(" in line and ")" in line:
            parts = re.split(r"(\(|\))", line)
            indent = len(line) - len(line.lstrip())
            current_line = " " * indent
            
            for part in parts:
                if len(current_line + part) > max_length and current_line.strip():
                    fixed_lines.append(current_line)
                    current_line = " " * (indent + 4) + part
                else:
                    current_line += part
            
            if current_line.strip():
                fixed_lines.append(current_line)
        else:
            fixed_lines.append(line)
    
    return "\n".join(fixed_lines)

def add_switch_case_spacing(content: str) -> str:
    """Add consistent spacing between switch cases."""
    lines = content.split("\n")
    in_switch = False
    last_was_case = False
    fixed_lines = []
    
    for line in lines:
        stripped = line.strip()
        if "switch" in stripped:
            in_switch = True
        elif in_switch and "}" in stripped and not stripped.startswith("case"):
            in_switch = False
            
        if in_switch and stripped.startswith("case"):
            if last_was_case:
                fixed_lines.append("")
            last_was_case = True
        else:
            last_was_case = False
            
        fixed_lines.append(line)
    
    return "\n".join(fixed_lines)

def add_explicit_types(content: str) -> str:
    """Add explicit type annotations to properties."""
    lines = content.split("\n")
    fixed_lines = []
    
    for line in lines:
        if "let" in line or "var" in line:
            # Skip if already has type annotation or is a closure
            if ":" in line or "=" not in line or "{" in line:
                fixed_lines.append(line)
                continue
                
            # Find the type from the right side of the assignment
            parts = line.split("=")
            if len(parts) != 2:
                fixed_lines.append(line)
                continue
                
            left = parts[0].strip()
            right = parts[1].strip()
            
            # Infer type from common patterns
            inferred_type = None
            if right.startswith("\""):
                inferred_type = "String"
            elif right.isdigit():
                inferred_type = "Int"
            elif right in ["true", "false"]:
                inferred_type = "Bool"
            elif right.startswith("[") and right.endswith("]"):
                if right == "[]":
                    inferred_type = "[Any]"
                else:
                    inferred_type = f"[{right[1:-1].split(',')[0].strip()}]"
            
            if inferred_type:
                fixed_lines.append(f"{left}: {inferred_type} = {right}")
            else:
                fixed_lines.append(line)
        else:
            fixed_lines.append(line)
    
    return "\n".join(fixed_lines)

def process_file(file_path: str) -> None:
    """Process a single Swift file to fix all violations."""
    print(f"Processing {file_path}...")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Apply fixes
    content = add_deinit_method(content)
    content = fix_line_length(content)
    content = add_switch_case_spacing(content)
    content = add_explicit_types(content)
    
    # Write back to file
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"Completed processing {file_path}")

def main():
    """Main function to process all Swift files."""
    swift_files = find_swift_files(HANDLERS_DIR)
    for file_path in swift_files:
        process_file(file_path)
    print("Completed processing all files")

if __name__ == "__main__":
    main()
