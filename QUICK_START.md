# Quick Start

## 1️⃣ Create GitHub Repository

```bash
cd /media/milkkarten/data/agent-docs-repo

# Create repo on GitHub, then:
git remote add origin git@github.com:YOUR_USERNAME/agent-docs.git
git branch -M main
git push -u origin main
```

## 2️⃣ Update Installation Script

Edit `install_to_project.sh` and replace:
```bash
REPO_URL="git@github.com:YOUR_USERNAME/agent-docs.git"
```

## 3️⃣ Install to Your Projects

### Using Submodule (Recommended)

```bash
cd ~/Research/your-project
/media/milkkarten/data/agent-docs-repo/install_to_project.sh . submodule
git add .
git commit -m "Add agent documentation"
```

### Batch Install to All Projects

```bash
#!/bin/bash
for project in ~/Research/*/; do
    if [ -d "$project/.git" ]; then
        echo "Installing to $(basename $project)..."
        /media/milkkarten/data/agent-docs-repo/install_to_project.sh "$project" submodule
    fi
done
```

## 4️⃣ Test with Claude Code

```bash
cd ~/Research/your-project
cat .claude.md  # Should show agent instructions
claude -c       # Claude automatically reads .claude.md
```

Ask Claude: "How do I submit a GPU training job?"

## 🔄 Update Documentation

When GPU Manager docs change:

```bash
# 1. Update this repo
cd /media/milkkarten/data/agent-docs-repo
./update_from_source.sh
git add . && git commit -m "Update docs" && git push

# 2. Update in projects (if using submodules)
cd ~/Research/your-project
git submodule update --remote agent-docs
git commit -am "Update agent docs"
```

## 📊 File Overview

| File | Purpose |
|------|---------|
| `AGENTS.md` | Main instructions read by AI agents |
| `README.md` | Human-readable setup guide |
| `gpu_manager/*.md` | Detailed guides for training/optimization |
| `update_from_source.sh` | Sync from GPU Manager source |
| `install_to_project.sh` | Install to individual projects |

## 🎯 Benefits

✅ **Version controlled** - Track doc changes over time
✅ **Single source of truth** - One repo, many projects
✅ **Easy updates** - Git submodule or pull
✅ **Multi-agent support** - Works with Claude, Codex, etc.
✅ **Automatic discovery** - `.claude.md` symlink
