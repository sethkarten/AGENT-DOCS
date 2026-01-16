# Agent Documentation File Map

**Complete index of all agent guides and documentation**

---

## 📋 Quick Start Files

| File | Purpose | Use Case |
|------|---------|----------|
| **AGENTS.md** | Main entry point for all AI agents | OpenAI Codex, Cursor, generic agents |
| **CLAUDE.md** | Main entry point for Claude Code | Claude Code (identical to AGENTS.md) |
| **FILE_MAP.md** | This file - Complete documentation index | Finding the right guide for your task |
| **README.md** | Installation and setup instructions | Setting up the repo in projects |
| **QUICK_START.md** | Step-by-step deployment guide | First-time setup |

---

## 🖥️ GPU & Training Guides

**Location:** `training/`

### Core GPU Scheduling

| File | Lines | Purpose |
|------|-------|---------|
| **GPU_MANAGER_REFERENCE.md** | 74 | Quick reference for GPU job submission |
| **TRAINING_AGENT_GUIDE.md** | 661 | ML training best practices, SLURM QoS, offline mode |
| **LLM_OPTIMIZATION_GUIDE.md** | 564 | vLLM inference, Unsloth training, quantization |
| **TRAINING_LOOP.md** | 650+ | Systematic experimentation workflow (hypothesis → test → full run → iterate) |

**When to use:**
- Submitting training jobs to GPU clusters
- Optimizing LLM inference or fine-tuning
- Understanding SLURM resource allocation
- Setting up offline mode for compute nodes
- Running systematic ML experiments with monitoring

**Key topics covered:**
- ✅ Resource selection (local-5090, Cynthia, Pikachu, della clusters)
- ✅ SLURM QoS priority (1h/24h/72h time limits)
- ✅ CPU/RAM allocation (12 CPUs, 100GB per GPU)
- ✅ Training loop workflow (hypothesis → test → full run → iterate)
- ✅ Real-time monitoring (error detection, GPU utilization, performance tracking)
- ✅ vLLM (10-20x faster inference)
- ✅ Unsloth (2-5x faster training)
- ✅ Quantization strategies (4-bit, 8-bit, GPTQ, AWQ)
- ✅ Autonomous job watchers
- ✅ GPU-specific configurations

---

## ✍️ Writing & Research Agents

**Location:** `writing/`

### Core Writing System

| File | Size | Purpose |
|------|------|---------|
| **STYLE_GUIDE.md** | 13KB | NeurIPS-quality academic writing principles |
| **WRITING_ASSISTANT.md** | 13KB | Orchestrator for drafting papers from notes to submission |
| **WRITING_LOOP.md** | 24KB | Systematic review loop for polishing complete drafts |

**When to use:**
- Writing academic papers (NeurIPS, ICML, ICLR style)
- Need formal, scholarly prose
- Want structured feedback and iteration
- Iterative improvement of paper drafts

---

### Content Development Agents

| File | Size | Purpose |
|------|------|---------|
| **AGENT_SECTION_WRITER.md** | 9KB | Write individual sections with proper structure |
| **AGENT_RELATED_WORK.md** | 7KB | Position paper in literature, find related work |
| **AGENT_CLAIM_EVIDENCE_MAP.md** | 8KB | Map claims to supporting evidence |
| **AGENT_EXPERIMENT_GAP.md** | 8KB | Identify missing experiments before running them |

**When to use:**
- Drafting introduction, methods, results sections
- Writing related work section
- Ensuring claims are backed by evidence
- Planning experiments strategically

---

### Verification & Quality Agents

| File | Size | Purpose |
|------|------|---------|
| **AGENT_CITATION_CHECK.md** | 6KB | Verify citations are accurate and properly formatted |
| **AGENT_CLAIM_VERIFY.md** | 6KB | Check that claims match paper content |
| **AGENT_SPELLCHECK.md** | 6KB | Advanced spell/grammar checking for academic text |
| **AGENT_LLM_DETECTOR.md** | 5KB | Detect LLM-generated text patterns |

**When to use:**
- Pre-submission verification
- Ensuring citation accuracy
- Catching writing quality issues
- Making text less detectable as AI-generated

---

### Visual & Presentation Agents

| File | Size | Purpose |
|------|------|---------|
| **AGENT_FIGURE_PLANNER.md** | 9KB | Plan effective figures and tables |
| **AGENT_VISUAL.md** | 7KB | Visual design guidance for figures |
| **figure_analysis_agent.md** | 4KB | Analyze existing figures for improvements |

**When to use:**
- Planning what figures/tables to create
- Improving existing visualizations
- Ensuring figures support claims

---

### Review & Revision Agents

| File | Size | Purpose |
|------|------|---------|
| **AGENT_METAREVIEWER.md** | 7KB | Meta-review synthesizing reviewer feedback |
| **AGENT_IMPROVER.md** | 6KB | Improve writing quality iteratively |
| **AGENT_INTERVIEWER.md** | 6KB | Interview-style clarification of paper content |
| **REVIEWER_POOL.md** | 15KB | Simulated reviewer personas for feedback |

**When to use:**
- Post-submission: Addressing reviewer comments
- Pre-submission: Getting simulated reviews
- Iterative improvement of drafts

---

### Supporting Agents

| File | Size | Purpose |
|------|------|---------|
| **citation_verification_agent.md** | 3KB | Lightweight citation checker |

---

## 🔄 Maintenance Scripts

| File | Purpose |
|------|---------|
| **update_from_source.sh** | Sync docs from GPU Manager source |
| **install_to_project.sh** | Install to individual projects |

---

## 📚 Usage Patterns

### For GPU Training Projects

```bash
# Reference these files:
1. CLAUDE.md / AGENTS.md          # Main entry point
2. training/TRAINING_AGENT_GUIDE.md  # Training workflow
3. training/LLM_OPTIMIZATION_GUIDE.md  # If using LLMs
```

### For Academic Writing Projects

```bash
# Reference these files:
1. CLAUDE.md / AGENTS.md          # Main entry point
2. writing/STYLE_GUIDE.md          # Writing principles
3. writing/WRITING_ASSISTANT.md    # Orchestration
4. writing/WRITING_LOOP.md           # Review process
5. Specific agents as needed      # See sections above
```

### For Mixed Projects (Training + Writing Papers)

```bash
# Reference all sections:
1. CLAUDE.md / AGENTS.md          # Main entry point
2. This file (FILE_MAP.md)        # Navigate to needed guides
3. training/* for training
4. writing/* for paper writing
```

---

## 🎯 Quick Decision Tree

**"What guide do I need?"**

```
Are you...
├─ Running GPU experiments?
│  └─ See training/ section above
│
├─ Writing an academic paper?
│  ├─ Just starting / have notes?
│  │  └─ WRITING_ASSISTANT.md
│  │
│  ├─ Have complete draft to polish?
│  │  └─ WRITING_LOOP.md
│  │
│  ├─ Need to write specific section?
│  │  └─ AGENT_SECTION_WRITER.md
│  │
│  ├─ Planning experiments?
│  │  └─ AGENT_EXPERIMENT_GAP.md
│  │
│  ├─ Planning figures?
│  │  └─ AGENT_FIGURE_PLANNER.md
│  │
│  ├─ Checking citations?
│  │  └─ AGENT_CITATION_CHECK.md
│  │
│  └─ Addressing reviewer feedback?
│     └─ AGENT_METAREVIEWER.md
│
└─ Both GPU training AND paper writing?
   └─ Reference both training/ and writing/ as needed
```

---

## 📊 Statistics

**Total Documentation:**
- **25 files** (~1,900 lines total)
- **GPU Guides:** 3 files (1,299 lines)
- **Writing Guides:** 19 files (~600+ lines)
- **Meta Docs:** 3 files (README, QUICK_START, FILE_MAP)

**Coverage:**
- ✅ GPU scheduling and training optimization
- ✅ Academic paper writing (NeurIPS style)
- ✅ Research workflow automation
- ✅ Quality verification and review

---

## 🔗 Integration

**How agents discover this map:**

1. Agent reads `.claude.md` → Points to `CLAUDE.md` or `AGENTS.md`
2. CLAUDE.md/AGENTS.md → References `FILE_MAP.md` for complete guide index
3. Agent finds relevant guide in FILE_MAP.md
4. Agent reads specific guide(s) for detailed instructions

**In practice:**
```bash
cd ~/Research/your-project
cat .claude.md              # Symlinks to agent-docs/CLAUDE.md
                            # CLAUDE.md references FILE_MAP.md
                            # Agent can navigate to any specific guide
```

---

**Last Updated:** 2026-01-15
**Repository:** https://github.com/YOUR_USERNAME/agent-docs
**Maintained by:** GPU Manager + Writing Assistant systems
