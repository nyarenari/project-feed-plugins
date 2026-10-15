---
name: work-triage
description: Reviews and organizes a Project Feed task backlog by finding duplicates, stale or ownerless work, overdue items, and vague tasks, then proposes a prioritized queue. Use when the user asks what to work on next, wants the backlog cleaned up, deduplicated, or reprioritized, asks "what's stuck", or needs a sprint or weekly queue from Project Feed tasks.
---

# Work triage

Triage is a proposal first and a change second. People rely on task history, so nothing changes until the user agrees, and nothing gets deleted.

## Gather

1. Confirm the scope: which project, or all projects the user can see.
2. Read `backlog`, `todo`, `in_progress`, and `in_review` with `list_tasks`, one status per call. Follow `nextCursor` until `hasMore` is false. Pages can be short or empty while more rows remain.
3. Open a task with `get_task` before judging it. A title alone is not enough to call two tasks duplicates.

## Find

| Problem | Signal |
| --- | --- |
| Duplicate | Same outcome, even with different wording. Read both descriptions |
| Stale | `in_progress` with no `updatedAt` change in about two weeks, or no recent comments |
| No owner | Empty `assigneeIds` on `todo` or `in_progress` work |
| Overdue | `dueDate` in the past and status not `done` or `cancelled` |
| Vague | No description, no way to verify, or a title that is an activity rather than an outcome |
| Blocked | A comment or description says it waits on something |

## Propose

Return an ordered queue and a list of proposed changes. For each, give the identifier, title, the change, and a one-line reason.

```
Queue
1. PRO-51 Fix login loop (urgent, due Oct 16)
2. PRO-47 Upload retries (high, unblocked by PRO-46 yesterday)

Proposed changes
- PRO-38: cancel as duplicate of PRO-47 (same retry work, PRO-47 has the newer spec)
- PRO-29: move to backlog (no update since Sep 2, no owner)
- PRO-33: needs an owner and a way to verify
```

Order by priority (`urgent`, `high`, `medium`, `low`, `none`), then due date, then whether the task is unblocked and ready.

## Apply

Only after the user agrees, or when they already gave exact instructions:

- Use `bulk_update_tasks` for status, priority, assignee, or project changes across many tasks (up to 50 per call). `status` and `assign` changes are all or nothing. Others report `succeeded` and `failed` per task.
- For a duplicate, comment on it with `create_task_comment` naming the task you kept, then set it to `cancelled`. Cancelled tasks keep their history.
- Never delete tasks during triage, and never set `done` on someone else's work.
- Report what changed and anything that failed.
