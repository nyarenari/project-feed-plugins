---
name: project-status
description: Summarize Project Feed project health and recent progress. Use for standups, status reports, weekly updates, blockers, overdue work, or a concise project briefing.
---

# Project status

Report what changed and what needs attention.

1. Resolve the requested project with `list_projects` and `get_project`.
2. Load open tasks across relevant statuses. Follow pagination until there is enough evidence for the requested report.
3. Read task details and comments for high-priority, blocked, overdue, or recently active work.
4. Separate completed work, active work, blockers, and next decisions.
5. Name task identifiers for claims that a reader may want to open.
6. Do not infer completion from a branch, commit, pull request, or green check alone. Use the task state and available evidence.
7. If the user asks to publish an update, draft it first and confirm the target before calling a write tool.

Keep the report brief unless the user asks for a detailed review.
