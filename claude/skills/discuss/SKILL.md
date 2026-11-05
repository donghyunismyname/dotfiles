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
- Queued is unnumbered and ordered by how fundamental a topic is: fundamental means its answer shapes other decisions. Every new point or question joins it, also when the user sends many at once; questions are discussion too.
- The top Queued item, marked `(now)`, is the one topic of this answer: the body below the lists. End it with a soft proposal.
- Ask what the user would not think of; skip the obvious.
- Build only from Decided.
