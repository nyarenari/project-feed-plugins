---
name: plan-project
description: Turns a feature, bug, spec, or project brief into a Project Feed task plan with clear tasks, checklists, and subtasks. Use when the user wants to plan work, break down a feature, build or refill a backlog, scope a milestone, or create implementation tasks in Project Feed, including when they paste a brief and say "make tasks for this".
---

# Plan project work

Write a plan that someone else can pick up without reopening this conversation. Every task should say what done looks like.

## Steps

1. Find the project with `list_projects`. Ask if the brief could belong to more than one.
2. Look for existing work before creating anything: `search` the key terms and `list_tasks` for the project in `backlog`, `todo`, and `in_progress`. Extend or reference existing tasks instead of duplicating them.
3. Split the work into outcomes that can each be reviewed on their own. Small dependent steps inside one outcome are checklist items. Work that needs its own owner, schedule, or discussion is a subtask.
4. If the plan is large (roughly more than eight tasks) or the brief leaves real choices open, show the outline and ask before creating it. A short outline is cheaper to fix than twenty tasks.
5. Create each task with `create_task`:
   - `title`: the outcome in plain words ("Export project as CSV", not "CSV stuff").
   - `description` with `descriptionFormat: "markdown"`: scope, expected behavior, constraints, out of scope, and how to verify.
   - `parentTaskId` for subtasks. The parent must be in the same project and cannot itself be a subtask.
   - `priority`, dates, estimates, `assigneeIds`, and `tagNames` only when the brief supports them. Leave `status` at the default `todo`, or use `backlog` for work that is not ready.
6. Add checklist items with `add_checklist_item` using the internal `id` returned by `create_task`.
7. Project Feed has no dependency field. Write ordering in the description ("Blocked by PRO-12: needs the export endpoint") and create blocking work first so its identifier exists. When the plan came from a post, link each task to it with `create_task_link`.
8. Return the plan as a list of identifiers and titles, grouped the way you split it, followed by the decisions still open.

## Keep it honest

Do not invent requirements, estimates, or owners to make the plan look complete. When the brief is silent, record the open question in the task description and list it in your reply.
