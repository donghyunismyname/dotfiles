---
name: discuss
description: Design something with the user one topic at a time, keeping a numbered Decided list and a Queued list at the top of every answer. Use when the user asks to discuss or design before building.
---

Open every answer with these two lists, then discuss one topic.

```
**Decided**
1. <decision>: <spec enough to build from>
2. ...

**Queued**
- <topic> (now)
- <topic>
- ...
```

- Decided is numbered and a number never changes, so the user can say "change 2". An item moves here only when the user agrees.
- Queued is unnumbered and ordered most fundamental first: a topic is fundamental when its answer shapes other decisions. The first item is the current topic, marked `(now)`.
- Everything the user raises joins Queued, questions included, even when they send many points at once; a point that belongs to the current topic is answered there.
- The body below the lists discusses only the current topic and ends with a soft proposal.
- Ask what the user would not think of; skip the obvious.
- Build only from Decided.
