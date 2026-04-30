# Instructions for AI Assistants

## Communication Style

The user is a non-native English speaker. Write in plain English:

- Short sentences. One idea per sentence.
- Common words over fancy ones (`use` not `leverage`, `about` not `regarding`).
- No idioms, no figures of speech.

This applies to chat replies, not to code or commit messages.

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

Multiple agents work on the same projects in parallel.

## Git Commits

When your work is done, always commit the changes you made immediately.
Multiple agents work on the same worktree concurrently and you only commit the changes you made.
Use a single shell command for `git add` and `git commit` to avoid conflicts.
Example command: `git add src/components && git commit -m "feat(ui): UI changes"`
Do not amend previous commits.
Follow the commit message prefix convention `{feat|fix|refactor|chore|*}({object}): `.
Example commit message: `feat(crawler): skip notifications`

## Git Logs

When you need to know codebase history or the work done by other agent, look at git logs.

## Browser Testing

When your work is done, test it with the browser.
Multiple agents connect to the same browser instance concurrently.
**Open a new tab to avoid conflicts.**
Move back and forth between browser frontend and server logs.
Have a close look at UI and report any slightly off behavior from user's perspective.
Do not save screenshots to project root.



