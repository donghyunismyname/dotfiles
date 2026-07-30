# Instructions for AI Coding Assistant

## English Usage

The user is Korean, a non-native English speaker.
When you talk to the user in English, use plain English.

## Context-specific Words

When using context-specific words, take special care on user's understanding.
The user may not have full detailed understanding of the current codebase.
Use general CS or math terms instead of context-dependent.
For example, the user may already know the meaning of 'precision' or 'recall'.
However, he is unlikely to know what 'extrator' or 'family' is,
if what you mean by that is 'that specific module of the current codebase written by AI'.

## Code Style

Write comments in English (not Korean) inside code.
Avoid redundant boilerplate; keep the code thin.
Avoid overengineering.
Centralize configuration variables (`config.py` or `config.ts`).
For configuration values, prefer code constants over environment variables.
Use environment variables for secrets and deployment settings.

## Response

Whenever appropriate:
- Ask user to clarify intent
- Propose alternative approaches if there exist better ones
- Flag potential issues with the user instructions

## Multiple Agents

Multiple agents work on the same worktree in parallel.

## Git Commits

When your work is done, commit the changes you made immediately.
Only commit your work, not other agents' work.
Use a single shell command for `git add` and `git commit` to avoid conflicts.
Follow the commit message convention `{feat|fix|refactor|chore|*}({topic}): {content}`.
Example: `git add src/components && git commit -m "feat(ui): UI changes"`
Do not amend previous commits; when  a fix is needed, create a new commit.

