# Agent Documentation

**Shared AI agent instructions for GPU scheduling and academic writing**

## 🎯 Purpose

This repository contains standardized documentation for AI coding agents (Claude Code, OpenAI Codex, Cursor, etc.) to:
- Submit GPU training jobs across your infrastructure
- Write NeurIPS-quality academic papers
- Navigate comprehensive guides for both domains

## 📦 What's Included

### Core Entry Points
- **AGENTS.md** / **CLAUDE.md** - Main instructions file (identical, for different AI platforms)
- **FILE_MAP.md** - Complete index of all 25 guide files

### GPU & Training Guides (`gpu_manager/`)
- GPU job submission and scheduling
- SLURM resource allocation (12 CPUs, 100GB RAM per GPU)
- LLM optimization (vLLM, Unsloth, quantization)
- Training best practices and autonomous watchers

### Writing & Research Guides (`agents/`)
- NeurIPS academic writing style
- Paper drafting and review loops
- Citation verification
- Figure planning
- 19 specialized writing agents

## 🚀 Installation

### Simple Clone (Recommended)

**Clone the repo into your project:**

```bash
cd ~/Research/your-project
git clone git@github.com:YOUR_USERNAME/agent-docs.git
```

**Then copy the main file to your project root:**

```bash
# For Claude Code
cp agent-docs/CLAUDE.md .claude.md

# For OpenAI Codex / Cursor
cp agent-docs/AGENTS.md .agents.md
```

**To update later:**

```bash
cd ~/Research/your-project/agent-docs
git pull

# Then re-copy if you want the latest
cd ..
cp agent-docs/CLAUDE.md .claude.md
```

### Alternative: Direct File Copy

**If you don't want the full repo:**

```bash
cd ~/Research/your-project
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/agent-docs/main/CLAUDE.md
mv CLAUDE.md .claude.md
```

Note: You'll have all guides available in `agent-docs/` directory if you clone the full repo.

## 🤖 AI Agent Integration

### Claude Code
Automatically reads `.claude.md` when present in the project directory.

### OpenAI Codex / Cursor
Configure to read `.claude.md` or `AGENTS.md` as project context.

### Other Agents
Point them to read `AGENTS.md` for GPU scheduling instructions.

## 📝 Usage

Once installed, AI agents in your project will automatically know how to:

**For GPU Training:**
- Submit GPU training jobs to the scheduler
- Choose appropriate resources (local-5090, Cynthia, Pikachu, della clusters)
- Configure SLURM QoS for queue priority (1h/24h/72h)
- Handle offline mode for SLURM compute nodes
- Optimize for LLMs with vLLM and Unsloth

**For Academic Writing:**
- Write NeurIPS-quality formal prose
- Draft papers from notes to submission
- Verify citations and claims
- Plan effective figures and tables
- Navigate 19 specialized writing agents via FILE_MAP.md

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
├── AGENTS.md                           ← Main instructions (generic)
├── CLAUDE.md                           ← Main instructions (Claude Code)
├── FILE_MAP.md                         ← Complete index of all 25 guides
├── README.md                           ← This file
├── QUICK_START.md                      ← Setup guide
├── gpu_manager/                        ← GPU & training guides
│   ├── TRAINING_AGENT_GUIDE.md        ├─ ML training best practices (661 lines)
│   ├── LLM_OPTIMIZATION_GUIDE.md      ├─ vLLM, Unsloth, quantization (564 lines)
│   └── GPU_MANAGER_REFERENCE.md       └─ Quick reference (74 lines)
├── agents/                             ← Writing & research guides
│   ├── STYLE_GUIDE.md                 ├─ NeurIPS academic writing (13KB)
│   ├── WRITING_ASSISTANT.md           ├─ Drafting papers (13KB)
│   ├── AGENT_LOOP.md                  ├─ Review & polish (24KB)
│   ├── AGENT_SECTION_WRITER.md        ├─ Write sections
│   ├── AGENT_CITATION_CHECK.md        ├─ Verify citations
│   ├── AGENT_FIGURE_PLANNER.md        ├─ Plan figures
│   └── ... (13 more agents)           └─ See FILE_MAP.md
└── scripts/
    ├── update_from_source.sh          ← Sync GPU docs from source
    └── install_to_project.sh          ← Install to projects
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
