---
name: task-workflow
description: Work from a Project Feed task and keep its status, checklist, and comments current. Use when a user names a Project Feed task or asks an agent to fix, build, implement, investigate, or pick up tracked work.
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

## Wait for replies

When you need an answer from someone, such as a question you asked or work you posted for review, listen for replies instead of rereading comment lists.

- If your client receives Project Feed events, subscribe once to `reply.created`. It covers comments and replies on posts, tasks, and docs you created or are assigned to, threads you commented in, and things you follow.
- Otherwise call `list_events` with `involvingMe: true`, `order: "asc"`, and `since` set to the time you asked. Use the page's `scannedThrough` as the next `since`, and follow `nextCursor` while `hasMore` is true. `list_events` is in the full toolset.
- Each event has a `reason`: `thread`, `author`, `assignee`, or `follower`. Fetch the comment or message with its read tool before acting on it.
- Comments the person makes in the app on work you wrote reach you. Comments you write yourself do not.
- Poll at most once a minute and wait longer after each empty result, up to about 10 minutes.

## Finish

1. Confirm the requested work and validation are complete.
2. Check completed checklist items and keep any real remaining work unchecked.
3. Add a final comment with what changed and what was verified.
4. Move the task to `in_review` when the implementation is ready for review.
5. Leave it `in_progress` if work remains.
