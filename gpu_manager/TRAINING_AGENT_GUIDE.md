# Training Agent Guide

**Autonomous ML Training Management** - Resource allocation, job monitoring, and intelligent resubmission for large-scale training runs.

---

## 🎯 Resource Usage Strategy

### **Priority Order for Training Jobs**

```
1. 🥇 AI Lab (della-ailab)     → Primary for large training runs
2. 🥈 Local 2x5090             → Quick experiments, small models
3. 🥉 Cynthia (fallback only)  → Use ONLY if ailab queue is stuck
```

### **Decision Matrix**

| Scenario | Use Resource | Reason |
|----------|--------------|--------|
| Large model (>7B params) | **AI Lab** | 141GB B200, highest memory |
| Small model (<1B params) | **local-5090** | Instant start, no queue |
| Medium model (1-7B params) | **AI Lab** | Better throughput than 5090 |
| AI Lab queue >4 hours | **Cynthia** | Avoid queue bottleneck |
| We have >5 jobs running | **Cynthia** | Fair usage, avoid hogging ailab |
| Quick debugging | **local-5090** | Instant feedback |
| Multi-GPU required (>2) | **AI Lab** | Up to 8x B200 |

### **When to Use Cynthia**

❌ **Don't default to Cynthia** - It's a fallback resource

✅ **Use Cynthia when**:
- AI Lab queue position hasn't moved in 3+ hours
- You already have 5+ jobs running on AI Lab
- AI Lab is down/unavailable
- Need 3-8 GPUs but AI Lab is full

**Check queue status**:
```bash
ssh della-gpu squeue -p ailab
# If your job is position >20 and hasn't moved in 3 hours → use Cynthia
```

---

## ⏱️ SLURM Time Limits & QoS Priority

**Job time limits automatically select SLURM QoS** for queue priority:

| Time Limit | SLURM QoS | Priority | Best For |
|------------|-----------|----------|----------|
| **≤ 1 hour** | `gpu-test` | 🔴 Highest | Debugging, quick tests, interactive work |
| **≤ 24 hours** | `gpu-short` | 🟡 Medium | Standard training runs (default) |
| **≤ 72 hours** | `gpu-medium` | 🟢 Lower | Long training runs, multi-day jobs |

### **Strategy**

```python
# Quick debugging → Use 1 hour for instant queue entry
"time_limit_hours": 1  # gpu-test QoS → Start immediately

# Normal training → Use 24 hours (good queue priority)
"time_limit_hours": 12  # gpu-short QoS → Reasonable wait

# Long training → Use up to 72 hours (lower priority)
"time_limit_hours": 48  # gpu-medium QoS → Longer wait
```

**Important**: If your job needs >1 hour but you want to debug:
- Submit with `time_limit_hours: 1` for quick start
- Implement checkpointing to resume if timeout
- Once working, resubmit with longer time limit

---

## 💾 SLURM Resource Allocation

**CPU and RAM are automatically allocated per GPU:**

| GPUs | CPUs | RAM | Example Use Case |
|------|------|-----|------------------|
| 1 | 12 | 100GB | Small models, debugging |
| 2 | 24 | 200GB | Medium models, distributed training |
| 4 | 48 | 400GB | Large models, multi-GPU training |
| 8 | 96 | 800GB | Very large models, full node training |

**Allocation Formula:**
- **12 CPUs per GPU** (fixed ratio)
- **100GB RAM per GPU** (fixed ratio)

**Example Job Submission:**
```json
{
  "gpu_count": 4,
  "gpu_memory_min_gb": 80,
  "time_limit_hours": 24
}
// ↓ SLURM automatically allocates:
// #SBATCH --gres=gpu:4
// #SBATCH --cpus-per-task=48  (4 GPUs × 12 CPUs)
// #SBATCH --mem=400G          (4 GPUs × 100GB)
```

**Why these ratios?**
- Prevents CPU bottlenecks during data loading
- Ensures sufficient RAM for model loading and preprocessing
- Matches typical GPU:CPU:RAM ratios on della clusters

---

## 🔧 Environment Setup

### **Python Environment**

**ALWAYS use `uv` Python** - No modules, no conda, no pip:

```bash
# ✅ Correct - uv handles everything
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt

# ❌ Wrong - Don't use module system
module load anaconda3  # NO!
module purge           # NO!
conda create ...       # NO!
```

### **SLURM-Specific: Offline Mode**

**AI Lab SLURM compute nodes have NO internet**. Pre-cache everything:

#### **1. HuggingFace Models**
```bash
# On login node (has internet):
ssh della-gpu
cd /scratch/gpfs/CHIJ/milkkarten/your-project

# Download model to cache
python << EOF
from transformers import AutoModel, AutoTokenizer
model_name = "meta-llama/Llama-2-7b-hf"
AutoModel.from_pretrained(model_name, cache_dir="./hf_cache")
AutoTokenizer.from_pretrained(model_name, cache_dir="./hf_cache")
EOF

# In your training script:
export HF_HOME=/scratch/gpfs/CHIJ/milkkarten/your-project/hf_cache
export TRANSFORMERS_OFFLINE=1
```

#### **2. Weights & Biases (wandb)**

**Option 1 - Offline mode**:
```python
# In your training script
import wandb
wandb.init(mode="offline")  # Logs saved locally

# After job completes, sync from login node:
# ssh della-gpu "cd /scratch/gpfs/CHIJ/milkkarten/your-project && wandb sync wandb/"
```

**Option 2 - Pre-authenticate** (better):
```bash
# On login node:
ssh della-gpu
wandb login  # Enter API key once

# In SLURM job script:
export WANDB_API_KEY=$(cat ~/.netrc | grep api.wandb.ai | awk '{print $6}')
export WANDB_MODE=online  # Will use cached auth
```

#### **3. Python Dependencies**
```bash
# Pre-install on login node (has internet):
ssh della-gpu "cd /scratch/gpfs/CHIJ/milkkarten/your-project && \
  uv venv .venv && \
  source .venv/bin/activate && \
  uv pip install transformers torch accelerate wandb datasets"
```

---

## 📁 SLURM Log Organization

**ALWAYS use a `logs/` folder** for SLURM output:

### **Directory Structure**
```
your-project/
├── train.py
├── requirements.txt
├── logs/                    ← SLURM logs here
│   ├── job_12345.out
│   ├── job_12345.err
│   ├── job_12346.out
│   └── job_12346.err
├── wandb/                   ← W&B logs
│   └── run-20260115/
└── checkpoints/             ← Model checkpoints
    └── checkpoint-1000/
```

### **SLURM Job Submission**
```bash
# Create logs directory first
mkdir -p logs

# Submit with proper log paths
sbatch --output=logs/job_%j.out --error=logs/job_%j.err train.slurm
```

### **GPU Manager Integration**

The GPU Manager automatically creates logs in the working directory. Structure:
```
/scratch/gpfs/CHIJ/milkkarten/your-project/
├── output.log               ← GPU Manager main log
├── .exit_code              ← Job exit status
├── slurm-JOBID.out         ← SLURM stdout (if configured)
├── slurm-JOBID.err         ← SLURM stderr (if configured)
└── logs/                   ← Your custom logs folder
    └── training.log
```

**Best Practice**: Configure your training script to write to `logs/`:
```python
import logging
import os

# Create logs directory
os.makedirs("logs", exist_ok=True)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/training.log'),
        logging.StreamHandler()
    ]
)
```

---

## 🤖 Training Agents (Autonomous Watchers)

Set up **two autonomous agents** to monitor training:

### **Agent 1: Job Failure Watcher** 🚨

**Purpose**: Detect failing jobs quickly and diagnose root cause

**How it works**:
1. Polls GPU Manager API every 2-5 minutes
2. Detects jobs in `failed` or `cancelled` state
3. Automatically investigates failure using hooks
4. Reports findings and suggests fixes

**Implementation**:

```python
#!/usr/bin/env python3
"""
Job Failure Watcher - Monitors for failing jobs and diagnoses issues
Usage: python job_failure_watcher.py
"""
import requests
import time
import subprocess
from datetime import datetime

GPU_MANAGER_API = "http://localhost:8080/api"
CHECK_INTERVAL = 120  # Check every 2 minutes

def check_jobs():
    """Check for failed jobs"""
    resp = requests.get(f"{GPU_MANAGER_API}/jobs?status=failed")
    failed_jobs = resp.json()

    resp = requests.get(f"{GPU_MANAGER_API}/jobs?status=cancelled")
    cancelled_jobs = resp.json()

    return failed_jobs + cancelled_jobs

def diagnose_failure(job):
    """Diagnose why a job failed using hooks"""
    job_id = job['id']
    resource = job['resource']

    # Get logs
    logs_resp = requests.get(f"{GPU_MANAGER_API}/jobs/{job_id}/logs")
    logs = logs_resp.text

    # Common failure patterns
    diagnostics = {
        "oom": "CUDA out of memory" in logs or "OutOfMemoryError" in logs,
        "import_error": "ImportError" in logs or "ModuleNotFoundError" in logs,
        "wandb_auth": "wandb: ERROR" in logs and "authentication" in logs.lower(),
        "internet": "Request failed after 3 retries" in logs,
        "timeout": job.get('time_limit_exceeded', False),
        "cuda_error": "CUDA error" in logs or "cudaGetDevice" in logs,
    }

    # Generate report
    report = f"""
╔══════════════════════════════════════════════════════════════╗
║  JOB FAILURE REPORT - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
╚══════════════════════════════════════════════════════════════╝

Job ID: {job_id}
Resource: {resource}
Script: {job['script']}
Status: {job['status']}

DIAGNOSTICS:
"""

    if diagnostics["oom"]:
        report += "\n❌ OUT OF MEMORY\n"
        report += "   → Reduce batch size\n"
        report += "   → Enable gradient checkpointing\n"
        report += "   → Use smaller model or request more GPU memory\n"

    if diagnostics["import_error"]:
        report += "\n❌ MISSING DEPENDENCY\n"
        report += "   → Pre-install dependencies on login node:\n"
        report += f"   ssh della-gpu 'cd {job['work_dir']} && uv pip install -r requirements.txt'\n"

    if diagnostics["internet"]:
        report += "\n❌ INTERNET ACCESS DENIED (SLURM compute node)\n"
        report += "   → Pre-download HuggingFace models on login node\n"
        report += "   → Set TRANSFORMERS_OFFLINE=1\n"
        report += "   → Use wandb offline mode or pre-authenticate\n"

    if diagnostics["wandb_auth"]:
        report += "\n❌ WANDB AUTHENTICATION FAILED\n"
        report += "   → Run 'ssh della-gpu wandb login' on login node\n"
        report += "   → Or use wandb.init(mode='offline')\n"

    if diagnostics["timeout"]:
        report += "\n⏱️  JOB TIMEOUT\n"
        report += "   → Increase time_limit_hours\n"
        report += "   → Or implement checkpointing to resume\n"

    if diagnostics["cuda_error"]:
        report += "\n❌ CUDA ERROR\n"
        report += "   → Check CUDA version compatibility\n"
        report += "   → Verify GPU availability\n"

    report += f"\n\nLAST 20 LINES OF LOGS:\n{'-'*60}\n"
    report += '\n'.join(logs.split('\n')[-20:])

    return report

def main():
    print("🤖 Job Failure Watcher Started")
    print(f"   Checking every {CHECK_INTERVAL}s for failed jobs...\n")

    seen_failures = set()

    while True:
        try:
            failed = check_jobs()

            for job in failed:
                job_id = job['id']

                # Skip if already reported
                if job_id in seen_failures:
                    continue

                print(f"\n🚨 FAILURE DETECTED: Job {job_id}")
                report = diagnose_failure(job)
                print(report)

                # TODO: Send notification (email, Slack, etc.)

                seen_failures.add(job_id)

            time.sleep(CHECK_INTERVAL)

        except KeyboardInterrupt:
            print("\n\n👋 Job Failure Watcher stopped")
            break
        except Exception as e:
            print(f"⚠️  Watcher error: {e}")
            time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()
```

**Run in background**:
```bash
# Start the watcher
nohup python job_failure_watcher.py > watcher_failures.log 2>&1 &

# Check if running
ps aux | grep job_failure_watcher
```

---

### **Agent 2: Training Progress Watcher** 📊

**Purpose**: Monitor W&B logs, evaluate training health, suggest improvements, auto-resubmit

**How it works**:
1. Polls wandb API every 10-30 minutes
2. Analyzes training metrics (loss, accuracy, learning rate)
3. Detects issues (divergence, plateau, overfitting)
4. Makes recommendations or auto-resubmits with adjusted config

**Implementation**:

```python
#!/usr/bin/env python3
"""
Training Progress Watcher - Monitors wandb logs and optimizes training
Usage: python training_progress_watcher.py --project your-wandb-project
"""
import wandb
import argparse
import time
import requests
from datetime import datetime
import numpy as np

GPU_MANAGER_API = "http://localhost:8080/api"
CHECK_INTERVAL = 600  # Check every 10 minutes

def analyze_run(run):
    """Analyze a wandb run for issues"""
    history = run.history()

    if len(history) < 10:
        return None, "Not enough data yet"

    issues = []
    recommendations = []

    # Check for divergence (loss increasing)
    if 'loss' in history.columns:
        recent_loss = history['loss'].tail(20).values
        if len(recent_loss) > 10:
            if np.mean(recent_loss[-5:]) > np.mean(recent_loss[:5]) * 1.5:
                issues.append("🔴 LOSS DIVERGING")
                recommendations.append("Reduce learning rate by 2-5x")
                recommendations.append("Check for gradient explosion (add gradient clipping)")

    # Check for plateau (loss not improving)
    if 'loss' in history.columns:
        recent_loss = history['loss'].tail(50).values
        if len(recent_loss) > 20:
            variance = np.var(recent_loss[-20:])
            if variance < 0.001:  # Basically flat
                issues.append("🟡 TRAINING PLATEAUED")
                recommendations.append("Increase learning rate")
                recommendations.append("Or decrease if already converged")

    # Check for overfitting (train loss << val loss)
    if 'train_loss' in history.columns and 'val_loss' in history.columns:
        recent_train = history['train_loss'].tail(10).mean()
        recent_val = history['val_loss'].tail(10).mean()

        if recent_val > recent_train * 1.5:
            issues.append("🟠 OVERFITTING DETECTED")
            recommendations.append("Add regularization (dropout, weight decay)")
            recommendations.append("Reduce model size")
            recommendations.append("Get more training data")

    # Check for NaN/Inf
    if history.isna().any().any() or np.isinf(history.select_dtypes(include=[np.number])).any().any():
        issues.append("🔴 NaN/Inf VALUES - CRITICAL")
        recommendations.append("STOP TRAINING - Reduce learning rate significantly")
        recommendations.append("Add gradient clipping")
        recommendations.append("Check data preprocessing")

    # Check learning rate schedule
    if 'learning_rate' in history.columns:
        lr_values = history['learning_rate'].tail(20).values
        if len(lr_values) > 5 and np.std(lr_values) < 1e-8:
            issues.append("ℹ️  Learning rate is constant")
            recommendations.append("Consider using LR scheduler (cosine, linear warmup)")

    return issues, recommendations

def should_auto_adjust(issues):
    """Determine if we should auto-adjust and resubmit"""
    critical_issues = [i for i in issues if i.startswith("🔴")]
    return len(critical_issues) > 0

def auto_adjust_config(job, issues, recommendations):
    """Automatically adjust training config based on issues"""
    adjustments = {}

    if any("DIVERGING" in i for i in issues):
        adjustments['learning_rate'] = 'reduce_by_3x'
        adjustments['gradient_clip'] = 'add_value_1.0'

    if any("NaN/Inf" in i for i in issues):
        adjustments['learning_rate'] = 'reduce_by_5x'
        adjustments['gradient_clip'] = 'add_value_0.5'
        adjustments['stop_training'] = True

    return adjustments

def resubmit_job(job_id, adjustments):
    """Cancel current job and resubmit with adjustments"""
    # Cancel current job
    requests.delete(f"{GPU_MANAGER_API}/jobs/{job_id}")

    # TODO: Modify config and resubmit
    # This requires parsing your training script's config
    # and resubmitting with adjusted parameters

    print(f"  ↻ Would resubmit with adjustments: {adjustments}")
    print(f"  ⚠️  Auto-resubmit not implemented - manual intervention required")

def main(wandb_project, wandb_entity=None):
    api = wandb.Api()

    print(f"🤖 Training Progress Watcher Started")
    print(f"   Project: {wandb_project}")
    print(f"   Checking every {CHECK_INTERVAL}s\n")

    monitored_runs = set()

    while True:
        try:
            # Get active runs
            runs = api.runs(f"{wandb_entity}/{wandb_project}" if wandb_entity else wandb_project)

            for run in runs:
                if run.state != "running":
                    continue

                run_id = run.id

                # Analyze run
                issues, recommendations = analyze_run(run)

                if issues is None:
                    continue

                if len(issues) > 0:
                    print(f"\n📊 RUN ANALYSIS: {run.name} ({run_id})")
                    print(f"   State: {run.state}")
                    print(f"   Runtime: {run.summary.get('_runtime', 0) / 60:.1f} minutes")

                    print("\n   ISSUES DETECTED:")
                    for issue in issues:
                        print(f"   {issue}")

                    print("\n   RECOMMENDATIONS:")
                    for rec in recommendations:
                        print(f"   • {rec}")

                    # Check if we should auto-adjust
                    if should_auto_adjust(issues):
                        adjustments = auto_adjust_config(run, issues, recommendations)
                        print(f"\n   🔧 AUTO-ADJUSTMENT TRIGGERED")

                        # Find corresponding GPU manager job
                        # (This requires tracking wandb run ID → GPU job ID)
                        # For now, just report
                        print(f"   Suggested adjustments: {adjustments}")

                monitored_runs.add(run_id)

            time.sleep(CHECK_INTERVAL)

        except KeyboardInterrupt:
            print("\n\n👋 Training Progress Watcher stopped")
            break
        except Exception as e:
            print(f"⚠️  Watcher error: {e}")
            time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True, help="W&B project name")
    parser.add_argument("--entity", help="W&B entity (team)")
    args = parser.parse_args()

    main(args.project, args.entity)
```

**Run in background**:
```bash
# Install wandb
uv pip install wandb

# Login to wandb
wandb login

# Start the watcher
nohup python training_progress_watcher.py --project your-project > watcher_progress.log 2>&1 &
```

---

## 🛠️ SSH Debugging Guide

When jobs fail, SSH access is crucial for debugging. Here's how to investigate:

### **Quick Debugging Workflow**

```bash
# 1. Check job status
curl http://localhost:8080/api/jobs/{job_id}

# 2. Get logs
curl http://localhost:8080/api/jobs/{job_id}/logs

# 3. SSH to the resource
ssh della-gpu  # for SLURM jobs
ssh Cynthia    # for Cynthia jobs

# 4. Navigate to working directory
cd /scratch/gpfs/CHIJ/milkkarten/your-project  # SLURM
cd /data1/milkkarten/Research/your-project     # Cynthia

# 5. Check files
ls -la
cat output.log
cat slurm-*.err  # SLURM error log
cat logs/training.log  # Your custom logs

# 6. Check SLURM job (if applicable)
squeue -u $USER  # See running jobs
sacct -j JOBID --format=JobID,JobName,State,ExitCode,Elapsed  # Job history
scontrol show job JOBID  # Detailed job info

# 7. Check environment
source .venv/bin/activate
python -c "import torch; print(torch.cuda.is_available())"
```

### **Common Issues and SSH Debugging**

#### **Issue: CUDA Out of Memory**
```bash
# Check GPU usage
ssh della-gpu "nvidia-smi"

# Check batch size in config
cat your-config.yaml | grep batch_size

# Check model size
python -c "from transformers import AutoModel; model = AutoModel.from_pretrained('...'); print(sum(p.numel() for p in model.parameters()))"
```

#### **Issue: Import Error**
```bash
# Check installed packages
source .venv/bin/activate
uv pip list

# Try importing
python -c "import transformers; print(transformers.__version__)"

# Reinstall if needed
uv pip install -r requirements.txt
```

#### **Issue: Wandb not logging**
```bash
# Check wandb status
cat ~/.netrc | grep wandb

# Check wandb directory
ls -la wandb/

# Manually sync offline runs
wandb sync wandb/offline-run-*
```

#### **Issue: Job stuck in queue**
```bash
# Check queue position
squeue -u $USER -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"

# Check why job is pending
squeue -j JOBID --start

# Check partition availability
sinfo -p ailab
```

---

## 📋 Training Job Template

**Complete example** showing best practices:

### **File: `train.py`**
```python
#!/usr/bin/env python3
"""
Example training script with proper logging and offline mode
"""
import os
import logging
import argparse
import wandb
from transformers import AutoModelForCausalLM, AutoTokenizer, Trainer, TrainingArguments

# Configure logging
os.makedirs("logs", exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/training.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def main(args):
    # Set offline mode for SLURM
    if os.getenv("SLURM_JOB_ID"):
        logger.info("Running on SLURM - setting offline mode")
        os.environ['TRANSFORMERS_OFFLINE'] = '1'
        os.environ['HF_HOME'] = './hf_cache'

    # Initialize wandb
    wandb.init(
        project=args.wandb_project,
        name=args.run_name,
        mode="offline" if os.getenv("SLURM_JOB_ID") else "online"
    )

    # Load model
    logger.info(f"Loading model: {args.model_name}")
    model = AutoModelForCausalLM.from_pretrained(
        args.model_name,
        cache_dir="./hf_cache"
    )
    tokenizer = AutoTokenizer.from_pretrained(
        args.model_name,
        cache_dir="./hf_cache"
    )

    # Training config
    training_args = TrainingArguments(
        output_dir="./checkpoints",
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        learning_rate=args.lr,
        logging_dir="./logs",
        logging_steps=10,
        save_steps=500,
        report_to="wandb"
    )

    # Load dataset (assumed to be pre-downloaded)
    # dataset = load_from_disk("./data")

    # Train
    trainer = Trainer(
        model=model,
        args=training_args,
        # train_dataset=dataset
    )

    logger.info("Starting training...")
    trainer.train()

    logger.info("Training completed!")
    wandb.finish()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_name", default="gpt2")
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--batch_size", type=int, default=8)
    parser.add_argument("--lr", type=float, default=5e-5)
    parser.add_argument("--wandb_project", default="my-training")
    parser.add_argument("--run_name", default="experiment-1")
    args = parser.parse_args()

    main(args)
```

### **File: `requirements.txt`**
```
torch>=2.0.0
transformers>=4.30.0
datasets>=2.14.0
wandb>=0.15.0
accelerate>=0.20.0
```

### **Submit to AI Lab**
```bash
curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "repo": "git@github.com:user/your-training-project.git",
    "branch": "main",
    "script": "train.py",
    "args": [
      "--model_name", "meta-llama/Llama-2-7b-hf",
      "--epochs", "3",
      "--batch_size", "4",
      "--lr", "5e-5",
      "--wandb_project", "llama-finetuning",
      "--run_name", "exp-001"
    ],
    "gpu_count": 1,
    "gpu_memory_min_gb": 141,
    "time_limit_hours": 12,
    "prefer_resource": "della-ailab"
  }'
```

---

## 📊 Complete Workflow

### **1. Preparation Phase**

```bash
# Clone your repo
cd ~/Research
git clone git@github.com:user/your-training-project.git
cd your-training-project

# Pre-install dependencies on SLURM login node
ssh della-gpu "cd /scratch/gpfs/CHIJ/milkkarten/your-training-project && \
  uv venv .venv && source .venv/bin/activate && \
  uv pip install -r requirements.txt"

# Pre-download model
ssh della-gpu
cd /scratch/gpfs/CHIJ/milkkarten/your-training-project
python << EOF
from transformers import AutoModel, AutoTokenizer
model = AutoModel.from_pretrained("meta-llama/Llama-2-7b-hf", cache_dir="./hf_cache")
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-2-7b-hf", cache_dir="./hf_cache")
EOF
exit

# Configure wandb
ssh della-gpu wandb login
```

### **2. Job Submission**

```bash
# Start watchers
nohup python job_failure_watcher.py > watcher_failures.log 2>&1 &
nohup python training_progress_watcher.py --project your-project > watcher_progress.log 2>&1 &

# Submit training job
curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d @job_config.json

# Job ID returned: abc-123-xyz
```

### **3. Monitoring**

```bash
# Check job status
curl http://localhost:8080/api/jobs/abc-123-xyz | jq

# View live logs
curl http://localhost:8080/api/jobs/abc-123-xyz/logs

# Check wandb dashboard
wandb board your-project

# Check watcher logs
tail -f watcher_failures.log
tail -f watcher_progress.log
```

### **4. Debugging (if needed)**

```bash
# SSH to resource
ssh della-gpu

# Navigate to job directory
cd /scratch/gpfs/CHIJ/milkkarten/your-training-project

# Check SLURM logs
cat logs/job_*.err
cat logs/training.log

# Check SLURM status
squeue -u $USER
sacct -j SLURM_JOB_ID

# Manually run part of the job for debugging
source .venv/bin/activate
python train.py --epochs 1 --batch_size 1  # Minimal config
```

### **5. Iteration**

Based on watcher feedback:
- Adjust hyperparameters
- Fix bugs
- Resubmit with updated config
- Watchers continue monitoring

---

## 🚀 Quick Start Checklist

- [ ] Set up environment on SLURM login node (uv, dependencies)
- [ ] Pre-download HuggingFace models to cache
- [ ] Configure wandb authentication
- [ ] Create `logs/` directory in project
- [ ] Set up training watchers
- [ ] Submit job to AI Lab first
- [ ] Monitor via watchers and wandb dashboard
- [ ] Use Cynthia only as fallback

---

## 📖 Related Documentation

- [CLAUDE.md](CLAUDE.md) - GPU Manager quick reference
- [REPO_SETUP.md](REPO_SETUP.md) - SSH keys and troubleshooting
- [NETWORK_ARCHITECTURE.md](NETWORK_ARCHITECTURE.md) - Mac-VPN proxy setup
- [AGENT_GUIDE.md](AGENT_GUIDE.md) - Complete API documentation

---

**Last Updated**: 2026-01-15
**Status**: Production Ready ✅
