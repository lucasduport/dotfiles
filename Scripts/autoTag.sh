#!/bin/sh

show_help() {
    echo "Usage: $0 <directory> [tag-message] [-p pattern] [-f tag-name]"
    echo
    echo "Arguments:"
    echo "  directory       The directory containing files to be processed."
    echo "  tag-message     (Optional) Custom tag message for the commit and tag."
    echo "Options:"
    echo "  -p pattern      Pattern for generating the tag name (e.g., assistants-kafka-*)."
    echo "  -f tag-name     Force a specific tag name."
    echo "  -h, --help      Display this help message and exit."
    echo
    echo "Features:"
    echo "  1. Verifies the provided directory exists."
    echo "  2. Shows a git status summary for the provided directory."
    echo "  3. Optionally adds a tag with an incremented tag number."
    echo "  4. Allows custom commit and tag messages."
    echo "  5. Supports pattern-based tag generation."
    echo "  6. Allows forcing a specific tag name."
}

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

DIRECTORY=""
TAG_MESSAGE=""
PATTERN=""
FORCE_TAG=""

while [ $# -gt 0 ]; do
    case "$1" in
        -p)
            shift
            PATTERN="$1"
            ;;
        -f)
            shift
            FORCE_TAG="$1"
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)

            if [ -z "$DIRECTORY" ]; then
                DIRECTORY="$1"
            elif [ -z "$TAG_MESSAGE" ]; then
                TAG_MESSAGE="$1"
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

if [ ! -d "$DIRECTORY" ]; then
    echo "$0 takes a valid directory as argument"
    exit 1
fi

# Check if eza is installed
if command -v eza >/dev/null 2>&1; then
    eza --git-ignore -T --icons=always --git "$DIRECTORY"
else
    # Fallback to tree command and filter out gitignored files
    git ls-files -co --exclude-standard --directory "$DIRECTORY" | tree -if --fromfile -
fi
echo

# Generate tag message and tag name
if [ -z "$TAG_MESSAGE" ]; then
    exercise="$(basename "$DIRECTORY" | sed "s|/||")"
    if [ -z "$FORCE_TAG" ]; then
        tagnumber="$(git tag | grep -c -- "${PATTERN%-*}-")"
        tagnumber=$(( tagnumber + 1 ))
        TAG_MESSAGE="${PATTERN%-*}: tag number ${tagnumber}"
        TAG_NAME="${PATTERN%-*}-${tagnumber}"
    else
        TAG_NAME="$FORCE_TAG"
        TAG_MESSAGE="Forced tag: $FORCE_TAG"
    fi
else
    TAG_NAME="$TAG_MESSAGE"
fi

echo "Tag message: $TAG_MESSAGE"
echo "Tag name: $TAG_NAME"

printf "\nPlease confirm if you want to proceed with adding and tagging changes [y/N]: "
read CONFIRM
case "$CONFIRM" in
    [yY] | [yY][eE][sS])
        ;;
    *)
        echo "Operation cancelled."
        exit 1
        ;;
esac

# Stage the changes for the specified directory
git add "$DIRECTORY"

git commit -m "$TAG_MESSAGE"
git tag -m "$TAG_MESSAGE" "$TAG_NAME"

git push --follow-tags

