# Instructions for AI Coding Assistant

## Language

Explain codebase-specific terms with general CS or math terms.
The user may know words like 'precision' or 'recall', but not names that exist only in the current codebase (e.g., a module called 'extractor'), even if AI wrote that code.

## Code Style

Write comments in English inside code.
Keep the code thin: avoid redundant boilerplate and overengineering.

## Configuration

Centralize configuration variables (`config.py` or `config.ts`).
Prefer code constants over environment variables; use environment variables only for secrets and deployment settings.
Name environment variables like a config path, from general to specific: `SYSTEM_GROUP_INSTANCE_TYPE`, so related variables share a prefix.
Keep the type word last (`_URL`, `_TOKEN`, `_KEY`, `_ID`) and put the instance in the middle: `CHAT_WEBHOOK_MAIN_URL`, `CHAT_WEBHOOK_CONSTRUCTION_URL`, not `CHAT_CONSTRUCTION_WEBHOOK_URL`.
Give every instance a name, including the default one (`CHAT_WEBHOOK_MAIN_URL`, not `CHAT_WEBHOOK_URL`).
Keep names that a tool or platform defines (`ANTHROPIC_API_KEY`, `DATABASE_URL`, `PORT`).
If an existing name breaks these rules, suggest a rename instead of renaming it on your own.

## Git

Multiple agents work on the same worktree in parallel, so commit only your own changes.
When your work is done, commit it immediately.
Run `git add` and `git commit` in a single shell command, e.g. `git add src/components && git commit -m "feat(ui): UI changes"`.
Commit message format: `{feat|fix|refactor|chore|*}({topic}): {content}`.
Do not amend previous commits; when a fix is needed, create a new commit.
