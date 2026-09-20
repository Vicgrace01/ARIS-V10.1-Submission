# ARIS V10.1 Datasets

## Composition

| Split | File | Records |
| :--- | :--- | ---: |
| Training | train_chatml_v10_4_clean.jsonl | 2017 |
| Validation | val_chatml_v8_final.jsonl | 204 |
| Evaluation (held out) | ARIS_EVAL_FROZEN_V2.jsonl | 131 |

### Training set
- **Format:** ChatML JSONL (list of messages with role and content)
- **SHA-256:** a37d1677f8b896b99f602c5242172d9059ab30e6b8ab67c421f446b6483af31c

### Validation set
- **SHA-256:** 3a898c9c8170397db4b3ab4325b2c574afaca84babe780f2df68db6b9dbbc8ab
- Established during the v8 development cycle and reused across v10 and v10.1
  so validation loss remained comparable across training runs.
- Disjoint from the training corpus at the primary question level

### Evaluation set
- Originally 153 records. A four-level contamination audit
  (exact, normalized, substring, near-duplicate Jaccard >= 0.90) removed
  16 records whose prompts overlapped with the training set (pass 1),
  and a second pass removed 6 more whose prompts overlapped with the
  validation set (pass 2). Both cleanup passes are documented in
  `provenance/eval_cleanup_report.md` and
  `provenance/eval_cleanup_report_v2.md`.

## Source
Authored in-house by the ARIS team, grounded in institutional reference material from:
- IITA (International Institute of Tropical Agriculture)
- NAERLS (National Agricultural Extension and Research Liaison Services)
- NAFDAC (National Agency for Food and Drug Administration and Control)

## Content
Synthetic agronomic advisory conversations covering yam and cassava cultivation,
spacing, seedbed selection, disease identification (CMD, CBSD, YMV, MSV), pest
vectors, chemical safety boundaries, livestock health, and Nigerian Pidgin fluency.

## License
Original ARIS training conversations are released under CC BY 4.0 for the ADTC
2026 submission. Source materials from IITA, NAERLS, and NAFDAC remain the
property of their respective organisations and are used as factual reference
only. No source documents are redistributed.
