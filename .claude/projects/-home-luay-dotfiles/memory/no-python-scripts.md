---
name: no-python-scripts
description: "User is not a Python developer; write scripts in Bash, Node only as fallback, never Python"
metadata:
  node_type: memory
  type: feedback
  originSessionId: c5e1b842-bd59-4bc5-a218-cf7dd931e44a
  modified: 2026-11-18T14:15:08.651Z
---

Write scripts (hooks, tooling, helpers) in Bash. If Bash really can't do it, use Node. Never Python.

**Why:** the user doesn't know Python and wants to read and maintain every script themself. Stated 2026-11-18 when a Python hook was drafted for [[configure-claude-walkthrough]] item #4.
**How to apply:** default to Bash + standard CLI tools (jq, grep, sed, awk); reach for Node only when Bash would be unreasonably complex.
