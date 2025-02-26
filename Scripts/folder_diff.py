import os
import hashlib
import argparse
from pathlib import Path
from typing import Dict, Set, Tuple, List
import shutil
import math
import difflib
import sys

def get_file_hash(file_path: str) -> str:
    """
    Calculate MD5 hash of a file.
    
    Args:
        file_path: Path to the file
        
    Returns:
        MD5 hash as a hexadecimal string
    """
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def scan_directory(directory: str) -> Dict[str, str]:
    """
    Recursively scan a directory and create a dictionary of relative paths to file hashes.
    
    Args:
        directory: Path to the directory to scan
        
    Returns:
        Dictionary mapping relative file paths to their MD5 hashes
    """
    file_hashes = {}
    base_path = Path(directory)
    
    for root, _, files in os.walk(directory):
        for file in files:
            full_path = os.path.join(root, file)
            rel_path = str(Path(full_path).relative_to(base_path))
            file_hashes[rel_path] = get_file_hash(full_path)
            
    return file_hashes

def compare_directories(dir1: str, dir2: str) -> Tuple[Set[str], Set[str], Set[str]]:
    """
    Compare two directories and identify files that are unique to each directory
    and files with the same path but different content.
    
    Args:
        dir1: Path to the first directory
        dir2: Path to the second directory
        
    Returns:
        Tuple of sets containing:
        - Files only in dir1
        - Files only in dir2
        - Files with the same path but different content
    """
    files1 = scan_directory(dir1)
    files2 = scan_directory(dir2)
    
    # Files unique to each directory
    files_only_in_dir1 = set(files1.keys()) - set(files2.keys())
    files_only_in_dir2 = set(files2.keys()) - set(files1.keys())
    
    # Files with the same path but different content
    files_with_diff_content = {
        file for file in set(files1.keys()) & set(files2.keys())
        if files1[file] != files2[file]
    }
    
    return files_only_in_dir1, files_only_in_dir2, files_with_diff_content

def is_binary_file(file_path: str) -> bool:
    """
    Check if a file is binary by reading the first 4KB and looking for null bytes.
    
    Args:
        file_path: Path to the file
        
    Returns:
        True if the file is likely binary, False otherwise
    """
    try:
        with open(file_path, 'rb') as f:
            chunk = f.read(4096)
            if b'\x00' in chunk:
                return True
            
            # Also check if it's not a valid text file
            try:
                chunk.decode('utf-8')
                return False
            except UnicodeDecodeError:
                return True
    except:
        return True

def show_file_diff(file_path: str, dir1: str, dir2: str) -> List[str]:
    """
    Generate a unified diff between two files.
    
    Args:
        file_path: Relative path to the file
        dir1: Path to the first directory
        dir2: Path to the second directory
        
    Returns:
        List of diff lines
    """
    file1 = os.path.join(dir1, file_path)
    file2 = os.path.join(dir2, file_path)
    
    # Check if either file is binary
    if is_binary_file(file1) or is_binary_file(file2):
        return ["Binary files differ"]
    
    try:
        with open(file1, 'r', encoding='utf-8') as f1, open(file2, 'r', encoding='utf-8') as f2:
            lines1 = f1.readlines()
            lines2 = f2.readlines()
            
            diff = difflib.unified_diff(
                lines1, lines2,
                fromfile=f"a/{file_path}",
                tofile=f"b/{file_path}",
                lineterm=''
            )
            
            return list(diff)
    except UnicodeDecodeError:
        return ["Failed to decode file as text"]
    except Exception as e:
        return [f"Error comparing files: {str(e)}"]

def visualize_differences(dir1_name: str, dir2_name: str, 
                         only_in_dir1: Set[str], only_in_dir2: Set[str], 
                         modified: Set[str]) -> None:
    """
    Visualize the differences between two directories using ASCII art.
    
    Args:
        dir1_name: Name of the first directory
        dir2_name: Name of the second directory
        only_in_dir1: Set of files only in the first directory
        only_in_dir2: Set of files only in the second directory
        modified: Set of files modified between the directories
    """
    # Get terminal width
    terminal_width = shutil.get_terminal_size().columns
    
    # Calculate counts
    count_only_in_dir1 = len(only_in_dir1)
    count_only_in_dir2 = len(only_in_dir2)
    count_modified = len(modified)
    total_count = count_only_in_dir1 + count_only_in_dir2 + count_modified
    
    if total_count == 0:
        print("\nNo differences found - directories are identical.\n")
        return
    
    # Calculate percentages
    percent_only_in_dir1 = (count_only_in_dir1 / total_count) * 100
    percent_only_in_dir2 = (count_only_in_dir2 / total_count) * 100
    percent_modified = (count_modified / total_count) * 100
    
    # Print summary header
    print("\n" + "=" * terminal_width)
    print(f"DIRECTORY COMPARISON SUMMARY: {dir1_name} vs {dir2_name}")
    print("=" * terminal_width)
    
    # Print stats
    print(f"\nTotal differences: {total_count} files")
    print(f"- Only in {dir1_name}: {count_only_in_dir1} files ({percent_only_in_dir1:.1f}%)")
    print(f"- Only in {dir2_name}: {count_only_in_dir2} files ({percent_only_in_dir2:.1f}%)")
    print(f"- Modified files: {count_modified} files ({percent_modified:.1f}%)")
    
    # Visual bar chart
    bar_width = min(terminal_width - 10, 60)  # Leave some margin
    
    print("\nVisual Difference Distribution:")
    print("The bar below shows the relative proportion of each type of difference:")
    
    # Calculate bar segments
    dir1_segment = math.floor((count_only_in_dir1 / total_count) * bar_width)
    modified_segment = math.floor((count_modified / total_count) * bar_width)
    dir2_segment = bar_width - dir1_segment - modified_segment
    
    # Create color codes if terminal supports it
    try:
        # Red for files only in dir1
        red = "\033[91m"
        # Yellow for modified files
        yellow = "\033[93m"
        # Green for files only in dir2
        green = "\033[92m"
        # Reset color
        reset = "\033[0m"
        has_colors = True
    except:
        # Fallback if terminal doesn't support colors
        red = ""
        yellow = ""
        green = ""
        reset = ""
        has_colors = False
    
    # Create the colored or character-based bar
    if has_colors:
        # Color version
        bar = "│" + red + "■" * dir1_segment + reset + yellow + "■" * modified_segment + reset + green + "■" * dir2_segment + reset + "│"
    else:
        # Plain text version
        bar = "│" + "R" * dir1_segment + "M" * modified_segment + "A" * dir2_segment + "│"
    
    # Print the visualization
    print("-" * (bar_width + 2))
    print(bar)
    print("-" * (bar_width + 2))
    
    # Print the legend
    if has_colors:
        print(f"{red}■{reset} = Only in {dir1_name} ({count_only_in_dir1} files) | " +
              f"{yellow}■{reset} = Modified ({count_modified} files) | " +
              f"{green}■{reset} = Only in {dir2_name} ({count_only_in_dir2} files)")
    else:
        print(f"R = Only in {dir1_name} ({count_only_in_dir1} files) | " +
              f"M = Modified ({count_modified} files) | " +
              f"A = Only in {dir2_name} ({count_only_in_dir2} files)")
        
    # Print extent of differences
    if total_count > 0:
        # Count total files in both directories
        dir1_files = len(scan_directory(dir1_name))
        dir2_files = len(scan_directory(dir2_name))
        total_files = max(dir1_files, dir2_files)
        
        diff_percentage = (total_count / total_files) * 100 if total_files > 0 else 0
        
        print("\nOverall Difference Assessment:")
        print(f"- Total files examined: {total_files}")
        print(f"- Different files: {total_count} ({diff_percentage:.1f}%)")
        
        if diff_percentage < 5:
            print("MINIMAL DIFFERENCES: Less than 5% of files differ")
        elif diff_percentage < 15:
            print("MINOR DIFFERENCES: Between 5% and 15% of files differ")
        elif diff_percentage < 30:
            print("MODERATE DIFFERENCES: Between 15% and 30% of files differ")
        elif diff_percentage < 50:
            print("SIGNIFICANT DIFFERENCES: Between 30% and 50% of files differ")
        else:
            print("MAJOR DIFFERENCES: More than 50% of files differ")
            
    print("\n" + "=" * terminal_width + "\n")

def display_file_diffs(dir1: str, dir2: str, modified_files: Set[str]) -> None:
    """
    Display unified diffs for each modified file.
    
    Args:
        dir1: Path to the first directory
        dir2: Path to the second directory
        modified_files: Set of files that are modified
    """
    if not modified_files:
        print("No modified files to diff.")
        return
    
    terminal_width = shutil.get_terminal_size().columns
    
    for file_path in sorted(modified_files):
        print("\n" + "=" * terminal_width)
        print(f"DIFF: {file_path}")
        print("-" * terminal_width)
        
        diff_lines = show_file_diff(file_path, dir1, dir2)
        
        # Create color codes if terminal supports it
        try:
            # Colors for diff
            red = "\033[91m"      # for removed lines
            green = "\033[92m"    # for added lines
            cyan = "\033[96m"     # for diff header
            reset = "\033[0m"
            has_colors = True
        except:
            red = ""
            green = ""
            cyan = ""
            reset = ""
            has_colors = False
        
        for line in diff_lines:
            if has_colors:
                if line.startswith('---') or line.startswith('+++'):
                    print(f"{cyan}{line}{reset}")
                elif line.startswith('-'):
                    print(f"{red}{line}{reset}")
                elif line.startswith('+'):
                    print(f"{green}{line}{reset}")
                elif line.startswith('@@'):
                    print(f"{cyan}{line}{reset}")
                else:
                    print(line)
            else:
                print(line)
                
        print("-" * terminal_width)

def main():
    parser = argparse.ArgumentParser(description='Compare two directories recursively and visualize differences.')
    parser.add_argument('dir1', help='First directory to compare')
    parser.add_argument('dir2', help='Second directory to compare')
    parser.add_argument('--no-vis', action='store_true', help='Disable visualization')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show detailed file lists')
    parser.add_argument('--diff', '-d', action='store_true', help='Show content differences for modified files')
    args = parser.parse_args()
    
    # Check if directories exist
    if not os.path.isdir(args.dir1):
        print(f"Error: '{args.dir1}' is not a valid directory")
        return
    
    if not os.path.isdir(args.dir2):
        print(f"Error: '{args.dir2}' is not a valid directory")
        return
    
    print(f"Comparing {args.dir1} and {args.dir2}...")
    
    files_only_in_dir1, files_only_in_dir2, files_with_diff_content = compare_directories(args.dir1, args.dir2)
    
    # Visualize the differences
    if not args.no_vis:
        visualize_differences(
            args.dir1, 
            args.dir2, 
            files_only_in_dir1, 
            files_only_in_dir2, 
            files_with_diff_content
        )
    
    # Report detailed differences if verbose mode
    if args.verbose:
        if files_only_in_dir1:
            print(f"Files only in '{args.dir1}':")
            for file in sorted(files_only_in_dir1):
                print(f"  {file}")
            print()
        
        if files_only_in_dir2:
            print(f"Files only in '{args.dir2}':")
            for file in sorted(files_only_in_dir2):
                print(f"  {file}")
            print()
        
        if files_with_diff_content:
            print("Files with the same path but different content:")
            for file in sorted(files_with_diff_content):
                print(f"  {file}")
            print()
        
        if not (files_only_in_dir1 or files_only_in_dir2 or files_with_diff_content):
            print("The directories are identical.")
    
    # Show actual diffs if requested
    if args.diff:
        display_file_diffs(args.dir1, args.dir2, files_with_diff_content)
    
if __name__ == "__main__":
    main()
