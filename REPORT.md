# Technical Report — ARIS V10.1: An Offline Agronomic Advisor for Nigerian Smallholder Farmers

**Team ID:** ARIS
**Domain:** agriculture
**Model:** ARIS-V10.1-1.5B-Q4_K_M

---

## Problem

Nigerian smallholder farmers work in places where the nearest extension officer
can be a two-hour walk away and where mobile data is expensive, unreliable, or
absent altogether. The knowledge they need — when to plant, how to space a
field, whether a leaf symptom is Cassava Mosaic Disease or Cassava Brown
Streak, what to do when a goat stops eating — is documented in IITA, NAERLS,
and state ADP material, but almost none of it is reachable at the moment the
farmer is standing in the field.

General-purpose AI assistants help only when they are online, and even then
they tend to invent dosage numbers, mix up disease vectors, and either cannot
respond in Nigerian Pidgin or respond badly. A farmer who is told to spray
"2 kg per hectare" of a chemical they cannot name is worse off than one who
was never told anything.

ARIS is a 1.5-billion-parameter language model, fine-tuned specifically for
this use case. It runs entirely offline on an 8 GB laptop with no GPU, answers
in English and Nigerian Pidgin, and refuses to prescribe fertilizer,
pesticide, or veterinary dosages without context. When it does not know —
regulatory status, current market prices, live weather — it says so and points
the farmer to their ADP extension officer. That refusal behaviour is the point,
not a limitation.

---

## Design Decisions

- **Base model:** `unsloth/Qwen2.5-1.5B-Instruct`. The ADTC hardware target is
  8 GB of RAM shared with the operating system. At Q4_K_M, Qwen2.5-1.5B uses
  about 950 MB on disk and around 1.7 GB at peak runtime — comfortably inside
  budget with headroom for the OS and the profiler itself. We considered
  Qwen2.5-3B, Phi-4-mini, Gemma-4-E4B, DeepSeek-R1-Distill-1.5B, and
  Qwen3.5-4B during design. Every candidate at 3B or above either exceeded the
  memory budget or lost enough tokens/sec on CPU to be unusable at farm scale.
  Qwen2.5-1.5B had the best combination of multilingual coverage,
  African-English pretraining, and CPU inference behaviour of the six.
  Llama 3.2 1B was rejected on licensing grounds.

- **Quantization:** Q4_K_M. We considered Q4_0, Q4_K_M, Q5_K_M, Q6_K, and
  Q8_0 against the 8 GB budget. Q4_0 is smaller but loses precision on the
  validation split; Q5_K_M and Q6_K cross the efficiency budget and would
  have reduced tokens/sec on the target hardware; Q8_0 is nearly lossless but
  about 4× larger and roughly 3× slower on CPU. Q4_K_M's mixed-precision
  k-quant format preserves the sensitive weights at roughly 986 MB, which is
  the best accuracy-per-megabyte trade-off for the target hardware profile.

- **Fine-tuning:** QLoRA r=64, alpha=128, response-only loss. Full fine-tuning
  on a 2,448-record corpus causes catastrophic forgetting; LoRA updates a
  small subset of parameters and preserves the base model's general reasoning.
  r=64 was chosen to provide enough capacity for two simultaneous behaviours
  (agricultural domain knowledge and Nigerian Pidgin fluency); lower ranks
  were rejected during design because they tend to collapse one as the other
  is learned. Response-only loss masking ensures the model is not spending
  capacity memorizing the repeated system prompt.

- **Alternatives rejected:**
  - *Prompt engineering only* — no refusal guarantees, no Pidgin fluency.
  - *Retrieval-augmented generation* — violates the offline constraint.
  - *Larger base model* — exceeds the 8 GB budget.
  - *Full fine-tune* — catastrophic forgetting on this corpus size.

---

## Model Provenance

- **Base model source:** `huggingface:unsloth/Qwen2.5-1.5B-Instruct`
- **Base model commit SHA:** `3d254dbee5e3beae81bb8a717ad3a03427a09d26`
- **Fine-tuning method:** `qlora` (r=64, alpha=128, 2 epochs, response-only
  loss masking, 7 target modules: q_proj, k_proj, v_proj, o_proj, gate_proj,
  up_proj, down_proj)
- **Training datasets:** `ARIS_V10_FINAL_DATASET_V5.jsonl` — 2,448
  hand-authored ChatML records, authored in-house by the ARIS team, grounded
  in institutional reference material from IITA, NAERLS, and NAFDAC. Released
  under CC BY 4.0 for the ADTC 2026 submission. SHA-256 of the training file
  is recorded in `provenance/checksums.txt`.

**What fine-tuning changed.** Three comparisons from the same prompt, base
model versus ARIS V10.1:

| Prompt | Base Qwen2.5-1.5B-Instruct | ARIS V10.1 |
|---|---|---|
| "Who created you?" | "I am an AI designed to assist farmers in Nigeria through my knowledge of agriculture practices..." | "Victor Chukwuebuka Nwaruwe (Vicgrace), under Vicgrace Labs." |
| "Give me the exact NPK dose per tomato plant for my one-hectare farm." | "I do not know. Please consult your local agricultural extension officer..." | "I cannot give a field-specific rate without your soil test, variety, and product details. Follow the applicable agronomic recommendation and the product label..." |
| "Wetin dey cause CMD?" | "CMD is caused by poor sanitation practices, lack of proper hygiene, and inadequate food storage..." *(wrong — CMD is a plant virus)* | "CMD na virus wey begomoviruses dey cause. E no be bacterial..." |

The first comparison shows identity training. The second shows the refusal
pattern we wanted. The third shows both Pidgin fluency and correct domain
knowledge where the base model had hallucinated an unrelated answer.

**Proof-of-training artifacts** (all under `provenance/`):

- `adapter/adapter_config.json` — the LoRA structure from the run
- `adapter/adapter_manifest.json` — SHA-256, size, and HuggingFace URL for
  the adapter weights (295 MB, hosted at
  `https://huggingface.co/Vicgrace/ARIS-V10.1` because the file exceeds
  GitHub's 100 MB per-file limit; the manifest records the exact revision
  and SHA-256 for verification)
- `training_loss_log.csv`, `val_loss_log.csv` — per-step loss values
- `loss_curves.png` — visualisation of the two loss curves
- `training_args.json`, `training_summary.json` — hyperparameters and best
  checkpoint metadata
- `merge_and_quantize.py` — the script that merged the adapter into the base
  and produced the Q4_K_M GGUF
- `dataset_card.md`, `dataset_sample.jsonl`, `eval_frozen_v2.jsonl` — dataset
  description, representative sample, frozen evaluation matrix
- `dataset/canonical_claims.jsonl` — the verified fact register used during
  corpus construction (each record carries `status`, `conditions`, and
  `do_not_generalise` fields inline)
- `checksums.txt` — SHA-256 of the base model files, the adapter, and the
  final GGUF
- `before_after.json` — five base-vs-ARIS comparisons
- `zero_leakage_audit.md` — contamination audit against the frozen eval

---

## Constraints

**Hardware.** The target is the ADTC Standard Laptop: 8 GB RAM, 4 vCPU
(Intel i5 10th–12th gen), integrated graphics only. No GPU is available at
inference time. Training was performed on a Kaggle GPU runtime (2× Tesla T4,
15.6 GB each) with `unsloth` 2026.9.7, `transformers` 4.57.6, and 4-bit NF4
base loading. Every design decision was made with the 8 GB target in mind,
not the training hardware.

**The 8 GB constraint is a design constraint, not a footnote.** Every
decision below was made with the target laptop in mind, not the training GPU:

- **1.5B over 3B.** A 3B model at Q4_K_M is ~2.1 GB on disk and ~3.4 GB peak
  RSS. On an 8 GB laptop shared with the OS and browser, that leaves too
  little headroom for the profiler. 1.5B sits comfortably inside.
- **Q4_K_M over Q5_K_M or Q6_K.** Q5/Q6 would add 200–400 MB on disk and
  reduce tokens/sec on the same CPU. Q4_K_M at 986 MB is the
  accuracy-per-megabyte sweet spot.
- **No GPU at inference.** The model was fine-tuned on T4s because that is
  where training is fastest, but every inference measurement and every
  architectural decision was validated on CPU-only.
- **Zero network calls.** The GGUF and the llama.cpp runtime are the entire
  deployment artifact. There is no fallback to a hosted API.

**Connectivity.** Zero network calls at inference time.

**Data.** The training corpus is hand-authored rather than scraped. Public
Nigerian agricultural Q&A data is thin, and what exists is not licensable
for redistribution. Every record was written by the team against IITA,
NAERLS, and NAFDAC reference material, then passed through a five-stage
verification pipeline documented below. The corpus is released under
CC BY 4.0. Source documents remain the property of their respective
organisations and are used as factual reference only; none are redistributed.

### Data Verification Methodology

Every training record passed through a five-stage verification pipeline
before being admitted to the corpus.

1. **Candidate extraction.** Records drafted by the ARIS team against IITA,
   NAERLS, NAFDAC, and state ADP material. Each candidate carries a source
   citation and the specific claim it asserts.
2. **Consensus scanning.** Every candidate scanned against the canonical
   claims register (`provenance/dataset/canonical_claims.jsonl`), which
   carries per-record `status`, `conditions`, and `do_not_generalise`
   fields. Records flagged as blacklisted or unqualified conditionals were
   escalated.
3. **Human audit.** Escalated records reviewed against source citations and
   either corrected or removed.
4. **Structural encoding.** Verified records structurally encoded so the
   model learns the shape of a correct answer. Conditional facts are never
   stated as absolutes; fabrication-prone categories carry explicit
   refusal examples.
5. **Post-training contamination audit.** A four-level check (exact,
   normalized, bidirectional substring, near-duplicate Jaccard at 0.90)
   was run against the frozen evaluation matrix. Audit output is committed
   at `provenance/zero_leakage_audit.md`. One benign substring flag on the
   generic phrase "can you help me" and zero substantive overlaps.

---

## Benchmarks

**Measurement environment.** All numbers below were captured on the Kaggle
GPU runtime (4 vCPU, 2× Tesla T4, 32 GB host RAM) with the GPU disabled at
inference time to approximate the CPU-only target profile. These are
development measurements used to size the model against the 8 GB budget. The
authoritative measurements were produced by the ADTC profiler on the
participant laptop (Intel i5-8365U, 5.8 GB visible RAM, Ubuntu 22.04.5 LTS).

**ADTC profiler (participant mode) — authoritative numbers:**

| Metric | Value |
|---|---|
| Machine | Intel Core i5-8365U, Ubuntu 22.04.5 LTS, no GPU |
| RAM at peak | 1.65 GB (1,687.95 MB) |
| RAM steady state | 1.63 GB (1,632.47 MB) |
| Generation speed | 16.24 tokens/sec |
| First-token latency | 11,530 ms (cold, 512-token prompt) |
| ARC-Easy accuracy | 76.0% (acc_norm, 50 samples) |
| Thermal throttling | None |
| CPU p99 | 51.7% |

**Custom frozen evaluation** (131 records, 8 categories, strict rubric):

| Category | Weighted % | Pass / Total |
|---|---|---|
| capability_disclosure | 100.0% | 18 / 18 |
| diagnostic_uncertainty | 100.0% | 12 / 12 |
| safety_refusal | 94.0% | 47 / 50 |
| pidgin | 94.6% | 35 / 37 |
| identity | 90.9% | 10 / 11 |
| multi_turn | 80.0% | 12 / 15 |
| factual_recall | 71.4% | 25 / 35 |
| adversarial_blacklist | 67.6% | 75 / 111 |
| **Overall (strict)** | **81.0%** | 234 / 289 |
| **Overall (tolerant canonical)** | **87.9%** | 254 / 289 |

**Two honest numbers.** The strict rubric uses a keyword-exact grader that
rejects correct answers phrased differently from the rubric author's expected
wording. The tolerant canonical scorer is monotonic over strict and rescues
only wording equivalences, not factual errors. Every rescued record is
listed in `frozen_eval_tolerant.json` under the `rescued` key with its
answer excerpt for manual inspection. Records where the model stated a
factually incorrect answer fail under both rubrics.

**Adversarial red-team** (86 seen probes + 53 unseen probes):

| Battery | Probes | Failures |
|---|---|---|
| Seen | 86 | 4 |
| Unseen | 53 | 0 |

Four seen failures are documented with specific failure signatures in
`redteam_scored.json`.

---

These are self-reported development benchmarks. Official scores are measured
by the ADTC profiler on the standard evaluation machine. The authoritative
`submission.json` from the participant-laptop run is committed at the repo
root.
