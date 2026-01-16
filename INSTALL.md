# Simple Installation Guide

## For a Single Project

```bash
cd ~/Research/your-project
git clone git@github.com:YOUR_USERNAME/agent-docs.git
cp agent-docs/CLAUDE.md .claude.md
```

Done! Claude Code will now read `.claude.md` automatically.

---

## For All Projects

```bash
for project in ~/Research/*/; do
    if [ -d "$project/.git" ]; then
        cd "$project"

        # Clone or update
        if [ -d "agent-docs" ]; then
            cd agent-docs && git pull && cd ..
        else
            git clone git@github.com:YOUR_USERNAME/agent-docs.git
        fi

        # Copy main file
        cp agent-docs/CLAUDE.md .claude.md

        echo "✓ $(basename $project)"
    fi
done
```

---

## What Gets Installed

After installation, your project has:

```
your-project/
├── .claude.md                  ← Claude Code reads this
├── agent-docs/                 ← Full documentation repo
│   ├── CLAUDE.md              ← Main instructions
│   ├── FILE_MAP.md            ← Index of all guides
│   ├── training/           ← GPU scheduling guides
│   │   ├── TRAINING_AGENT_GUIDE.md
│   │   ├── LLM_OPTIMIZATION_GUIDE.md
│   │   └── GPU_MANAGER_REFERENCE.md
│   └── writing/                ← Writing guides (19 files)
│       ├── STYLE_GUIDE.md
│       ├── WRITING_ASSISTANT.md
│       └── ...
```

---

## Updating Later

```bash
cd ~/Research/your-project/agent-docs
git pull
cd ..
cp agent-docs/CLAUDE.md .claude.md  # Optional: re-copy if main file changed
```

---

## For Other AI Platforms

If using OpenAI Codex, Cursor, or other agents:

```bash
cp agent-docs/AGENTS.md .agents.md  # Instead of CLAUDE.md
```

---

## Minimal Install (Just Main File)

If you don't want the full repo:

```bash
cd ~/Research/your-project
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/agent-docs/main/CLAUDE.md
mv CLAUDE.md .claude.md
```

This gives you the main instructions only. Full guides won't be available locally.

---

## Verification

Check that it worked:

```bash
cat .claude.md  # Should show GPU Manager instructions
```

Test with Claude Code:

```bash
claude -c  # Claude automatically reads .claude.md
```

Ask Claude: "How do I submit a GPU training job?"
