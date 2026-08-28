#!/usr/bin/env bash
# Markdown validation script using markdownlint-cli
#
# Usage:
#   ./validate_markdown.sh <file_or_directory>
#   ./validate_markdown.sh <file_or_directory> --fix
#
# This script validates markdown files using markdownlint-cli with GFM-optimized rules.
# If markdownlint is not installed, it will provide installation instructions.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/markdownlint-config.json"

MARKDOWNLINT=()
if command -v markdownlint &> /dev/null; then
    MARKDOWNLINT=(markdownlint)
elif [ -x "./node_modules/.bin/markdownlint" ]; then
    MARKDOWNLINT=("./node_modules/.bin/markdownlint")
elif command -v npx &> /dev/null && npx --no-install markdownlint --version &> /dev/null; then
    MARKDOWNLINT=(npx --no-install markdownlint)
else
    echo "❌ markdownlint-cli is not installed"
    echo ""
    echo "To install in the target project after approval:"
    echo "  npm install --save-dev markdownlint-cli"
    echo ""
    echo "Or install globally after approval:"
    echo "  npm install -g markdownlint-cli"
    echo ""
    exit 1
fi

# Check if target is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file_or_directory> [--fix]"
    echo ""
    echo "Examples:"
    echo "  $0 README.md          # Validate a single file"
    echo "  $0 docs/              # Validate all markdown in a directory"
    echo "  $0 README.md --fix    # Validate and auto-fix issues"
    exit 1
fi

TARGET="$1"
FIX_FLAG=""

if [ "$2" == "--fix" ]; then
    FIX_FLAG="--fix"
    echo "🔧 Running in fix mode - will auto-correct issues where possible"
    echo ""
fi

# Run markdownlint
echo "🔍 Validating markdown: $TARGET"
echo ""

if "${MARKDOWNLINT[@]}" --config "$CONFIG_FILE" $FIX_FLAG "$TARGET"; then
    echo ""
    echo "✅ All markdown files are valid!"
    exit 0
else
    echo ""
    echo "❌ Markdown validation failed. See errors above."
    echo ""
    echo "Tip: Run with --fix flag to auto-correct some issues:"
    echo "  $0 $TARGET --fix"
    exit 1
fi
