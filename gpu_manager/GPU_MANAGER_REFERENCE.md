# GPU Manager Quick Reference

> **Copy this file to your project's root directory** to have GPU scheduling reference available!

## 🚀 Submit a Job

```bash
curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "repo": "git@github.com:user/repo.git",
    "branch": "main",
    "script": "train.py",
    "args": ["--epochs", "100"],
    "gpu_count": 1,
    "gpu_memory_min_gb": 48,
    "time_limit_hours": 4
  }'
```

## 📊 Available Resources

- **local-5090**: 2x 5090 (32GB) - Instant, no VPN
- **Cynthia**: 8x A6000 Ada (48GB) - Instant, Mac-VPN required
- **Pikachu**: 8x A6000 (48GB) - Instant, Mac-VPN required
- **della-ailab**: B200 (141GB) - SLURM queue, Mac-VPN required
- **della-pli**: H100 (80GB) - SLURM queue, Mac-VPN required
- **della-a100**: A100 (80GB) - SLURM queue, Mac-VPN required

## 🔑 Key Parameters

- `script`: `.py` (Python) or `.sh` (bash) - auto-detected
- `gpu_count`: 1, 2, 4, or 8 GPUs
- `gpu_memory_min_gb`: 32 (5090), 48 (A6000), 80 (H100/A100), 141 (B200)
- `time_limit_hours`: Shorter = higher priority (<1h best)

### SLURM Resource Allocation
- **12 CPUs per GPU** (auto-allocated)
- **100GB RAM per GPU** (auto-allocated)
- Example: 2 GPUs = 24 CPUs + 200GB RAM

## ⚠️ Important Notes

### **Script Types**
- **Python (.py)**: Auto-installs dependencies via `uv`
- **Bash (.sh)**: Runs directly, skips Python setup

### **SLURM Clusters (della-*)**
Compute nodes have **NO internet access**. Pre-install dependencies:
```bash
ssh della-gpu "cd /scratch/gpfs/CHIJ/milkkarten/your-project && \
  uv venv .venv && source .venv/bin/activate && \
  uv pip install -r requirements.txt"
```
Then submit your job - it will use the pre-installed venv.

### **Network Requirements**
- Remote resources require Mac-VPN proxy (`milkkartenVPN.local`)
- Test: `ping milkkartenVPN.local` and `ssh Cynthia hostname`
- Only `local-5090` works without VPN

## 📖 Full Documentation

Located at: `/media/milkkarten/data/gpu_manager/docs/`

- [INDEX.md](INDEX.md) - Documentation index
- [CLAUDE.md](CLAUDE.md) - Quick reference (detailed)
- [AGENT_GUIDE.md](AGENT_GUIDE.md) - Complete API guide
- [REPO_SETUP.md](REPO_SETUP.md) - Setup & troubleshooting
- [NETWORK_ARCHITECTURE.md](NETWORK_ARCHITECTURE.md) - Network topology
- [MCP_SETUP.md](MCP_SETUP.md) - Claude Code integration

## 🌐 Quick Links

- Dashboard: http://localhost:8080
- API: http://localhost:8080/api/resources
- Check status: `curl http://localhost:8080/api/jobs/{job_id}`
- View logs: `curl http://localhost:8080/api/jobs/{job_id}/logs`
