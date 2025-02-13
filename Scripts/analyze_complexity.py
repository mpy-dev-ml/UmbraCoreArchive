#!/usr/bin/env python3

import os
import sys
import re
from collections import defaultdict
from dataclasses import dataclass
from typing import Dict, List, Set

@dataclass
class FileMetrics:
    path: str
    line_count: int
    type_count: int
    function_count: int
    complexity_score: float
    lint_issues: int

def count_types(content: str) -> int:
    """Count class, struct, and enum declarations."""
    type_patterns = [
        r'\bclass\s+\w+',
        r'\bstruct\s+\w+',
        r'\benum\s+\w+',
        r'\bprotocol\s+\w+'
    ]
    return sum(len(re.findall(pattern, content)) for pattern in type_patterns)

def count_functions(content: str) -> int:
    """Count function declarations."""
    func_pattern = r'\bfunc\s+\w+'
    return len(re.findall(func_pattern, content))

def calculate_complexity(content: str) -> float:
    """Calculate a complexity score based on various metrics."""
    # Count nesting levels
    nesting_score = len(re.findall(r'\{', content)) * 0.1
    
    # Count conditional statements
    conditionals = len(re.findall(r'\b(if|guard|switch|while|for)\b', content)) * 0.2
    
    # Count force unwrapping and force casting
    force_unwrap = len(re.findall(r'!(?!\=)', content)) * 0.3
    force_cast = len(re.findall(r'as!', content)) * 0.3
    
    # Count complex patterns
    complex_patterns = [
        (r'try\?', 0.2),  # Optional try
        (r'try!', 0.4),   # Force try
        (r'\?\.', 0.1),   # Optional chaining
        (r'\?\?', 0.2),   # Nil coalescing
        (r'@escaping', 0.3),  # Escaping closures
        (r'\bclosure\b', 0.2),  # Explicit closure usage
        (r'\binit\?', 0.2),  # Failable initializers
        (r'\bdeinit\b', 0.3),  # Deinitializers
        (r'@objc\b', 0.2),  # Objective-C interop
        (r'\bextension\b', 0.1),  # Extensions
    ]
    
    pattern_score = sum(len(re.findall(pattern, content)) * weight 
                       for pattern, weight in complex_patterns)
    
    return nesting_score + conditionals + force_unwrap + force_cast + pattern_score

def should_analyze_file(file_path: str) -> bool:
    """Determine if a file should be analyzed."""
    excluded_dirs = {'.build', '.git', 'Tests', 'Examples', 'Documentation'}
    
    # Check if file is in excluded directory
    parts = file_path.split(os.sep)
    if any(part in excluded_dirs for part in parts):
        return False
    
    # Only analyze Swift source files
    return file_path.endswith('.swift')

def analyze_swift_files(root_dir: str) -> List[FileMetrics]:
    metrics = []
    lint_issues = defaultdict(int)
    
    # First parse SwiftLint report if it exists
    lint_report = os.path.join(root_dir, 'swiftlint_report.txt')
    if os.path.exists(lint_report):
        with open(lint_report, 'r') as f:
            for line in f:
                if 'warning: ' in line or 'error: ' in line:
                    file_path = line.split(':')[0]
                    lint_issues[file_path] += 1
    
    # Analyze Swift files
    for root, _, files in os.walk(root_dir):
        for file in files:
            file_path = os.path.join(root, file)
            if not should_analyze_file(file_path):
                continue
                
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                    
                metrics.append(FileMetrics(
                    path=os.path.relpath(file_path, root_dir),
                    line_count=len(content.splitlines()),
                    type_count=count_types(content),
                    function_count=count_functions(content),
                    complexity_score=calculate_complexity(content),
                    lint_issues=lint_issues.get(file_path, 0)
                ))
            except Exception as e:
                print(f"Error processing {file_path}: {e}", file=sys.stderr)
    
    return metrics

def generate_report(metrics: List[FileMetrics]) -> None:
    # Sort by complexity score + lint issues
    metrics.sort(key=lambda x: (x.complexity_score + x.lint_issues * 0.5), reverse=True)
    
    print("\nRefactoring Priority Report")
    print("=========================\n")
    
    print("Top 10 Files Requiring Attention:")
    print("--------------------------------")
    for m in metrics[:10]:
        print(f"\n{m.path}")
        print(f"  Lines: {m.line_count}")
        print(f"  Types: {m.type_count}")
        print(f"  Functions: {m.function_count}")
        print(f"  Complexity Score: {m.complexity_score:.2f}")
        print(f"  Lint Issues: {m.lint_issues}")
    
    print("\nSummary Statistics:")
    print("------------------")
    total_lines = sum(m.line_count for m in metrics)
    total_types = sum(m.type_count for m in metrics)
    total_functions = sum(m.function_count for m in metrics)
    total_issues = sum(m.lint_issues for m in metrics)
    
    print(f"Total Files: {len(metrics)}")
    print(f"Total Lines: {total_lines}")
    print(f"Total Types: {total_types}")
    print(f"Total Functions: {total_functions}")
    print(f"Total Lint Issues: {total_issues}")
    
    # Generate recommendations
    print("\nRefactoring Recommendations:")
    print("---------------------------")
    for m in metrics[:5]:
        if m.complexity_score > 5 or m.lint_issues > 0:
            print(f"\n{m.path}:")
            if m.line_count > 300:
                print("- Consider splitting into smaller files")
            if m.type_count > 3:
                print("- Consider separating types into different files")
            if m.function_count > 10:
                print("- Consider extracting some functions into extensions")
            if m.lint_issues > 0:
                print("- Address SwiftLint issues")
            if m.complexity_score > 10:
                print("- High complexity score indicates need for simplification")
                print("  * Look for opportunities to reduce nesting")
                print("  * Consider breaking down complex functions")
                print("  * Review force unwrapping and force casting usage")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 analyze_complexity.py <root_directory>")
        sys.exit(1)
    
    root_dir = sys.argv[1]
    metrics = analyze_swift_files(root_dir)
    generate_report(metrics)
