# ML Training Loop - Systematic Experimentation

**A structured workflow for hypothesis-driven machine learning training**

---

## 🎯 Overview

The training loop is a systematic approach to ML experimentation that maximizes learning while minimizing wasted compute. Each iteration tests a hypothesis, monitors execution, and informs the next experiment.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TRAINING LOOP WORKFLOW                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. HYPOTHESIS → 2. RESOURCE CHECK → 3. TEST RUN → 4. FULL RUN     │
│       ↑                                                      │       │
│       │                                                      │       │
│       └──────────────── ANALYZE & ITERATE ←─────────────────┘       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Phase 1: Hypothesis Formation

**Before starting any run, clearly define what you're testing.**

### What Makes a Good Hypothesis?

A hypothesis should be:
- **Specific**: "Increase batch size from 32 to 64"
- **Measurable**: "Should improve training speed by ~1.5x"
- **Falsifiable**: "If loss doesn't decrease within 2 epochs, hypothesis is wrong"

### Hypothesis Categories

| Category | Examples | Metrics to Track |
|----------|----------|------------------|
| **Hyperparameters** | Learning rate, batch size, weight decay, warmup steps | Loss curves, convergence speed |
| **Architecture** | Model depth, hidden dim, attention heads, activation functions | Performance, parameter count, inference speed |
| **Data Processing** | Augmentation, filtering, tokenization, preprocessing | Training stability, generalization gap |
| **Algorithm Changes** | Optimizer (Adam→AdamW), loss function, regularization | Convergence behavior, final metrics |

### Document Your Hypothesis

Create a training log entry:

```markdown
## Experiment: exp-2024-01-15-larger-batch

**Hypothesis**: Increasing batch size from 32 to 128 with linear LR scaling
will maintain model quality while reducing training time by 2x.

**Changes**:
- batch_size: 32 → 128
- learning_rate: 1e-4 → 4e-4 (linear scaling)
- warmup_steps: 500 → 2000

**Expected Outcomes**:
- Training time: ~24h → ~12h
- Final loss: Similar to baseline (±5%)
- GPU utilization: >90%

**Baseline**: exp-2024-01-10-baseline (loss=0.45, 24h training)
```

---

## 🖥️ Phase 2: Resource Selection

**Choose the right GPU resource based on your experiment type.**

### Resource Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│ RESOURCE SELECTION DECISION TREE                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Is this a full training run?                                       │
│    ├─ YES → Use AI Lab (B200 141GB)                                │
│    │         - Large models                                         │
│    │         - Long training (>12h)                                 │
│    │         - Maximum memory needed                                │
│    │                                                                 │
│    └─ NO → Is this a quick test/debug?                             │
│         ├─ YES → Use local-5090 (2x 32GB)                          │
│         │         - Instant start                                   │
│         │         - Quick iteration                                 │
│         │         - No queue wait                                   │
│         │                                                            │
│         └─ NO → Inference or small training?                       │
│              └─ Use Cynthia (8x A6000 Ada 48GB)                    │
│                  - Instant start                                    │
│                  - Multi-GPU if needed                              │
│                  - Good for inference                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### GPU Resource Matrix

| Use Case | Priority 1 | Priority 2 | Priority 3 |
|----------|------------|------------|------------|
| **Large model training** | AI Lab (B200) | della-pli (H100) | della-a100 (A100) |
| **Quick testing/debugging** | local-5090 | Cynthia | AI Lab (1h gpu-test) |
| **Inference (batch)** | AI Lab (B200) | Cynthia | local-5090 |
| **Inference (interactive)** | local-5090 | Cynthia | - |
| **Small model training** | local-5090 | Cynthia | AI Lab |
| **Multi-GPU training (2-4 GPUs)** | AI Lab | Cynthia | della-pli |
| **Multi-GPU training (8 GPUs)** | AI Lab | Cynthia | - |

### Check Available Resources

```bash
# Check all GPU resources
curl http://localhost:8080/api/resources

# Look for:
# - free_gpus > 0 (instant availability)
# - running_jobs < total capacity (low contention)
```

**Decision Making**:
- **AI Lab available?** → Use it for training runs
- **AI Lab busy?** → Use local-5090 for testing, queue AI Lab for full run
- **Only need 1-2 GPUs?** → local-5090 or Cynthia are instant

---

## 🧪 Phase 3: Test Run (1 Hour Max)

**Never commit to a long run without validating setup first.**

### Test Run Checklist

```json
{
  "repo": "git@github.com:user/project.git",
  "branch": "exp-larger-batch",
  "script": "train.py",
  "args": ["--batch-size", "128", "--max-steps", "100", "--save-interval", "50"],
  "gpu_count": 1,
  "gpu_memory_min_gb": 80,
  "time_limit_hours": 1,
  "prefer_resource": "della-ailab"
}
```

**Why 1 hour?**:
- ✅ `gpu-test` QoS = highest priority, starts immediately
- ✅ Long enough to catch most errors
- ✅ Short enough to iterate quickly if issues found

### What to Monitor in Test Run

#### 1️⃣ **Startup Validation** (First 5 minutes)

```bash
# Watch logs in real-time
curl http://localhost:8080/api/jobs/{job_id}/logs

# Check for:
# ✓ Dependencies loaded successfully
# ✓ Model initialized without errors
# ✓ Data loading working
# ✓ First training step completed
```

**Common startup issues**:
- ❌ Import errors (missing dependencies)
- ❌ CUDA out of memory (model too large)
- ❌ Data loading failures (path issues, corrupted files)
- ❌ Config errors (incompatible hyperparameters)

#### 2️⃣ **GPU Utilization** (10-15 minutes in)

**Target**: >85% GPU utilization, >80% memory utilization

```python
# Add to your training script
import time
import torch

def log_gpu_stats():
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        allocated = torch.cuda.memory_allocated(i) / 1024**3
        reserved = torch.cuda.memory_reserved(i) / 1024**3
        total = props.total_memory / 1024**3

        print(f"GPU {i}: {allocated:.1f}GB / {total:.1f}GB allocated "
              f"({100*allocated/total:.1f}% utilization)")

# Call every 100 steps
if step % 100 == 0:
    log_gpu_stats()
```

**Low utilization (<70%)?** Common causes:
- Data loading bottleneck (increase num_workers)
- Batch size too small
- CPU preprocessing too slow
- Network I/O issues

#### 3️⃣ **Training Dynamics** (Full hour)

Monitor these metrics:

```python
# Essential metrics to log
metrics = {
    "step": step,
    "loss": loss.item(),
    "learning_rate": optimizer.param_groups[0]['lr'],
    "throughput": samples_per_second,
    "gpu_memory_gb": torch.cuda.max_memory_allocated() / 1024**3,
    "timestamp": time.time()
}
```

**Red flags 🚩**:
- Loss = NaN or Inf (learning rate too high, numerical instability)
- Loss not decreasing after 100+ steps (learning rate too low, bug in training loop)
- Memory usage growing over time (memory leak)
- Throughput decreasing over time (data loading issue)

### Test Run Decision Matrix

| Observation | Action |
|-------------|--------|
| ✅ No errors, good GPU utilization, loss decreasing | **Proceed to full run** |
| ⚠️ Low GPU utilization but otherwise healthy | Optimize data loading, then proceed |
| ⚠️ Loss stable but not decreasing | Increase LR or check implementation, retest |
| ❌ Crashes or OOM errors | Fix issue, retest |
| ❌ Loss = NaN | Reduce LR, add gradient clipping, retest |

---

## 🚀 Phase 4: Full Run

**Once test run validates setup, launch the full training.**

### Full Run Submission

```json
{
  "repo": "git@github.com:user/project.git",
  "branch": "exp-larger-batch",
  "script": "train.py",
  "args": ["--batch-size", "128", "--epochs", "50", "--save-interval", "1000"],
  "gpu_count": 2,
  "gpu_memory_min_gb": 80,
  "time_limit_hours": 24,
  "prefer_resource": "della-ailab"
}
```

### Time Limit Strategy

| Training Duration | time_limit_hours | SLURM QoS | Priority | Best For |
|-------------------|------------------|-----------|----------|----------|
| **Short** | ≤24h | `gpu-short` | 🟡 Medium | Standard experiments |
| **Long** | ≤72h | `gpu-medium` | 🟢 Lower | Large-scale training |

**Trade-off**: Shorter time limits = higher queue priority but may not finish training.

**Recommendation**:
- Start with 24h if possible
- Use checkpointing to resume if needed
- Only use 72h for truly long runs

### Monitoring Full Runs

#### 🚨 **Error Detection Timer** (Every 10-15 minutes)

Catch failures quickly:

```python
#!/usr/bin/env python3
"""
Error Detection Watcher - Monitors for training failures
"""
import requests
import time

JOB_ID = "your-job-id"
CHECK_INTERVAL = 600  # 10 minutes

def check_for_errors(job_id):
    logs = requests.get(f"http://localhost:8080/api/jobs/{job_id}/logs").text

    # Error patterns
    errors = {
        "oom": "CUDA out of memory" in logs or "OutOfMemoryError" in logs,
        "nan": "loss = nan" in logs.lower() or "loss: nan" in logs.lower(),
        "timeout": "TimeoutError" in logs,
        "killed": "Killed" in logs or "killed by signal" in logs.lower(),
    }

    if any(errors.values()):
        print(f"🚨 ERROR DETECTED in job {job_id}:")
        for error_type, detected in errors.items():
            if detected:
                print(f"  - {error_type.upper()}")
        return True
    return False

while True:
    job = requests.get(f"http://localhost:8080/api/jobs/{JOB_ID}").json()

    if job['status'] == 'failed':
        print(f"❌ Job {JOB_ID} FAILED")
        check_for_errors(JOB_ID)
        break

    if job['status'] == 'completed':
        print(f"✅ Job {JOB_ID} COMPLETED")
        break

    # Check for errors even if still running
    if check_for_errors(JOB_ID):
        print("Consider cancelling and debugging")

    time.sleep(CHECK_INTERVAL)
```

#### 📊 **Utilization Monitor** (Every 30 minutes)

Ensure efficient resource usage:

```python
#!/usr/bin/env python3
"""
GPU Utilization Monitor - Tracks GPU usage efficiency
"""
import requests
import re
import time

def parse_gpu_utilization(logs):
    """Extract GPU utilization from logs"""
    # Assumes your training script logs GPU stats
    # Format: "GPU 0: 45.2GB / 141GB allocated (32.0% utilization)"

    pattern = r"GPU \d+:.*\((\d+\.\d+)% utilization\)"
    matches = re.findall(pattern, logs)

    if matches:
        utilizations = [float(u) for u in matches]
        return sum(utilizations) / len(utilizations)
    return None

def check_utilization(job_id):
    logs = requests.get(f"http://localhost:8080/api/jobs/{job_id}/logs").text
    utilization = parse_gpu_utilization(logs)

    if utilization:
        if utilization < 70:
            print(f"⚠️  Low GPU utilization: {utilization:.1f}%")
            print("   → Check data loading, increase batch size, or optimize preprocessing")
        else:
            print(f"✅ Good GPU utilization: {utilization:.1f}%")

    return utilization

# Run every 30 minutes
while True:
    check_utilization(JOB_ID)
    time.sleep(1800)
```

#### 📈 **Performance Tracker** (Every 1 hour)

Track training progress and detect issues:

```python
#!/usr/bin/env python3
"""
Performance Tracker - Monitors training metrics hourly
"""
import requests
import time
import re
from collections import deque

class PerformanceTracker:
    def __init__(self, job_id, check_interval=3600):
        self.job_id = job_id
        self.check_interval = check_interval
        self.loss_history = deque(maxlen=5)  # Last 5 hours

    def parse_latest_metrics(self, logs):
        """Extract latest loss and step from logs"""
        # Assumes format: "Step 1000 | Loss: 0.456"
        pattern = r"Step (\d+).*Loss[:\s]+(\d+\.\d+)"
        matches = re.findall(pattern, logs)

        if matches:
            step, loss = matches[-1]
            return int(step), float(loss)
        return None, None

    def check_progress(self):
        logs = requests.get(
            f"http://localhost:8080/api/jobs/{self.job_id}/logs"
        ).text

        step, loss = self.parse_latest_metrics(logs)

        if loss is None:
            print("⚠️  Could not parse loss from logs")
            return

        self.loss_history.append(loss)

        print(f"\n{'='*60}")
        print(f"Performance Check - Step {step}")
        print(f"{'='*60}")
        print(f"Current Loss: {loss:.4f}")

        if len(self.loss_history) >= 2:
            # Check if loss is improving
            recent_losses = list(self.loss_history)
            improvement = recent_losses[0] - recent_losses[-1]

            if improvement > 0:
                print(f"✅ Loss improving: -{improvement:.4f} over {len(recent_losses)}h")
            elif improvement < -0.01:
                print(f"🚩 Loss INCREASING: +{-improvement:.4f} over {len(recent_losses)}h")
                print("   → Consider stopping and investigating")
            else:
                print(f"⚠️  Loss plateaued (Δ{improvement:.4f})")
                print("   → May need to adjust learning rate or check convergence")

        # Hypothesis check
        print(f"\n📊 Hypothesis Evaluation:")
        print(f"   Current: {loss:.4f}")
        print(f"   Expected: ~0.45 (baseline)")

        if loss < 0.45:
            print("   ✅ Better than baseline - hypothesis supported!")
        elif loss > 0.50:
            print("   ❌ Worse than baseline - hypothesis may be wrong")
        else:
            print("   ➡️  Similar to baseline - need more training")

    def run(self):
        while True:
            job = requests.get(
                f"http://localhost:8080/api/jobs/{self.job_id}"
            ).json()

            if job['status'] in ['completed', 'failed']:
                print(f"\n{'='*60}")
                print(f"Job finished with status: {job['status']}")
                break

            self.check_progress()
            time.sleep(self.check_interval)

# Usage
tracker = PerformanceTracker(job_id="your-job-id")
tracker.run()
```

### When to Intervene

| Signal | Interpretation | Action |
|--------|----------------|--------|
| ✅ Loss decreasing steadily | Hypothesis on track | Continue monitoring |
| ⚠️ Loss plateau for >3 hours | May have converged or LR too low | Check convergence, consider stopping |
| 🚩 Loss increasing | Instability or bug | Stop job, investigate |
| 🚨 Low GPU utilization (<70%) | Inefficient | Optimize or accept slower training |
| ❌ Crashes/errors | Configuration issue | Stop, fix, relaunch |

---

## 🔄 Phase 5: Analysis & Iteration

**After each run, analyze results and plan next experiment.**

### Post-Run Analysis

```markdown
## Experiment Results: exp-2024-01-15-larger-batch

**Outcome**: ✅ SUCCESS

**Metrics**:
- Final Loss: 0.42 (baseline: 0.45) → **7% improvement**
- Training Time: 14.5h (baseline: 24h) → **40% faster**
- GPU Utilization: 92% (target: >85%)

**Hypothesis Validation**:
✅ CONFIRMED - Larger batch size improved both speed and quality

**Observations**:
- Loss converged faster than baseline (10h vs 20h)
- No stability issues with higher LR
- Memory usage: 95GB / 141GB (67% of B200)

**Next Steps**:
1. Try even larger batch size (128 → 256) with gradient accumulation
2. Test if quality holds on validation set
3. Consider this as new baseline
```

### Deciding Next Experiment

```
Current Result → Next Hypothesis
────────────────────────────────

Loss improved?
  ✅ YES → Push further in same direction
  ❌ NO  → Try different approach

Training stable?
  ✅ YES → Can be more aggressive
  ❌ NO  → Need more conservative changes

GPU utilization high?
  ✅ YES → Compute-optimal, can scale up
  ❌ NO  → Fix bottleneck before scaling
```

---

## 📋 Complete Loop Example

### Iteration 1: Baseline

```markdown
**Hypothesis**: Establish baseline with standard hyperparameters

**Resources**: AI Lab (B200)
**Test Run**: 1h, gpu-test QoS
**Full Run**: 24h, gpu-short QoS

**Result**: Loss 0.45, 24h training time
```

### Iteration 2: Larger Batch

```markdown
**Hypothesis**: 4x batch size will reduce training time by ~2x

**Resources**: AI Lab (B200)
**Test Run**: 1h, validated GPU utilization
**Full Run**: 24h, gpu-short QoS

**Result**: Loss 0.42, 14.5h → Better & faster! ✅
```

### Iteration 3: Architecture Change

```markdown
**Hypothesis**: Adding 2 more layers will improve quality by 10%

**Resources**: local-5090 (quick test), then AI Lab
**Test Run**: 1h on local-5090, caught OOM → reduced hidden dim
**Full Run**: 24h on AI Lab

**Result**: Loss 0.38, 16h → Significant improvement! ✅
```

### Iteration 4: Data Augmentation

```markdown
**Hypothesis**: Stronger augmentation will improve generalization

**Resources**: Cynthia (small run for testing)
**Test Run**: 1h, looks good
**Full Run**: 24h on AI Lab

**Result**: Loss 0.39, worse than Iteration 3 → Hypothesis rejected ❌
**Decision**: Revert to Iteration 3 architecture, try different data approach
```

---

## 🎯 Best Practices

### ✅ DO

- **Always run 1h test first** - Catches 90% of issues
- **Monitor actively for first 3 hours** - Most failures happen early
- **Log extensively** - GPU stats, throughput, loss every N steps
- **Use checkpointing** - Save every 1-2 hours for long runs
- **Document everything** - Track what you tried and why
- **Use version control** - Branch per experiment
- **Set up watchers** - Automate monitoring, don't babysit

### ❌ DON'T

- **Don't queue long runs without testing** - Wastes time if config is wrong
- **Don't change multiple things at once** - Can't tell what worked
- **Don't ignore low GPU utilization** - You're wasting resources
- **Don't run without monitoring** - Catch issues early
- **Don't forget to check queue status** - AI Lab may be busy
- **Don't use Cynthia for long training** - Reserve for testing/inference

---

## 🔧 Tools & Scripts

### Quick Start Template

```bash
#!/bin/bash
# quick_train_loop.sh - Automated test → full run workflow

REPO="git@github.com:user/project.git"
BRANCH="exp-new-hypothesis"
SCRIPT="train.py"

# Phase 1: Test run (1h)
echo "Starting 1h test run..."
TEST_JOB=$(curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d "{
    \"repo\": \"$REPO\",
    \"branch\": \"$BRANCH\",
    \"script\": \"$SCRIPT\",
    \"args\": [\"--max-steps\", \"100\"],
    \"gpu_count\": 1,
    \"time_limit_hours\": 1
  }" | jq -r '.id')

echo "Test job ID: $TEST_JOB"
echo "Monitoring for 1 hour..."

# Wait for test to complete
sleep 3700  # ~1 hour

# Check test result
STATUS=$(curl http://localhost:8080/api/jobs/$TEST_JOB | jq -r '.status')

if [ "$STATUS" = "completed" ]; then
    echo "✅ Test passed! Launching full run..."

    FULL_JOB=$(curl -X POST http://localhost:8080/api/jobs \
      -H "Content-Type: application/json" \
      -d "{
        \"repo\": \"$REPO\",
        \"branch\": \"$BRANCH\",
        \"script\": \"$SCRIPT\",
        \"gpu_count\": 2,
        \"time_limit_hours\": 24
      }" | jq -r '.id')

    echo "Full run job ID: $FULL_JOB"
else
    echo "❌ Test failed with status: $STATUS"
    echo "Check logs: curl http://localhost:8080/api/jobs/$TEST_JOB/logs"
fi
```

---

## 📚 Related Documentation

- [TRAINING_AGENT_GUIDE.md](TRAINING_AGENT_GUIDE.md) - Complete training best practices
- [LLM_OPTIMIZATION_GUIDE.md](LLM_OPTIMIZATION_GUIDE.md) - LLM-specific optimizations
- [GPU_MANAGER_REFERENCE.md](GPU_MANAGER_REFERENCE.md) - API quick reference

---

**Last Updated**: 2026-01-15
**Status**: Production Ready ✅
