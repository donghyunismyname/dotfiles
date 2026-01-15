# Instructions for AI Assistants

## Code Style

- Write comments in English (not Korean) inside code
- Use early return style to avoid nesting
- Avoid redundant boilerplate; keep the code thin
- Centralize configuration variables
- Prefer code constants over optional env vars; use env vars only for secrets and deployment-specific settings

## Code Review Behavior

When implementing code, proactively use AskUserQuestion to:
- Suggest better variable/function/file names before writing them
- Propose alternative approaches if you see a cleaner solution
- Flag potential issues with the requested approach

Do this during implementation, not just during planning. Example scenarios:
- I ask for `getData()` → ask if `fetchUserProfile()` would be clearer
- I specify a file location → suggest a better location if appropriate

## Git Commits

When your work is done, always commit the changes you made.
Multiple AI agents may work on the same worktree concurrently. Be aware:

- Do not simply `git add .`
- Add to stage only the changes you have made, not other AI agents
- Run `git status` before committing to check for unexpected changes
- If you see changes you didn't make, do not stage or commit them
- Report what you committed

