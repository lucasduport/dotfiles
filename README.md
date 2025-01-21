# Dotfiles

Here are my dotfiles, managed with GNU Stow. This cheatsheet serves as a guide to using Stow effectively to manage dotfiles in a version-controlled repository.

---

## Prerequisites

- **GNU Stow**: Ensure Stow is installed on your system. On Arch Linux:
  ```bash
  sudo pacman -S stow
  ```
- **Version Control**: Use Git or another version control system to track changes.

## Directory Structure

Place your dotfiles in a directory structure where each set of dotfiles belongs to a folder representing an application or tool.# dotfiles



\`\`\`Example:

```
.dotfiles/  
├── bash/      # Contains bash configuration files
│   └── .bashrc
├── zsh/       # Contains zsh configuration files
│   └── .zshrc
├── i3/        # i3 window manager configuration
│   └── .config/i3/config
└── git/       # Git configuration
    └── .gitconfig
```

---

## Basic Commands

### Stow a Single Application's Dotfiles

To create symlinks from `~` to the dotfiles in a specific folder (e.g., `zsh`):

```bash
stow zsh
```

This command assumes you are running it from the `.dotfiles` directory and will link files from the `zsh` folder to your home directory.

### Stow Multiple Applications

To link dotfiles for multiple applications:

```bash
stow bash git zsh
```

### Unstow (Remove Symlinks) for an Application

To remove symlinks created for `zsh`:

```bash
stow -D zsh
```

### Restow (Refresh Symlinks)

Use this to update symlinks after modifying files:

```bash
stow -R zsh
```

---

## Customizing Behavior

### Specify Target Directory

By default, Stow uses the parent directory as the target (e.g., `~`). To specify a different target:

```bash
stow --target=/ptfiles
```

\`\`\`Common Practices

1. **Use One Folder Per Application**: [Group dotfiles by applicati](https://www.example.com)on for modularity.
2. **Exclude Files if Nee**\*\*[ded](https://www.youtube.com/watch?v=y6XCebnB9gs)\*\*[: Use ](https://www.youtube.com/watch?v=y6XCebnB9gs)[`.stow-local-ignore`](https://www.youtube.com/watch?v=y6XCebnB9gs)[ to ignore certa](https://www.youtube.com/watch?v=y6XCebnB9gs)in files.
   Example `.stow-local-ignore`:
   ```
   .DS_Store
   temp-config
   ```
3. **Backup Before Stowing**: Ensure a backup exists before overwriting existing configurations.Example Workflow

1) Clone your dotfiles repository:
   ```bash
   git clone https://github.com/username/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```
2) Stow your desired applications:
   ```bash
   stow bash git zsh
   ```
3) Commit changes as needed:
   ```bash
   git add .
   git commit -m "Update zsh configuration"
   ```

---

## Additional Resources

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Managing Dotfiles with Stow](https://www.example.com)
- https\://www\.youtube.com/watch?v=y6XCebnB9gs


