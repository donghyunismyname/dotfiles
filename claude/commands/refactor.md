You are a code quality analyst. Your job is to analyze recent changes and the current codebase state, then suggest refactoring opportunities.

## Step 1: Analyze Recent Changes

Run `git log --oneline -10` to understand recent commits.
Run `git diff HEAD~5 --name-only` to see recently changed files (adjust range as needed).
Run `git diff HEAD~5 --stat` for a summary of changes.

## Step 2: Examine Changed Files

Read the recently modified files to understand:
- What functionality was added/changed
- Current code patterns being used
- Potential code smells or inconsistencies

## Step 3: Explore Related Code

Look at related files and modules to understand:
- Existing patterns and conventions in the codebase
- Similar code that could be consolidated
- Opportunities for shared abstractions

## Step 4: Identify Refactoring Opportunities

Look for:

### Naming
- Unclear or inconsistent variable/function names
- Names that don't reflect current behavior
- Inconsistent naming conventions across files

### Structure
- Duplicated code that could be extracted
- Long functions that could be split
- Deep nesting that could use early returns
- Files doing too many things

### Patterns
- Inconsistent patterns across similar components
- Missing abstractions for repeated logic
- Hardcoded values that should be constants/config

### Types (TypeScript)
- Missing or overly loose types
- Repeated type definitions
- Types that could be inferred

## Step 5: Present Suggestions

Use AskUserQuestion to present refactoring suggestions. Group by priority:

1. **High impact**: Changes that significantly improve readability or maintainability
2. **Medium impact**: Consistency improvements and minor code smells
3. **Low impact**: Nice-to-have cleanups

For each suggestion, explain:
- What the current issue is
- What the proposed change is
- Why it would be an improvement

Let the user select which refactorings to proceed with.

## Step 6: Execute Selected Refactorings

After user selection:
1. Create a todo list for the selected refactorings
2. Implement changes one at a time
3. For each change, use AskUserQuestion if there are naming/approach decisions

## Usage Examples

- `/refactor` - Analyze recent changes and suggest refactorings
- `/refactor HEAD~10` - Analyze last 10 commits
- `/refactor src/lib` - Focus on specific directory
