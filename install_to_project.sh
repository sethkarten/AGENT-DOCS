#!/bin/bash
# Install agent docs to a project
# Usage: ./install_to_project.sh /path/to/project [mode]
# Modes: submodule (default), clone, copy

PROJECT_DIR="${1:-.}"
MODE="${2:-submodule}"
REPO_URL="git@github.com:sethkarten/AGENT-DOCS.git"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory '$PROJECT_DIR' does not exist"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1
echo "Installing agent docs to: $(pwd)"
echo "Mode: $MODE"
echo ""

case $MODE in
    submodule)
        echo "Adding as git submodule..."
        git submodule add "$REPO_URL" agent-docs 2>/dev/null || {
            echo "Submodule already exists, updating..."
            git submodule update --init --remote agent-docs
        }

        # Create symlink
        if [ ! -L ".claude.md" ]; then
            ln -s agent-docs/AGENTS.md .claude.md
            echo "✓ Created .claude.md symlink"
        else
            echo "✓ .claude.md symlink already exists"
        fi

        echo ""
        echo "✓ Agent docs installed as submodule"
        echo "  To update: git submodule update --remote agent-docs"
        ;;

    clone)
        echo "Cloning agent-docs repository..."
        if [ -d "agent-docs" ]; then
            echo "agent-docs already exists, pulling updates..."
            cd agent-docs && git pull && cd ..
        else
            git clone "$REPO_URL" agent-docs
        fi

        # Create symlink
        if [ ! -L ".claude.md" ]; then
            ln -s agent-docs/AGENTS.md .claude.md
            echo "✓ Created .claude.md symlink"
        else
            echo "✓ .claude.md symlink already exists"
        fi

        echo ""
        echo "✓ Agent docs cloned"
        echo "  To update: cd agent-docs && git pull"
        ;;

    copy)
        echo "Copying AGENTS.md to .claude.md..."
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cp "$SCRIPT_DIR/AGENTS.md" .claude.md
        echo "✓ Copied AGENTS.md to .claude.md"
        echo ""
        echo "Note: Updates require manual copying"
        ;;

    *)
        echo "Error: Unknown mode '$MODE'"
        echo "Valid modes: submodule, clone, copy"
        exit 1
        ;;
esac

echo ""
echo "Agent documentation ready! AI agents can now:"
echo "  - Submit GPU training jobs"
echo "  - Access detailed guides in agent-docs/training/"
echo "  - Use writing guides in agent-docs/writing/"
