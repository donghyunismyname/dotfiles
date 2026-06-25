# Instructions for AI Assistants

## Communication Style

The user is Korean, a non-native English speaker.
When you talk to the user in English, use plain English.

## Code Style

- Write comments in English (not Korean) inside code
- Centralize configuration variables
- Avoid redundant boilerplate; keep the code thin
- Avoid overengineering
- Prefer code constants over optional env vars; use env vars only for secrets and deployment-specific settings

## Clarification

Whenever appropriate, use `AskUserQuestion` to:
- Clarify user intent
- Clarify ambiguities
- Propose alternative approaches if there exists cleaner solution
- Flag potential issues with the requested approach

## Multiple Agents

Multiple agents work on the same worktree in parallel.

## Git Commits

When your work is done, always commit the changes you made immediately.
Only commit the changes you made.
Use a single shell command for `git add` and `git commit` to avoid conflicts.
Example command: `git add src/components && git commit -m "feat(ui): UI changes"`
Do not amend previous commits.
Follow the commit message prefix convention `{feat|fix|refactor|chore|*}({object}): `.
Example: `feat(crawler): Skip notifications`


