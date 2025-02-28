import os
import hashlib
import click
from pathlib import Path
from typing import Dict, Set, Tuple, List, Optional
import shutil
import math
import difflib
import sys
from itertools import combinations

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
        click.echo("\nNo differences found - directories are identical.\n")
        return
    
    # Calculate percentages
    percent_only_in_dir1 = (count_only_in_dir1 / total_count) * 100
    percent_only_in_dir2 = (count_only_in_dir2 / total_count) * 100
    percent_modified = (count_modified / total_count) * 100
    
    # Print summary header
    click.echo("\n" + "=" * terminal_width)
    click.echo(f"DIRECTORY COMPARISON SUMMARY: {dir1_name} vs {dir2_name}")
    click.echo("=" * terminal_width)
    
    # Print stats
    click.echo(f"\nTotal differences: {total_count} files")
    click.echo(f"- Only in {dir1_name}: {count_only_in_dir1} files ({percent_only_in_dir1:.1f}%)")
    click.echo(f"- Only in {dir2_name}: {count_only_in_dir2} files ({percent_only_in_dir2:.1f}%)")
    click.echo(f"- Modified files: {count_modified} files ({percent_modified:.1f}%)")
    
    # Visual bar chart
    bar_width = min(terminal_width - 10, 60)  # Leave some margin
    
    click.echo("\nVisual Difference Distribution:")
    click.echo("The bar below shows the relative proportion of each type of difference:")
    
    # Calculate bar segments
    dir1_segment = math.floor((count_only_in_dir1 / total_count) * bar_width)
    modified_segment = math.floor((count_modified / total_count) * bar_width)
    dir2_segment = bar_width - dir1_segment - modified_segment
    
    # Create color codes if terminal supports it
    has_colors = not os.environ.get('NO_COLOR') and not os.environ.get('CLICOLOR') == '0'
    
    # Define colors
    red = click.style("■", fg="red") if has_colors else "R"
    yellow = click.style("■", fg="yellow") if has_colors else "M"
    green = click.style("■", fg="green") if has_colors else "A"
    
    # Create the bar
    bar = "│" + red * dir1_segment + yellow * modified_segment + green * dir2_segment + "│"
    
    # Print the visualization
    click.echo("-" * (bar_width + 2))
    click.echo(bar)
    click.echo("-" * (bar_width + 2))
    
    # Print the legend
    if has_colors:
        click.echo(f"{click.style('■', fg='red')} = Only in {dir1_name} ({count_only_in_dir1} files) | " +
                  f"{click.style('■', fg='yellow')} = Modified ({count_modified} files) | " +
                  f"{click.style('■', fg='green')} = Only in {dir2_name} ({count_only_in_dir2} files)")
    else:
        click.echo(f"R = Only in {dir1_name} ({count_only_in_dir1} files) | " +
                  f"M = Modified ({count_modified} files) | " +
                  f"A = Only in {dir2_name} ({count_only_in_dir2} files)")
        
    # Print extent of differences
    if total_count > 0:
        # Count total files in both directories
        dir1_files = len(scan_directory(dir1_name))
        dir2_files = len(scan_directory(dir2_name))
        total_files = max(dir1_files, dir2_files)
        
        diff_percentage = (total_count / total_files) * 100 if total_files > 0 else 0
        
        click.echo("\nOverall Difference Assessment:")
        click.echo(f"- Total files examined: {total_files}")
        click.echo(f"- Different files: {total_count} ({diff_percentage:.1f}%)")
        
        if diff_percentage < 5:
            click.echo("MINIMAL DIFFERENCES: Less than 5% of files differ")
        elif diff_percentage < 15:
            click.echo("MINOR DIFFERENCES: Between 5% and 15% of files differ")
        elif diff_percentage < 30:
            click.echo("MODERATE DIFFERENCES: Between 15% and 30% of files differ")
        elif diff_percentage < 50:
            click.echo("SIGNIFICANT DIFFERENCES: Between 30% and 50% of files differ")
        else:
            click.echo("MAJOR DIFFERENCES: More than 50% of files differ")
            
    click.echo("\n" + "=" * terminal_width + "\n")

def display_file_diffs(dir1: str, dir2: str, modified_files: Set[str]) -> None:
    """
    Display unified diffs for each modified file.
    
    Args:
        dir1: Path to the first directory
        dir2: Path to the second directory
        modified_files: Set of files that are modified
    """
    if not modified_files:
        click.echo("No modified files to diff.")
        return
    
    terminal_width = shutil.get_terminal_size().columns
    
    for file_path in sorted(modified_files):
        click.echo("\n" + "=" * terminal_width)
        click.echo(f"DIFF: {file_path}")
        click.echo("-" * terminal_width)
        
        diff_lines = show_file_diff(file_path, dir1, dir2)
        
        # Use Click styling for diff output
        for line in diff_lines:
            if line.startswith('---') or line.startswith('+++'):
                click.echo(click.style(line, fg='cyan'))
            elif line.startswith('-'):
                click.echo(click.style(line, fg='red'))
            elif line.startswith('+'):
                click.echo(click.style(line, fg='green'))
            elif line.startswith('@@'):
                click.echo(click.style(line, fg='cyan'))
            else:
                click.echo(line)
                
        click.echo("-" * terminal_width)

def read_directories_from_file(file_path: str) -> List[str]:
    """
    Read directory paths from a text file.
    
    Args:
        file_path: Path to the text file containing directory paths
        
    Returns:
        List of directory paths
    """
    directories = []
    try:
        with open(file_path, 'r') as f:
            directories = [line.strip() for line in f.readlines() if line.strip() and not line.strip().startswith('#')]
        
        # Validate that all directories exist
        for directory in directories:
            if not os.path.isdir(directory):
                click.echo(f"Warning: Directory '{directory}' does not exist and will be skipped.")
                directories.remove(directory)
                
        return directories
    except Exception as e:
        click.echo(f"Error reading directory list from {file_path}: {str(e)}", err=True)
        return []

def compare_directory_pair(dir1: str, dir2: str, no_vis: bool, verbose: bool, show_diff: bool) -> None:
    """
    Compare a pair of directories and display results based on options.
    
    Args:
        dir1: Path to the first directory
        dir2: Path to the second directory
        no_vis: If True, disable visualization
        verbose: If True, show detailed file lists
        show_diff: If True, show content differences for modified files
    """
    # Check if directories exist
    if not os.path.isdir(dir1):
        click.echo(f"Error: '{dir1}' is not a valid directory", err=True)
        return
    
    if not os.path.isdir(dir2):
        click.echo(f"Error: '{dir2}' is not a valid directory", err=True)
        return
    
    click.echo(f"Comparing {dir1} and {dir2}...")
    
    files_only_in_dir1, files_only_in_dir2, files_with_diff_content = compare_directories(dir1, dir2)
    
    # Visualize the differences
    if not no_vis:
        visualize_differences(
            dir1, 
            dir2, 
            files_only_in_dir1, 
            files_only_in_dir2, 
            files_with_diff_content
        )
    
    # Report detailed differences if verbose mode
    if verbose:
        if files_only_in_dir1:
            click.echo(f"Files only in '{dir1}':")
            for file in sorted(files_only_in_dir1):
                click.echo(f"  {file}")
            click.echo()
        
        if files_only_in_dir2:
            click.echo(f"Files only in '{dir2}':")
            for file in sorted(files_only_in_dir2):
                click.echo(f"  {file}")
            click.echo()
        
        if files_with_diff_content:
            click.echo("Files with the same path but different content:")
            for file in sorted(files_with_diff_content):
                click.echo(f"  {file}")
            click.echo()
        
        if not (files_only_in_dir1 or files_only_in_dir2 or files_with_diff_content):
            click.echo("The directories are identical.")
    
    # Show actual diffs if requested
    if show_diff:
        display_file_diffs(dir1, dir2, files_with_diff_content)

def compare_multiple_directories(directories: List[str], no_vis: bool, verbose: bool, show_diff: bool) -> None:
    """
    Compare multiple directories pairwise.
    
    Args:
        directories: List of directory paths
        no_vis: If True, disable visualization
        verbose: If True, show detailed file lists
        show_diff: If True, show content differences for modified files
    """
    if len(directories) < 2:
        click.echo("At least two directories are required for comparison.", err=True)
        return
    
    # Compare all pairs of directories
    for dir1, dir2 in combinations(directories, 2):
        compare_directory_pair(dir1, dir2, no_vis, verbose, show_diff)

@click.group(context_settings={"help_option_names": ["-h", "--help"]})
@click.version_option(version="1.1.0")
def cli():
    """Directory comparison tool that helps you analyze differences between directories."""
    pass

@cli.command()
@click.argument('dir1', type=click.Path(exists=True, file_okay=False, dir_okay=True, readable=True))
@click.argument('dir2', type=click.Path(exists=True, file_okay=False, dir_okay=True, readable=True))
@click.option('--no-vis', is_flag=True, help='Disable visualization')
@click.option('--verbose', '-v', is_flag=True, help='Show detailed file lists')
@click.option('--diff', '-d', is_flag=True, help='Show content differences for modified files')
def compare(dir1, dir2, no_vis, verbose, diff):
    """
    Compare two directories and show their differences.
    
    DIR1 is the path to the first directory to compare.
    DIR2 is the path to the second directory to compare.
    """
    compare_directory_pair(dir1, dir2, no_vis, verbose, diff)

@cli.command()
@click.argument('file_path', type=click.Path(exists=True, file_okay=True, dir_okay=False, readable=True))
@click.option('--no-vis', is_flag=True, help='Disable visualization')
@click.option('--verbose', '-v', is_flag=True, help='Show detailed file lists')
@click.option('--diff', '-d', is_flag=True, help='Show content differences for modified files')
def compare_from_file(file_path, no_vis, verbose, diff):
    """
    Compare directories listed in a text file.
    
    FILE_PATH is the path to a text file containing a list of directories to compare.
    Each directory should be on a separate line. Comments can be added using # character.
    """
    directories = read_directories_from_file(file_path)
    if directories:
        click.echo(f"Found {len(directories)} directories to compare.")
        compare_multiple_directories(directories, no_vis, verbose, diff)
    else:
        click.echo("No valid directories found in the file.", err=True)

@cli.command()
@click.argument('directories', nargs=-1, type=click.Path(exists=True, file_okay=False, dir_okay=True, readable=True))
@click.option('--no-vis', is_flag=True, help='Disable visualization')
@click.option('--verbose', '-v', is_flag=True, help='Show detailed file lists')
@click.option('--diff', '-d', is_flag=True, help='Show content differences for modified files')
def compare_multiple(directories, no_vis, verbose, diff):
    """
    Compare multiple directories pairwise.
    
    DIRECTORIES are two or more directory paths to compare.
    """
    if len(directories) < 2:
        click.echo("At least two directories are required for comparison.", err=True)
        return
    
    compare_multiple_directories(list(directories), no_vis, verbose, diff)

@cli.command()
def generate_sample_file():
    """Generate a sample directory list file."""
    sample_content = """# Directory comparison list
# Each line should contain a valid directory path
# Lines starting with # are treated as comments and ignored

/path/to/first/directory
/path/to/second/directory
/path/to/third/directory

# You can add as many directories as needed
# All directories will be compared pairwise
"""
    
    output_file = "directory_list_sample.txt"
    
    # Don't overwrite existing file without confirmation
    if os.path.exists(output_file):
        if not click.confirm(f"File '{output_file}' already exists. Overwrite?"):
            click.echo("Aborted.")
            return
    
    try:
        with open(output_file, 'w') as f:
            f.write(sample_content)
        click.echo(f"Sample file created: {output_file}")
    except Exception as e:
        click.echo(f"Error creating sample file: {str(e)}", err=True)

if __name__ == "__main__":
    cli()
