# Instructions for AI Assistants

## Code Style

- Avoid overengineering
- Write comments in English (not Korean) inside code
- Use early return style to avoid nesting
- Avoid redundant boilerplate; keep the code thin
- Centralize configuration variables
- Prefer code constants over optional env vars; use env vars only for secrets and deployment-specific settings

## Code Review Behavior

When implementing code, proactively use `AskUserQuestion` to:
- Suggest better variable/function/file names before writing them
- Propose alternative approaches if you see a cleaner solution
- Clarify ambiguities
- Flag potential issues with the requested approach

## Git Commits

When your work is done, always commit the changes you made immediately.
Multiple AI agents may work on the same worktree concurrently.
Commit only the changes you made, not other AI agents.
Report what you committed.

## Git Logs

When you need to know the changes other agents made, look at git commit logs.

## Browser Testing

When your work is done, test it with the browser.
Multiple AI agents may connect to the same browser instance concurrently.
Open a new tab to avoid conflicts.
When testing is done, close the tab you opened.
Never close the tab if you didn't open it.
Move back and forth between browser frontend and dev server logs.



