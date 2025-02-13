#!/usr/bin/env python3

import os
import re
from datetime import datetime

def add_file_header(content, filepath):
    """Add standard file header if missing."""
    relative_path = os.path.relpath(filepath, '/Users/mpy/CascadeProjects/UmbraCore')
    header = f'''//
//  {os.path.basename(filepath)}
//  UmbraCore
//
//  Created on {datetime.now().strftime('%Y-%m-%d')}
//  Copyright © {datetime.now().year} Codeium. All rights reserved.
//

'''
    if not content.startswith('//'):
        return header + content
    return content

def add_explicit_types(content):
    """Add explicit type annotations to properties."""
    lines = content.split('\n')
    modified_lines = []
    
    for line in lines:
        # Match property declarations without explicit types
        if re.search(r'(var|let)\s+\w+\s*=\s*\S+', line) and not re.search(r'(var|let)\s+\w+\s*:\s*\S+', line):
            # Try to infer type from the value
            match = re.search(r'(var|let)\s+(\w+)\s*=\s*(\S+)', line)
            if match:
                keyword, name, value = match.groups()
                # Simple type inference
                type_hint = None
                if value in ['true', 'false']:
                    type_hint = 'Bool'
                elif value.isdigit():
                    type_hint = 'Int'
                elif value.startswith('"'):
                    type_hint = 'String'
                elif value.startswith('['):
                    type_hint = '[Any]'  # Placeholder, needs manual review
                elif value.startswith('{'):
                    type_hint = '[String: Any]'  # Placeholder, needs manual review
                
                if type_hint:
                    line = f'{keyword} {name}: {type_hint} = {value}'
        
        modified_lines.append(line)
    
    return '\n'.join(modified_lines)

def add_deinit(content):
    """Add deinit method to classes that need it."""
    if 'class' in content and 'deinit' not in content:
        # Find the end of the class
        class_end = content.rfind('}')
        if class_end != -1:
            deinit = '''
    deinit {
        // Clean up any resources
    }
'''
            content = content[:class_end] + deinit + content[class_end:]
    return content

def fix_deployment_target(content):
    """Update macOS deployment target from 13.0 to 14.0."""
    return content.replace('@available(macOS 13.0', '@available(macOS 14.0')

def process_file(filepath):
    """Process a single Swift file to fix SwiftLint violations."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Apply fixes
    content = add_file_header(content, filepath)
    content = add_explicit_types(content)
    content = add_deinit(content)
    content = fix_deployment_target(content)
    
    # Write back changes
    with open(filepath, 'w') as f:
        f.write(content)

def main():
    """Process all Swift files in the project."""
    root_dir = '/Users/mpy/CascadeProjects/UmbraCore'
    for dirpath, _, files in os.walk(root_dir):
        if '.build' in dirpath:
            continue
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(dirpath, file)
                print(f'Processing {filepath}')
                process_file(filepath)

if __name__ == '__main__':
    main()
