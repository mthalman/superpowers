# Superpowers Repository Memory

## Python Script Execution

### UTF-8 Encoding

When executing Python scripts in this repository, always use UTF-8 mode to handle Unicode characters (emojis, special symbols) in output and file operations:

```bash
PYTHONUTF8=1 python script.py
```

**Why:** Windows console defaults to cp1252 encoding, which doesn't support Unicode characters. The `PYTHONUTF8=1` environment variable enables Python's UTF-8 mode for both console output and file I/O operations.

**Examples:**
- Running init_skill.py: `PYTHONUTF8=1 python skills/skill-creator/scripts/init_skill.py skill-name --path skills`
- Any Python script that uses emojis or non-ASCII characters in print statements or file writes

## PowerShell Usage

The repository uses PowerShell for scripts and automation. When creating new skills or utilities, prefer PowerShell (.ps1) over Python for better Windows integration.
