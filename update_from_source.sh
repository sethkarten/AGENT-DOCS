#!/bin/bash
# Update agent-docs from GPU Manager source
# Run this script when GPU Manager docs are updated

SOURCE_DIR="/media/milkkarten/data/gpu_manager/docs"
DEST_DIR="/media/milkkarten/data/agent-docs-repo"

echo "Updating agent documentation from source..."

# Copy main agent instructions
cp "$SOURCE_DIR/CLAUDE.md" "$DEST_DIR/AGENTS.md"
sed -i 's/Claude Code Instructions/AI Agent Instructions/' "$DEST_DIR/AGENTS.md"
echo "✓ Updated AGENTS.md"

# Copy detailed guides
cp "$SOURCE_DIR/TRAINING_AGENT_GUIDE.md" "$DEST_DIR/gpu_manager/"
cp "$SOURCE_DIR/LLM_OPTIMIZATION_GUIDE.md" "$DEST_DIR/gpu_manager/"
cp "$SOURCE_DIR/GPU_MANAGER_REFERENCE.md" "$DEST_DIR/gpu_manager/"
echo "✓ Updated gpu_manager/ guides"

echo ""
echo "Agent docs updated! Next steps:"
echo "  cd $DEST_DIR"
echo "  git add ."
echo "  git commit -m 'Update documentation'"
echo "  git push"
