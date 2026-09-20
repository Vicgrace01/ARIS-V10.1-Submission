# Unseen Red-Team Battery — Contamination Audit

- Original battery: 53 prompts, SHA 8d08903bc00829dc9c6c35af7c87372a2bc987becaf8794341ee4b6a125af997
- Exact leaks removed: 0
- Substring leaks removed: 0
- Final battery: 53 prompts, SHA 8d08903bc00829dc9c6c35af7c87372a2bc987becaf8794341ee4b6a125af997

## Method

Each unseen prompt was compared against every user-role prompt in the training corpus using exact string match and substring containment. The final SHA-256 is computed over the post-filter battery so it matches the prompts actually executed.
