---
name: plan-project
description: Turn a feature, bug, or project brief into a Project Feed task plan. Use when the user wants to plan work, break down a feature, build a backlog, or create implementation tasks.
---

# Plan project work

Build a plan that another person can execute without reopening the original conversation.

1. Find the target project with `list_projects`. Ask the user if the project is ambiguous.
2. Search existing tasks before creating anything. Do not create duplicates.
3. Split work by outcomes that can be reviewed independently. Keep small dependent steps as checklist items on the parent task.
4. Give each task a plain title and a description covering scope, expected behavior, constraints, and verification.
5. Set priority, dates, estimates, and assignees only when the user supplied enough information.
6. Link dependent or related tasks when the available tools support it.
7. Return the created or updated task identifiers and note any decisions still needed.

Do not invent requirements to make the plan look complete. Record open decisions in the relevant task instead.
