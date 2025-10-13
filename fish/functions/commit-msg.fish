function commit-msg --argument extra
   set dirs (dirname (git diff HEAD^ --name-only) | sort -u)
   set examples (git log  --no-merges --pretty=format:"<subject>%n%s%n</subject>%n<body>%n%b%n</body>%n%n" -- $dirs | grep -v 'Signed-off' | head -n 200)
   set system (echo "Based on the provided diff, output a commit subject and body according to the guidelines below. Output NOTHING else except the commit subject and its body.
1. The commit messages follow a consistent format: `<component>: <short summary>` in the subject line
2. The components are typically namespaced with slashes where appropriate, like `c8d/list`, `daemon/c8d`, `integration-cli`, etc.
3. The subject line is concise and describes the change in imperative mood (Fix, Add, Update, etc.)
4. The commit body provides detailed explanation of:
   - What the issue was
   - Why the change is needed
   - How the change addresses the problem
   - Any technical details important for understanding the change
   - HOWEVER, it should not blindly translate the code diff to natural language.
5. For bug fixes, the body often includes:
   - Description of the bug behavior
   - Root cause analysis
   - The specific changes made to fix it
   - Sometimes error logs or code snippets demonstrating the issue
6. For new features, the body explains:
   - What the feature does
   - Why it's needed
   - How it's implemented
   - Any backward compatibility considerations
7. When updating dependencies, the message includes:
   - Full diff link
   - Brief summary of important changes
   - Occasionally CVE references for security fixes
8. The commits tend to be focused on a single logical change or related changes to one component
9. Tone is technical and matter-of-fact, focused on clarity for other developers
This style resembles standard Go project commit convention with a focus on being informative while maintaining readability.

- **Component/Area**: Mentioning specific components or areas being modified, e.g., `registry`, `libnet`, `daemon`, `integration-cli`.
- **Action**: Involves verbs like `Fix`, `Update`, `Move`, `Remove`, `Add`, `Improve`, indicating the primary action taken.
- **Purpose/Additional Info**: Offers details or reasons for the change or specifies changes in dependencies or tools, like version updates.
- **Testing/Cleanup**: Indicating changes to tests or cleanup in code, e.g., `TestStopContainerWithTimeout: Increase timeout`.
- **Dependency Management**: Usage of `vendor:` prefix indicating dependency updates. 
- **Formatting/Linting**: Specifics about code style improvements or compliance with linters.
- **Reverts**: Clearly marked with `Revert`.
- **Experimental/Deprecation**: Flags that indicate feature warnings or deprecated elements.
- **CI/Tooling**: Changes in Continuous Integration setups or development tooling.
- **Documentation**: Begins with `docs/` or `api` indicating updates to documentation.

Here's some additional context for the commit from the human:
<extra_context>
$extra
</extra_context>

Below are example commit subjects and bodies enclosed in corresponding HTML tags (don't output tags for the result though)
$examples
" | jq -R -s)

   set prompt (git diff -U15 --cached | jq -R -s)

   if test -x /usr/bin/security
      set token (security find-generic-password -w -s Anthropic)
   end
   if test -z "$token" && command -v pass &>/dev/null
      set token (pass show Anthropic)
   end

   curl -s https://api.anthropic.com/v1/messages \
      --header "x-api-key: $token" \
      --header "anthropic-version: 2023-06-01" \
      --header "content-type: application/json" \
      --data \
'{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 4096,
    "messages": [
        {"role": "assistant", "content": '$system'},
        {"role": "user", "content": '$prompt'}
    ]
}' | jq -r '.content[].text' | vim --headless -c "normal! ggVGgq" -c 'w! /dev/stdout' -c 'q'  - 2>/dev/null

end
