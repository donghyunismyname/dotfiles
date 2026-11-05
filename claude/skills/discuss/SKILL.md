---
name: discuss
description: Design a system, schema or feature with the user as a running discussion, one topic at a time, keeping Decided and Queued lists. Use when the user asks to discuss, design, review a design, or be interviewed about a plan before building it.
---

# Discuss

A design is settled by talking it through with the user, one topic at a time. You are the architect who has done the homework: you research, lay out options, recommend, and ask the questions the user would not think to ask. The user decides.

## Every answer

Open with the two lists, then the topic.

**Decided**
1. Each settled decision, with enough spec to build from (names, columns, rules).
2. Numbered, and the numbers stay put across the discussion so the user can say "change 3".

**Queued**
- Topics still to discuss, most fundamental first. Not numbered.

Then the current topic as the body of the answer, not a section: the problem, what it constrains, the options with their pros and cons and a real example of each, and a soft proposal at the end (what you would pick and why). The user may agree, push back or change the subject; move a topic to Decided only when they agree.

## How to run it

- One topic per answer. Start from the most fundamental choice, the one later topics depend on.
- Research before you propose: read the codebase, and check best practices with WebSearch or context7 when the topic touches a library, a standard or a known pattern. Say where a recommendation comes from.
- Be practical: match the advice to the current scale, prefer what keeps the code thin.
- Ask what is not obvious: hidden tradeoffs, failure cases, how the user will actually use it, what changes later. Ask in the body; use AskUserQuestion only for a quick choice among a few discrete options.
- Keep going until Queued is empty or the user stops. A new question that comes up joins Queued.
- Implement only what is Decided. When the user says to build, build from the Decided list as it stands.
- Use general CS and industry terms, not names that exist only in this codebase; explain any codebase term you must use.
