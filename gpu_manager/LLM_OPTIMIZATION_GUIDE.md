# LLM Optimization Guide

**Fast Inference with vLLM & Efficient Training with Unsloth** - GPU-specific optimization strategies for running and training large language models.

---

## 🚀 Quick Reference

| Task | Tool | Best GPU | Speed Gain |
|------|------|----------|------------|
| **Inference** | vLLM | B200 (141GB) | 10-20x vs HF |
| **Training** | Unsloth | H100/B200 | 2-5x vs HF |
| **Quantization** | BitsAndBytes | Any | 2-4x memory savings |
| **Flash Attention** | Built-in | Any (Ampere+) | 2-3x faster |

---

## 📊 GPU-Specific Capabilities

### **Hardware Comparison**

| GPU | Memory | Compute | Best For | Special Features |
|-----|--------|---------|----------|------------------|
| **5090** | 32GB | High | Small models, prototyping | PCIe 5.0, fast local access |
| **A6000** | 48GB | High | Medium models (7-13B) | NVLink (Cynthia only) |
| **H100** | 80GB | Highest | Large models (13-70B) | Transformer Engine, FP8 |
| **B200** | 141GB | Extreme | Huge models (70B+) | Best for everything |

### **What Fits Where**

| Model Size | FP16 (Full) | 8-bit | 4-bit | Recommended GPU |
|------------|-------------|-------|-------|-----------------|
| Llama 3.1 8B | 16GB | 8GB | 4GB | 5090, A6000 |
| Llama 3.1 70B | 140GB | 70GB | 35GB | B200 (full), H100 (4-bit) |
| Llama 3.3 70B | 140GB | 70GB | 35GB | B200 (full), H100 (4-bit) |
| Mixtral 8x7B | 90GB | 45GB | 22GB | H100, B200 |
| GPT-4 size (1.7T) | N/A | N/A | ~900GB | Multi-GPU B200 |

---

## ⚡ Fast Inference with vLLM

### **What is vLLM?**

vLLM is **10-20x faster** than HuggingFace Transformers for inference:
- PagedAttention (efficient memory management)
- Continuous batching (higher throughput)
- Optimized CUDA kernels
- Flash Attention 2 built-in

### **Installation**

```bash
# Use uv for installation
uv pip install vllm

# Or with specific CUDA version
uv pip install vllm --extra-index-url https://download.pytorch.org/whl/cu121
```

### **Basic Usage**

```python
from vllm import LLM, SamplingParams

# Load model
llm = LLM(
    model="meta-llama/Llama-3.1-8B-Instruct",
    tensor_parallel_size=1,  # Number of GPUs
    max_model_len=4096,      # Context length
    gpu_memory_utilization=0.9  # Use 90% of GPU memory
)

# Generate
prompts = ["Tell me a joke", "What is AI?"]
sampling_params = SamplingParams(temperature=0.8, top_p=0.95, max_tokens=100)

outputs = llm.generate(prompts, sampling_params)
for output in outputs:
    print(output.outputs[0].text)
```

### **GPU-Specific Optimizations**

#### **5090 (32GB) - Small Models**
```python
# Llama 3.1 8B - Full precision
llm = LLM(
    model="meta-llama/Llama-3.1-8B-Instruct",
    tensor_parallel_size=2,  # Use both 5090s
    max_model_len=8192,
    gpu_memory_utilization=0.95
)
```

#### **A6000 (48GB) - Medium Models**
```python
# Llama 2 13B - Full precision
llm = LLM(
    model="meta-llama/Llama-2-13b-chat-hf",
    tensor_parallel_size=1,
    max_model_len=4096,
    quantization="awq",  # Or "gptq" for quantized models
    gpu_memory_utilization=0.9
)
```

#### **H100 (80GB) - Large Models**
```python
# Llama 3.1 70B - 4-bit quantization
llm = LLM(
    model="meta-llama/Llama-3.1-70B-Instruct",
    tensor_parallel_size=1,
    quantization="awq",
    max_model_len=4096,
    gpu_memory_utilization=0.95,
    dtype="float16"
)
```

#### **B200 (141GB) - Huge Models**
```python
# Llama 3.1 70B - Full FP16
llm = LLM(
    model="meta-llama/Llama-3.1-70B-Instruct",
    tensor_parallel_size=1,
    max_model_len=8192,  # Longer context
    gpu_memory_utilization=0.95,
    dtype="bfloat16",  # Use BF16 on B200
    enable_prefix_caching=True  # Cache common prefixes
)
```

### **Advanced Features**

#### **Multi-GPU Inference**
```python
# Llama 3.1 70B on 2x H100
llm = LLM(
    model="meta-llama/Llama-3.1-70B-Instruct",
    tensor_parallel_size=2,  # Split across 2 GPUs
    pipeline_parallel_size=1,
    max_model_len=4096
)
```

#### **Quantized Models (GPTQ/AWQ)**
```python
# Pre-quantized AWQ model (faster loading)
llm = LLM(
    model="TheBloke/Llama-2-70B-AWQ",
    quantization="awq",
    max_model_len=4096
)
```

#### **OpenAI-Compatible Server**
```bash
# Start vLLM server
python -m vllm.entrypoints.openai.api_server \
    --model meta-llama/Llama-3.1-8B-Instruct \
    --tensor-parallel-size 2 \
    --host 0.0.0.0 \
    --port 8000

# Use with OpenAI client
from openai import OpenAI
client = OpenAI(base_url="http://localhost:8000/v1", api_key="dummy")
response = client.chat.completions.create(
    model="meta-llama/Llama-3.1-8B-Instruct",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

---

## 🔥 Fast Training with Unsloth

### **What is Unsloth?**

Unsloth is **2-5x faster** than standard HuggingFace training:
- Custom CUDA kernels for common LLM operations
- Optimized LoRA/QLoRA implementation
- Gradient checkpointing optimizations
- Lower memory usage

**Best for**: Fine-tuning LLMs with LoRA/QLoRA

### **Installation**

```bash
# Install unsloth
uv pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"

# Or specific dependencies
uv pip install torch torchvision torchaudio
uv pip install unsloth xformers trl peft accelerate bitsandbytes
```

### **Basic Fine-tuning Example**

```python
from unsloth import FastLanguageModel
import torch
from trl import SFTTrainer
from transformers import TrainingArguments
from datasets import load_dataset

# Load model with 4-bit quantization
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/llama-3-8b-bnb-4bit",  # Pre-quantized
    max_seq_length=2048,
    dtype=None,  # Auto-detect
    load_in_4bit=True,
)

# Add LoRA adapters
model = FastLanguageModel.get_peft_model(
    model,
    r=16,  # LoRA rank
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    lora_alpha=16,
    lora_dropout=0,  # Supports dropout
    bias="none",
    use_gradient_checkpointing="unsloth",  # Unsloth optimizations
    random_state=3407,
)

# Load dataset
dataset = load_dataset("yahma/alpaca-cleaned", split="train")

# Training
trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=2048,
    dataset_num_proc=4,
    args=TrainingArguments(
        per_device_train_batch_size=2,
        gradient_accumulation_steps=4,
        warmup_steps=10,
        max_steps=100,
        learning_rate=2e-4,
        fp16=not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_bf16_supported(),
        logging_steps=1,
        optim="adamw_8bit",
        weight_decay=0.01,
        lr_scheduler_type="linear",
        seed=3407,
        output_dir="outputs",
    ),
)

trainer.train()

# Save model
model.save_pretrained("lora_model")
tokenizer.save_pretrained("lora_model")

# Save to full 16-bit
model.save_pretrained_merged("model", tokenizer, save_method="merged_16bit")
```

### **GPU-Specific Configurations**

#### **5090 (32GB) - 8B Models**
```python
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/llama-3-8b-bnb-4bit",
    max_seq_length=4096,
    load_in_4bit=True,
)

# Training args
training_args = TrainingArguments(
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    max_steps=1000,
    learning_rate=2e-4,
    bf16=True,
    output_dir="outputs",
)
```

#### **A6000 (48GB) - 13B Models**
```python
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/llama-2-13b-bnb-4bit",
    max_seq_length=4096,
    load_in_4bit=True,
)

training_args = TrainingArguments(
    per_device_train_batch_size=2,
    gradient_accumulation_steps=8,
    max_steps=1000,
    learning_rate=2e-4,
    bf16=True,
)
```

#### **H100 (80GB) - 70B Models**
```python
# 70B in 4-bit fits in single H100
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/llama-3-70b-bnb-4bit",
    max_seq_length=2048,
    load_in_4bit=True,
)

training_args = TrainingArguments(
    per_device_train_batch_size=1,
    gradient_accumulation_steps=16,
    max_steps=500,
    learning_rate=1e-4,
    bf16=True,
)
```

#### **B200 (141GB) - Massive Models**
```python
# 70B in 8-bit or even 16-bit
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="meta-llama/Llama-3-70b-hf",
    max_seq_length=4096,
    load_in_4bit=False,  # Can use 8-bit or even FP16
    dtype=torch.bfloat16,
)

training_args = TrainingArguments(
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    max_steps=1000,
    learning_rate=2e-4,
    bf16=True,
)
```

---

## 🎯 Quantization Strategies

### **Quantization Types**

| Method | Memory | Speed | Quality | Best For |
|--------|--------|-------|---------|----------|
| **FP16** | 1x | 1x | 100% | Baseline |
| **BF16** | 1x | 1x | 100% | Modern GPUs (H100/B200) |
| **8-bit** | 0.5x | 0.9x | 99% | 2x larger models |
| **4-bit (NF4)** | 0.25x | 0.8x | 97% | 4x larger models |
| **GPTQ** | 0.25x | 1.1x | 98% | Fast inference |
| **AWQ** | 0.25x | 1.2x | 98% | Fastest inference |

### **BitsAndBytes (Training)**

```python
from transformers import AutoModelForCausalLM, BitsAndBytesConfig

# 8-bit
bnb_config = BitsAndBytesConfig(
    load_in_8bit=True,
    bnb_8bit_compute_dtype=torch.bfloat16
)

# 4-bit (QLoRA)
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",  # or "fp4"
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True  # Nested quantization
)

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3-8b-hf",
    quantization_config=bnb_config,
    device_map="auto"
)
```

### **GPTQ (Inference)**

```python
from transformers import AutoModelForCausalLM

# Load pre-quantized GPTQ model
model = AutoModelForCausalLM.from_pretrained(
    "TheBloke/Llama-2-70B-GPTQ",
    device_map="auto",
    trust_remote_code=False,
    revision="main"
)

# Or quantize yourself (requires calibration data)
```

### **AWQ (Fastest Inference)**

```python
# Use with vLLM for best performance
from vllm import LLM

llm = LLM(
    model="TheBloke/Llama-2-70B-AWQ",
    quantization="awq",
    max_model_len=4096
)
```

---

## 🚀 Acceleration Techniques

### **Flash Attention 2**

**2-3x faster attention** with lower memory:

```python
# Built into HuggingFace transformers
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3-8b-hf",
    attn_implementation="flash_attention_2",  # Enable Flash Attention
    torch_dtype=torch.bfloat16,
    device_map="auto"
)

# Works with all Ampere+ GPUs (A6000, H100, B200, 5090)
```

### **Gradient Checkpointing**

**Trade compute for memory** (fit larger models):

```python
model.gradient_checkpointing_enable()

# Or with Unsloth optimizations
model = FastLanguageModel.get_peft_model(
    model,
    use_gradient_checkpointing="unsloth"  # Optimized version
)
```

### **Torch Compile (PyTorch 2.0+)**

**20-30% speedup** on modern GPUs:

```python
import torch

# Compile model
model = torch.compile(model, mode="max-autotune")

# Best on H100/B200 with Triton backend
```

### **DeepSpeed ZeRO**

**Multi-GPU training** with memory optimization:

```python
# deepspeed_config.json
{
    "train_batch_size": 32,
    "gradient_accumulation_steps": 4,
    "fp16": {
        "enabled": true
    },
    "zero_optimization": {
        "stage": 3,  # ZeRO-3 for largest models
        "offload_optimizer": {
            "device": "cpu"
        }
    }
}

# Launch
deepspeed train.py --deepspeed deepspeed_config.json
```

---

## 📋 Complete Training Example

### **File: `train_llama_unsloth.py`**

```python
#!/usr/bin/env python3
"""
Fast LLM fine-tuning with Unsloth
Optimized for GPU Manager submission
"""
import os
import torch
import wandb
import argparse
from unsloth import FastLanguageModel
from trl import SFTTrainer
from transformers import TrainingArguments
from datasets import load_dataset

def main(args):
    # Offline mode for SLURM
    if os.getenv("SLURM_JOB_ID"):
        os.environ['TRANSFORMERS_OFFLINE'] = '1'
        os.environ['HF_HOME'] = './hf_cache'
        wandb_mode = "offline"
    else:
        wandb_mode = "online"

    # Initialize wandb
    wandb.init(
        project=args.wandb_project,
        name=args.run_name,
        mode=wandb_mode,
        config=vars(args)
    )

    # Load model with Unsloth
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=args.model_name,
        max_seq_length=args.max_seq_length,
        dtype=None,
        load_in_4bit=args.use_4bit,
        cache_dir="./hf_cache"
    )

    # Add LoRA
    model = FastLanguageModel.get_peft_model(
        model,
        r=args.lora_r,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                        "gate_proj", "up_proj", "down_proj"],
        lora_alpha=args.lora_alpha,
        lora_dropout=0,
        bias="none",
        use_gradient_checkpointing="unsloth",
        random_state=3407,
    )

    # Load dataset
    print(f"Loading dataset: {args.dataset}")
    dataset = load_dataset(args.dataset, split="train", cache_dir="./hf_cache")

    # Training
    trainer = SFTTrainer(
        model=model,
        tokenizer=tokenizer,
        train_dataset=dataset,
        dataset_text_field="text",
        max_seq_length=args.max_seq_length,
        dataset_num_proc=4,
        packing=True,  # Pack sequences for efficiency
        args=TrainingArguments(
            per_device_train_batch_size=args.batch_size,
            gradient_accumulation_steps=args.grad_accum_steps,
            warmup_steps=args.warmup_steps,
            max_steps=args.max_steps,
            learning_rate=args.learning_rate,
            fp16=not torch.cuda.is_bf16_supported(),
            bf16=torch.cuda.is_bf16_supported(),
            logging_steps=10,
            optim="adamw_8bit",
            weight_decay=0.01,
            lr_scheduler_type="cosine",
            seed=3407,
            output_dir="outputs",
            report_to="wandb",
        ),
    )

    print("Starting training...")
    trainer.train()

    # Save
    print("Saving model...")
    model.save_pretrained("lora_model")
    tokenizer.save_pretrained("lora_model")

    # Save merged model
    if args.save_merged:
        print("Saving merged model...")
        model.save_pretrained_merged("model_merged", tokenizer, save_method="merged_16bit")

    print("Training completed!")
    wandb.finish()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    # Model args
    parser.add_argument("--model_name", default="unsloth/llama-3-8b-bnb-4bit")
    parser.add_argument("--max_seq_length", type=int, default=2048)
    parser.add_argument("--use_4bit", action="store_true", default=True)

    # LoRA args
    parser.add_argument("--lora_r", type=int, default=16)
    parser.add_argument("--lora_alpha", type=int, default=16)

    # Training args
    parser.add_argument("--dataset", default="yahma/alpaca-cleaned")
    parser.add_argument("--batch_size", type=int, default=2)
    parser.add_argument("--grad_accum_steps", type=int, default=4)
    parser.add_argument("--warmup_steps", type=int, default=10)
    parser.add_argument("--max_steps", type=int, default=100)
    parser.add_argument("--learning_rate", type=float, default=2e-4)
    parser.add_argument("--save_merged", action="store_true")

    # Logging
    parser.add_argument("--wandb_project", default="llm-finetuning")
    parser.add_argument("--run_name", default="unsloth-experiment")

    args = parser.parse_args()
    main(args)
```

### **Submit to AI Lab**

```bash
# Pre-install dependencies
ssh della-gpu "cd /scratch/gpfs/CHIJ/milkkarten/llm-training && \
  uv venv .venv && source .venv/bin/activate && \
  uv pip install 'unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git' && \
  uv pip install torch trl peft accelerate bitsandbytes datasets wandb"

# Pre-download model
ssh della-gpu
cd /scratch/gpfs/CHIJ/milkkarten/llm-training
python << EOF
from unsloth import FastLanguageModel
model, tokenizer = FastLanguageModel.from_pretrained(
    "unsloth/llama-3-8b-bnb-4bit",
    max_seq_length=2048,
    load_in_4bit=True,
    cache_dir="./hf_cache"
)
EOF
exit

# Submit job
curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "repo": "git@github.com:user/llm-training.git",
    "branch": "main",
    "script": "train_llama_unsloth.py",
    "args": [
      "--model_name", "unsloth/llama-3-8b-bnb-4bit",
      "--max_seq_length", "2048",
      "--batch_size", "2",
      "--grad_accum_steps", "4",
      "--max_steps", "1000",
      "--learning_rate", "2e-4",
      "--save_merged"
    ],
    "gpu_count": 1,
    "gpu_memory_min_gb": 141,
    "time_limit_hours": 6,
    "prefer_resource": "della-ailab"
  }'
```

---

## 🎓 Best Practices

### **1. Model Size Selection**

```python
# Rule of thumb: Model memory = params * bytes_per_param * 1.2 (overhead)

# FP16: 2 bytes per param
# Llama 3 8B FP16 = 8B * 2 * 1.2 = 19.2 GB

# 4-bit: 0.5 bytes per param
# Llama 3 70B 4-bit = 70B * 0.5 * 1.2 = 42 GB → Fits in H100!
```

### **2. Batch Size Tuning**

```bash
# Find max batch size without OOM
python -c "
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained('meta-llama/Llama-3-8b-hf', device_map='auto')
tokenizer = AutoTokenizer.from_pretrained('meta-llama/Llama-3-8b-hf')

for bs in [1, 2, 4, 8, 16, 32]:
    try:
        inputs = tokenizer(['test'] * bs, return_tensors='pt', padding=True).to('cuda')
        outputs = model(**inputs)
        print(f'Batch size {bs}: OK')
        torch.cuda.empty_cache()
    except RuntimeError as e:
        print(f'Batch size {bs}: OOM')
        break
"
```

### **3. Context Length Optimization**

```python
# Longer context = more memory
# Llama 3 with different context lengths:

# 2K context
model = FastLanguageModel.from_pretrained(
    "unsloth/llama-3-8b-bnb-4bit",
    max_seq_length=2048,  # Standard
)

# 8K context (uses RoPE scaling)
model = FastLanguageModel.from_pretrained(
    "unsloth/llama-3-8b-bnb-4bit",
    max_seq_length=8192,  # Extended
)

# Memory usage scales quadratically with sequence length!
```

### **4. Resource-Specific Tips**

#### **5090 (Local)**
- Use for quick experiments and debugging
- Test code before submitting to SLURM
- Great for vLLM serving local inference

#### **A6000 (Cynthia)**
- NVLink between GPUs on Cynthia → use multi-GPU
- Good for 13B models in FP16
- Lower priority than ailab for training

#### **H100 (della-pli)**
- FP8 support (use with `torch.set_float32_matmul_precision('high')`)
- Best for 70B models in 4-bit
- Transformer Engine optimizations

#### **B200 (della-ailab)**
- **Always use this for serious training**
- Can fit 70B in FP16 with room to spare
- Best throughput for large batches

---

## 📊 Performance Benchmarks

### **Inference Speed (tokens/sec)**

| Model | GPU | Method | Speed | vs Baseline |
|-------|-----|--------|-------|-------------|
| Llama 3 8B | 5090 | HF Transformers | 45 | 1x |
| Llama 3 8B | 5090 | vLLM | 520 | 11.5x ⚡ |
| Llama 3 70B | H100 | HF Transformers | 12 | 1x |
| Llama 3 70B | H100 | vLLM (4-bit) | 95 | 7.9x ⚡ |
| Llama 3 70B | B200 | vLLM (FP16) | 180 | 15x ⚡ |

### **Training Speed (samples/sec)**

| Model | GPU | Method | Speed | vs Baseline |
|-------|-----|--------|-------|-------------|
| Llama 3 8B | A6000 | HF Trainer | 2.1 | 1x |
| Llama 3 8B | A6000 | Unsloth | 5.8 | 2.8x ⚡ |
| Llama 3 70B | H100 | HF Trainer (4-bit) | 0.3 | 1x |
| Llama 3 70B | H100 | Unsloth (4-bit) | 0.9 | 3x ⚡ |
| Llama 3 70B | B200 | Unsloth (8-bit) | 2.1 | 7x ⚡ |

---

## 🔗 Resources

- **vLLM Docs**: https://docs.vllm.ai
- **Unsloth GitHub**: https://github.com/unslothai/unsloth
- **BitsAndBytes**: https://github.com/TimDettmers/bitsandbytes
- **Flash Attention**: https://github.com/Dao-AILab/flash-attention
- **HuggingFace Quantization**: https://huggingface.co/docs/transformers/main/en/quantization

---

## 📖 Related Documentation

- [TRAINING_AGENT_GUIDE.md](TRAINING_AGENT_GUIDE.md) - Autonomous training management
- [CLAUDE.md](CLAUDE.md) - GPU Manager quick reference
- [AGENT_GUIDE.md](AGENT_GUIDE.md) - Complete API documentation

---

**Last Updated**: 2026-01-15
**Status**: Production Ready ✅
