# Agent Documentation

**Shared AI agent instructions for GPU scheduling across research projects**

## 🎯 Purpose

This repository contains standardized documentation for AI coding agents (Claude Code, OpenAI Codex, etc.) to understand how to submit GPU training jobs across your infrastructure.

## 📦 What's Included

- **AGENTS.md** - Main instructions file that AI agents read
- **gpu_manager/** - Detailed guides for training and optimization

## 🚀 Installation

### Option 1: Git Submodule (Recommended)

**Keeps docs synced with updates:**

```bash
cd ~/Research/your-project
git submodule add git@github.com:YOUR_USERNAME/agent-docs.git agent-docs
git commit -m "Add agent documentation submodule"
```

Then create a symlink in your project root:
```bash
ln -s agent-docs/AGENTS.md .claude.md
```

**To update docs in all projects:**
```bash
cd ~/Research/your-project
git submodule update --remote agent-docs
```

### Option 2: Direct Clone

**Simpler but requires manual updates:**

```bash
cd ~/Research/your-project
git clone git@github.com:YOUR_USERNAME/agent-docs.git agent-docs
ln -s agent-docs/AGENTS.md .claude.md
```

**To update:**
```bash
cd ~/Research/your-project/agent-docs
git pull
```

### Option 3: Copy Files

**For projects that don't need updates:**

```bash
cd ~/Research/your-project
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/agent-docs/main/AGENTS.md
mv AGENTS.md .claude.md
```

## 🤖 AI Agent Integration

### Claude Code
Automatically reads `.claude.md` when present in the project directory.

### OpenAI Codex / Cursor
Configure to read `.claude.md` or `AGENTS.md` as project context.

### Other Agents
Point them to read `AGENTS.md` for GPU scheduling instructions.

## 📝 Usage

Once installed, AI agents in your project will automatically know how to:
- Submit GPU training jobs to the scheduler
- Choose appropriate resources (local-5090, Cynthia, Pikachu, della clusters)
- Configure SLURM QoS for queue priority
- Handle offline mode for SLURM compute nodes
- Optimize for LLMs with vLLM and Unsloth

## 🔄 Updating Documentation

To update agent docs across all projects:

**With submodules:**
```bash
# Update the source repo
cd /media/milkkarten/data/agent-docs-repo
git add . && git commit -m "Update docs" && git push

# Update in each project
cd ~/Research/your-project
git submodule update --remote agent-docs
git commit -am "Update agent docs"
```

**With clones:**
```bash
# Update each project individually
cd ~/Research/your-project/agent-docs
git pull
```

## 📚 Documentation Structure

```
agent-docs/
├── AGENTS.md                           ← Main agent instructions
├── README.md                           ← This file
└── gpu_manager/
    ├── TRAINING_AGENT_GUIDE.md        ← ML training best practices
    ├── LLM_OPTIMIZATION_GUIDE.md      ← vLLM, Unsloth, quantization
    └── GPU_MANAGER_REFERENCE.md       ← Quick reference
```

## 🛠️ Maintenance

**Maintained by:** GPU Manager system at `/media/milkkarten/data/gpu_manager`

**Update workflow:**
1. Make changes to source docs in `/media/milkkarten/data/gpu_manager/docs/`
2. Copy updated files to this repo
3. Commit and push
4. Projects using submodules automatically get updates

## 📖 Full Documentation

Complete GPU Manager documentation: `/media/milkkarten/data/gpu_manager/docs/INDEX.md`
