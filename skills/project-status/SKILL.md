---
name: project-status
description: Summarizes a Project Feed project's health and recent progress from its tasks and posts. Use for standups, status reports, weekly updates, "what changed this week", blockers, overdue work, release readiness, or a quick briefing on any Project Feed project, and when the user wants that summary posted back to Project Feed.
---

# Project status

Report what changed and what needs attention, backed by items the reader can open.

## Gather

1. Resolve the project with `list_projects`. Ask if the name matches more than one.
2. Pick the window. Use the one the user gave, otherwise the last 7 days.
3. Tasks: `list_tasks` takes one `status` per call, so read `in_progress`, `in_review`, `todo`, and `done` separately. Follow `nextCursor` until `hasMore` is false. Pages can be short or empty while more rows remain. The list is ordered by creation, not by update, so a task created months ago and finished yesterday can sit on the last page. If a project is too large to read fully, say how far you got.
4. Posts: `list_posts` for the project is newest first. Read the ones published in the window. They usually say what shipped and what is waiting for review.
5. Open the details that matter: `get_task` and `list_task_comments` for urgent, high-priority, overdue, and blocked work, and `list_post_comments` with `status: "open"` and `annotated: true` for posts waiting on review.

## Judge

- Done in the window: `done` tasks whose `completedAt` falls in it.
- Overdue: `dueDate` before today and status not `done` or `cancelled`. Tasks without a due date are never overdue.
- Stale: `in_progress` with no `updatedAt` change in the window.
- Blocked: a comment or description says so. Quote it rather than guessing.
- Waiting on review: `in_review` tasks, and posts with open `needs_changes` or `question` annotations.

Do not infer completion from a branch, commit, pull request, or green check. Report the task state and say where the evidence differs.

## Report

```
<Project> status, <window>

Done
- PRO-41 Export as CSV

In progress
- PRO-44 Upload retries (Sam, due Oct 18)

Needs attention
- PRO-39 Invite emails: overdue since Oct 10, no update in 9 days
- "Hero lighting v3": 2 open needs_changes annotations

Next decisions
- Whether PRO-45 ships in this release
```

Skip empty sections. Name every item with its identifier or post title. Keep it to a screen unless the user asks for more.

## Posting it

If the user wants the update in Project Feed, `create_post` in the project as a draft with `contentFormat: "markdown"`, show the draft, and publish with `update_post` and `status: "published"` only after they confirm. Publishing notifies the project's followers.
