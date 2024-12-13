# Getting Your GitHub Token

To analyze repositories, you'll need a GitHub personal access token. Here's how to get one:

1. Go to [GitHub Settings > Developer Settings > Personal Access Tokens > Tokens (classic)](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give your token a descriptive name (e.g., "Code Changes Analyzer")
4. **Important**: For security reasons, you don't need to select any permissions! Leave all checkboxes unchecked since we only need to read public repositories.
5. Click "Generate token"
6. **Copy your token immediately**! GitHub will only show it once.

⚠️ Security Tips:
- Never share your token or commit it to version control
- If you only analyze public repositories, don't grant any additional permissions
- If you suspect your token has been compromised, revoke it immediately and generate a new one

The token will look something like this: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
