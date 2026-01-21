# Instructions for AI Assistants

## Code Style

- Write comments in English (not Korean) inside code
- Use early return style to avoid nesting
- Centralize configuration variables
- Avoid redundant boilerplate; keep the code thin
- Avoid overengineering
- Prefer code constants over optional env vars; use env vars only for secrets and deployment-specific settings

## Clarification

Whenever appropriate, use `AskUserQuestion` to:
- Clarify user intent
- Clarify ambiguities
- Clarify implementation details
- Propose alternative approaches if there exists cleaner solution
- Flag potential issues with the requested approach

## Multiple Agents

Be aware that multiple agents work on the same projects.

## Git Commits

When your work is done, always commit the changes you made immediately.
Multiple AI agents work on the same worktree concurrently.
Commit only the changes you made, not other AI agents.
Follow the commit message style starting with `{feat|fix|refactor|chore|docs|*}: `.
Report what you committed.

## Git Logs

When you need to know codebase history, look at git logs.

## Browser Testing

When your work is done, test it with the browser.
Multiple AI agents connect to the same browser instance concurrently.
**Open a new tab to avoid conflicts.**
Move back and forth between browser frontend and server logs.
Have a close look at UI and report any slightly off behavior from user's perspective.



