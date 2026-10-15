---
name: task-workflow
description: Works from a Project Feed task and keeps its status, checklist, and comments current while the agent codes, fixes, or investigates. Use whenever a user names a task (PRO-123, task 42, "the onboarding task"), asks an agent to pick up, fix, build, implement, or investigate tracked work, or wants an agent's progress recorded in Project Feed, even if they never say "task".
---

# Task workflow

The task is the shared record of the work. People and other agents read it to see who is on what, what is done, and what is left, so keep it true while you work instead of updating it once at the end.

## Start

1. Find the task. If the user named one, call `get_task` with what they gave you. It accepts the internal ID, an identifier like `PRO-123`, or a task number like `42` (pass `42`, not `#42`). Otherwise use `search`, or `list_tasks` with `projectId` and `status`, and reuse a clear match.
2. Keep the internal `id` from `get_task` and pass it as `taskId` from then on. `update_task`, `add_checklist_item`, `create_task_comment`, `create_subtask`, and the tag tools reject identifiers with "Invalid tool arguments."
3. Read before changing: description, status, assignees, `list_checklist_items`, and recent `list_task_comments`.
4. If someone else moved it to `in_progress` recently, or another agent is commenting on it, ask before taking it over.
5. When nothing fits, `create_task` with `projectId` and `title`, and ask which project if that is unclear. Write the description in Markdown (`descriptionFormat: "markdown"`) covering scope, expected behavior, and how to verify.
6. Move it to `in_progress` when you start changing things.
7. If the checklist is empty or stale, add one `add_checklist_item` per real milestone. Write items as outcomes someone can check ("Upload rejects files over 1 GiB"), not activities ("Look at the code").

## While working

- Check an item with `update_checklist_item` and `checked: true` as soon as that milestone is done and verified. A checklist updated only at the end tells nobody anything in the meantime.
- Comment at checkpoints with `create_task_comment`: what changed, how you verified it, what is next. Include commit SHAs and pull request URLs. Send an `idempotencyKey` and reuse it on a retry so a dropped connection does not post the comment twice.
- Separable remaining work, such as something with its own owner or schedule, becomes a subtask (`create_task` with `parentTaskId`), not a line buried in a comment.
- For visual work, attach a screenshot or recording with `prepare_media_upload` and `destination: {type: "task", id}`.
- Keep unrelated changes out of the task.
- Ask before changing assignees, priority, dates, or project unless the user asked. Editing the description of a task someone else created can return 403.

## Finish

| Situation | Status |
| --- | --- |
| Planned work is done and verified, and every finished item is checked | `in_review` |
| Work remains, or you are stopping partway | Stay `in_progress`, with the remaining items unchecked |
| The user explicitly says it is done | `done` |

Leave a final comment with what changed and what you verified before moving to `in_review`.

Never set `done` on your own. A person decides when work is accepted, and `done` also completes the task's open subtasks and cancels its unfinished handoffs.
