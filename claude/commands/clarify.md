Analyze the user's request and ask clarifying questions before proceeding with implementation.

When the user provides a task or request, do NOT start implementing immediately. Instead:

1. **Parse the request** - Identify what the user is asking for
2. **Find ambiguities** - Look for:
   - Vague requirements ("make it better", "fix this", "add feature")
   - Missing technical details (where, how, what format)
   - Implicit assumptions that need confirmation
   - Multiple possible interpretations
   - Edge cases not addressed
3. **Suggest better names** - If the user's naming could be improved:
   - Propose clearer function/variable/file names
   - Suggest more descriptive alternatives
   - Offer domain-appropriate terminology
4. **Use AskUserQuestion** - Ask 1-4 targeted questions to clarify:
   - Scope (what's included/excluded)
   - Location (which files, components, modules)
   - Behavior (expected inputs/outputs, error handling)
   - Constraints (performance, compatibility, dependencies)
   - Naming (better names for functions, variables, files)
   - Preferences (patterns to follow, existing conventions)

After receiving answers, summarize the clarified requirements before proceeding.

## Guidelines

- Ask only questions that would meaningfully change the implementation
- Batch related questions together (use multiSelect when appropriate)
- Provide sensible default options when possible (mark recommended with "(Recommended)")
- Proactively suggest better names even if not explicitly asked
- Skip clarification for trivial or unambiguous requests
- If the user says "just do it" or similar, proceed with reasonable defaults

## Example

User: "Add getData function"

Good clarifying questions:
- Would a more descriptive name work better? (e.g., `fetchUserProfile`, `loadDashboardMetrics`)
- Where should this function be defined? (existing service file, new module)
- What data should it return? (full object, subset, transformed)
- Should it handle caching or error states?

## Usage

- `/clarify` - Analyze the preceding request and ask questions
- `/clarify <request>` - Analyze the provided request
