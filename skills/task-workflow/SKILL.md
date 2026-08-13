---
name: task-workflow
description: Work from a Project Feed task and keep its status, checklist, and comments current. Use when a user names a Project Feed task or asks Cursor to fix, build, implement, investigate, or pick up tracked work.
---

# Task workflow

Use Project Feed as the record of the work while completing the user's request.

## Start

1. If the user gave a task identifier, call `get_task` and `list_checklist_items`.
2. Otherwise, search open work with `list_tasks`. Reuse a clear match. If no task matches, create one when the target project is clear or ask the user which project to use.
3. Read the task description, project, status, assignee, checklist, and recent comments before changing it.
4. Move a selected `todo` task to `in_progress` when implementation begins.
5. Add checklist items for the work that remains if the checklist is empty or stale.

## Work

- Check an item only after that milestone is complete.
- Leave short comments at meaningful checkpoints. Include the result, verification, and next step.
- Keep unrelated repository changes out of the task.
- Ask before changing ownership, priority, dates, or project unless the user requested it.
- Do not mark a task `done` unless the user explicitly asks.

## Finish

1. Confirm the requested work and validation are complete.
2. Check completed checklist items and keep any real remaining work unchecked.
3. Add a final comment with what changed and what was verified.
4. Move the task to `in_review` when the implementation is ready for review.
5. Leave it `in_progress` if work remains.
