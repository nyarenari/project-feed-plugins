# Tasks

A task is an outcome someone needs to track. Discussion stays on the post, comment, or annotation that raised it. The task records who owns the work, where it stands, and how to verify it.

## Fields

| Field | Values |
| --- | --- |
| `status` | `backlog`, `todo` (default), `in_progress`, `perpetual`, `in_review`, `done`, `cancelled` |
| `priority` | `none` (default), `low`, `medium`, `high`, `urgent` |
| `title` | Up to 500 characters |
| `description` | String or Plate JSON. Set `descriptionFormat` to `markdown`, `plaintext`, or `platejs` |
| `startDate`, `dueDate` | Unix milliseconds |
| `estimatePoints` | 0 to 10000 |
| `estimateMinutes` | 0 to 100000. Refused when the workspace has time tracking off |
| `assigneeIds` | Up to 20 user IDs from `list_members` or `list_project_members` |
| `tagIds`, `tagNames` | Up to 50 combined on create |

Status meanings: `backlog` is captured but not ready, `todo` is ready to pick up, `perpetual` is ongoing work that never completes, `in_review` means the work is finished and waiting for a person, `done` is finished and verified, `cancelled` keeps abandoned work for history.

Side effects to know before changing status:

- Setting a parent to `done` completes its open subtasks.
- Moving a task to `done` or `cancelled` cancels its unfinished handoffs.

## IDs

A task has three handles: the internal `id`, the `identifier` (`PRO-42`, the project prefix plus a number), and the `taskNumber` people write as `#42`. Posts in the same project draw from the same identifier sequence, so `PRO-43` may be a post.

- `get_task` accepts all three: the `id`, `PRO-42` (any case), or `42`. Pass `42`, not `#42`.
- Write tools need the internal `id`. `update_task`, `add_checklist_item`, `create_task_comment`, `list_subtasks`, and the tag tools reject identifiers with "Invalid tool arguments."
- The handoff tools accept identifiers and task numbers.

So when the user names a task, call `get_task` with `taskId` set to what they gave you, then pass the returned `id` as `taskId` everywhere after that. If "Invalid tool arguments." comes back from a task tool, you probably passed an identifier.

## Find before you create

1. `search` with `types: ["task"]` for the title, or `list_tasks` with `projectId` and `status`.
2. `list_tasks` returns newest first, excludes subtasks, and can return a short or empty page when rows from hidden projects are filtered out. Keep passing `nextCursor` as `cursor` until `hasMore` is false.
3. Reuse a clear match. Create a task only when nothing fits, and ask which project to use if that is unclear. Every task needs a project.

## Write a good task

- Title: the outcome in plain words, not a log line.
- Description: scope, expected behavior, constraints, how to verify, and the links the assignee needs. Markdown works with `descriptionFormat: "markdown"`.
- Checklist: the steps to finish. Items are text plus `checked`, with no owner or status.
- Subtask: separable work that needs its own owner, status, schedule, or discussion. Up to 50 per parent and no nesting.
- Tags: shared categories. Never a stand-in for status or priority.
- Set dates, estimates, priority, and assignees only when the user gave you enough to set them.

## Work a task

1. Read it first: `get_task`, `list_checklist_items`, and `list_task_comments` (newest first).
2. If another agent or person moved it to `in_progress` recently, ask before taking it over.
3. Move it to `in_progress` with `update_task` (`taskId` set to the internal `id`, `status: "in_progress"`) when you start changing things.
4. If the checklist is empty or stale, add one item per real milestone with `add_checklist_item`.
5. Check items with `update_checklist_item` as each milestone lands, not in a batch at the end.
6. Comment at checkpoints with `create_task_comment`: what changed, how you verified it, and what is next. Put commit SHAs and pull request URLs in the comment. Agents cannot add commit or PR references directly. Those come from connected integrations.
7. Create subtasks for separable remaining work instead of burying it in a comment.
8. Attach screenshots or recordings for visual work: upload with `destination: {type: "task", id}`. A task holds up to 10 attachments.

## Finish a task

- Move to `in_review` when the planned work is complete and verified, every finished checklist item is checked, and a final comment says what changed and how it was checked.
- Leave it `in_progress` while real work remains, and keep those items unchecked.
- Set `done` only when a person explicitly asks. Same for `cancelled`.
- Ask before changing assignees, priority, dates, or project unless the user requested it.

## Tool notes

| Tool | Notes |
| --- | --- |
| `create_task` | `title` and `projectId` required. `parentTaskId` creates a subtask with full fields. The parent must be in the same project and cannot be a subtask |
| `update_task` | Send at least one field. `null` clears `assigneeId`, `startDate`, `dueDate`, `estimatePoints`, or `estimateMinutes`. `assigneeIds` replaces the whole list. Setting `projectId` moves the task with its subtasks. A subtask cannot move alone. No tag fields, use the tag tools |
| `move_task` | Board position. Send at most one of `beforeTaskId`, `afterTaskId`, or `index`. Anchors must be in the destination column |
| `bulk_update_tasks` | `action` is `status` (with `status`), `priority` (with `priority`), `assign` (with a single `assigneeId`, or `null` to unassign), `move_project` (with `projectId`), or `delete`, for 1 to 50 `taskIds`. `status` and `assign` are all or nothing. The others report `succeeded` and `failed` per task. Prefer it over many single calls |
| `delete_task`, `restore_task` | Trash and restore, subtasks included. Tags removed by the delete do not come back. Restore a parent before its subtasks |
| `create_subtask` | Quick subtask with title, status, priority, and assignees. Use `create_task` with `parentTaskId` for description, dates, tags, or estimates |
| `update_checklist_item` | Applies `checked` before `text`. Not atomic |
| `move_checklist_item` | One of `beforeItemId`, `afterItemId`, or `index` |
| `create_task_comment` | Markdown or Plate, up to 10,000 visible characters. `parentId` replies. Send an `idempotencyKey` and reuse it on retry. The same key with different content is refused. Comments on tasks synced with GitHub or Jira are forwarded there |
| `delete_task_comments` | Up to 10 per call. Repeat while `hasMore` is true |
| `create_task_link`, `list_task_links`, `remove_task_link` | Link the task to the post it came from |
| `list_task_references` | Docs, posts, and tasks that mention this task, plus external commits, pull requests, issues, and files |
| `add_task_tag`, `set_task_tags`, `remove_task_tag` | Exactly one of `tagId` or `tagName` on add. `remove_task_tag` takes `tagId` only. A project tag only fits tasks in its project. `set_task_tags` replaces the set |
| `toggle_task_reaction` | Adds if absent, removes if present. Read before toggling so a retry does not undo it |
| `create_task_from_comment` | With `commentId` and `title`, creates a task in the post's project linked back to the post. With `taskId` instead, links an existing task. Annotations only. Calling it again returns the same task. Use the returned `id`, not the identifier, for follow-up writes |

## Permissions

Members can change the status and priority of any task they can see. Editing other fields, deleting, and restoring are for the task's creator and workspace owners or admins, so expect a 403 when editing someone else's task description. Viewers are read only. Writes need a Pro or Enterprise workspace.

## Time tracking

Time tools need time tracking enabled in the workspace, and their `taskId` must be the internal `id`. An identifier returns "Task not found".

- `create_time_entry`: `taskId` and `durationSeconds` (1 to 86400), optional `occurredOn` and `note`. Log only time that reflects real work. Split anything over 24 hours.
- `start_timer`, `get_timer`, `stop_timer`: one running timer per person. A second start returns 409, so stop first. `stop_timer` logs the entry. Its `durationSeconds` can only shorten the run. Timers stop on their own at 24 hours.
- `list_time_entries` with `taskId` or `projectId` shows everyone's time. Without either it shows your own.
- Only the person who logged an entry, or an owner or admin, can edit or delete it.
