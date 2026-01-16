#!/bin/bash
# Update agent-docs from GPU Manager source
# Run this script when GPU Manager docs are updated

SOURCE_DIR="/media/milkkarten/data/gpu_manager/docs"
DEST_DIR="/media/milkkarten/data/agent-docs-repo"

echo "Updating agent documentation from source..."

# Copy main agent instructions from GPU Manager
cp "$SOURCE_DIR/CLAUDE.md" "$DEST_DIR/AGENTS.md"
sed -i 's/Claude Code Instructions/AI Agent Instructions/' "$DEST_DIR/AGENTS.md"

# Ensure FILE_MAP reference is in AGENTS.md
if ! grep -q "FILE_MAP.md" "$DEST_DIR/AGENTS.md"; then
    # Add FILE_MAP reference at top
    sed -i '1a\\n> **📋 Complete Guide Index:** See [FILE_MAP.md](FILE_MAP.md) for all available documentation\n> - GPU & Training: `gpu_manager/` directory\n> - Writing & Research: `agents/` directory\n\n---' "$DEST_DIR/AGENTS.md"
fi

# Add writing guides reference if not present
if ! grep -q "Writing & Research:" "$DEST_DIR/AGENTS.md"; then
    echo -e "\n**Writing & Research:**\n- Style Guide: \`agents/STYLE_GUIDE.md\` - NeurIPS academic writing\n- Writing Assistant: \`agents/WRITING_ASSISTANT.md\` - Drafting papers\n- Review Loop: \`agents/AGENT_LOOP.md\` - Polishing drafts\n- See [FILE_MAP.md](FILE_MAP.md) for complete agent index (19 writing guides)" >> "$DEST_DIR/AGENTS.md"
fi

echo "✓ Updated AGENTS.md"

# Create CLAUDE.md as duplicate
cp "$DEST_DIR/AGENTS.md" "$DEST_DIR/CLAUDE.md"
echo "✓ Updated CLAUDE.md (duplicate of AGENTS.md)"

# Copy detailed GPU guides
cp "$SOURCE_DIR/TRAINING_AGENT_GUIDE.md" "$DEST_DIR/training/"
cp "$SOURCE_DIR/LLM_OPTIMIZATION_GUIDE.md" "$DEST_DIR/training/"
cp "$SOURCE_DIR/GPU_MANAGER_REFERENCE.md" "$DEST_DIR/training/"
echo "✓ Updated training/ guides"

echo ""
echo "✅ Agent docs updated from GPU Manager source!"
echo ""
echo "Writing guides (writing/) are NOT updated - maintained separately"
echo ""
echo "Next steps:"
echo "  cd $DEST_DIR"
echo "  git add ."
echo "  git commit -m 'Update GPU Manager documentation'"
echo "  git push"
