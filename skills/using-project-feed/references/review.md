# Media review and annotations

An annotation is a comment pinned to one file on a post: a point on an image, a time in a video, a frame of a sprite, a page of a PDF, a line range in code, or a camera view of a 3D model. Reviewers leave them in the file viewer. Agents can read, answer, resolve, and create them.

## Review status

Each annotation has a `reviewStatus`:

| Value | Meaning | What an agent does |
| --- | --- | --- |
| `needs_changes` | A revision is required | Change the work |
| `question` | The reviewer needs an answer | Reply. Change nothing unless the answer leads to a change |
| `suggestion` | Optional improvement | Do it if it fits the request, otherwise reply |
| `comment` | General feedback (default) | Act only if the text asks for something |
| `approved` | Accepted | Nothing |

Resolution is separate from status. `resolved` means the feedback was addressed, and approving does not resolve. Only annotations can be resolved. Replies resolve with their annotation.

## Anchors

Set only the anchors that fit the file. Anchors that do not apply come back `null`.

| Field | Unit | Media |
| --- | --- | --- |
| `x`, `y` | Percent (0 to 100) of width and height from the top-left | Images, video frames, PDF pages, any visual file |
| `timeMs`, `endTimeMs` | Milliseconds from the start. `endTimeMs` must be after `timeMs` | Video, audio, Lottie, Rive |
| `frame`, `endFrame` | 0-based frame | Sprites, GIFs, animated 3D models |
| `page` | 1-based page | PDF and documents. Not combined with `frame` |
| `lines` | `{start, end, selectedText}`, 1-based | Text and code files |
| `camera` | `position` and `target` as `[x, y, z]` in model units, plus optional `fov`, `worldPosition`, `meshName`, `materialName` | 3D models |
| `drawing` | Marks drawn on the frame | Any visual file |

`drawing` is `{version: 1, tool, color, strokeWidth, shapes}`. `tool` is `pin`, `draw`, `arrow`, `line`, or `rect`. Shapes:

- pin: `{id, type: "pin", point: {x, y}}`
- freehand: `{id, type: "freehand", points: [{x, y}], color, strokeWidth}`
- arrow, line, rect: `{id, type, start: {x, y}, end: {x, y}, color, strokeWidth}`

Drawing points are fractions (0 to 1), unlike `x` and `y`, which are percentages. Colors: `#ff4fd8`, `#f59e0b`, `#22c55e`, `#60a5fa`, `#ffffff`, `#ef4444`. Stroke widths: 2, 3, 4, 5, 6, 8. Up to 50 shapes and 500 points per freehand shape. Every shape needs an `id`.

On 3D models a drawing belongs to the saved camera view and does not wrap the surface. On sprites an annotation belongs to its frame and does not follow a moving feature.

## Read feedback

- `list_post_comments` with `postId`, `annotated: true`, and `status: "open"` returns open annotations, oldest first, up to 100 per page. Follow `nextCursor`. Add `attachmentId` for one file.
- Annotations left on earlier versions stay open until someone resolves them, and their `attachmentId` still points at the older file.
- `get_post_comment` returns one annotation with its anchors, `reviewStatus`, reply count, and linked task.
- `get_annotation_frame` with `commentId` returns the picture the reviewer marked, the anchors, and a signed `imageUrl`. It needs both `media:read` and `comments:read`.
  - `source: "snapshot"` is the frame with the marks already drawn (`marksDrawn: true`).
  - `frame`, `video_thumbnail`, and `media` are the unmarked picture. Read it together with `annotation.drawing`.
  - `source: null` means no picture. Either the file has no viewable frame, or the current version dropped the file. For a dropped file, `get_post_version` with the earlier `number` still has its signed `url`.

Read every frame you need before publishing a version that drops the file it belongs to.

## Wait for feedback

`wait_for_comments` holds the request open until new comments arrive on a post or the timeout passes.

- `postId` (required), optional `attachmentId`, `annotated`, and `timeoutSeconds` (0 to 50, default 25).
- It returns `{comments, since}`. Pass `since` into the next call unchanged. Without `since`, it waits only for comments created after the call starts, so anything posted while you were away is missed. Use `list_post_comments` to catch up first.
- `annotated: true` skips replies. Leave it off when you also need replies to your own answers.
- When comments arrive, re-read the full open set with `list_post_comments`, not only the new ones.

MCP event subscriptions are off on the hosted server, so `wait_for_comments` is the way to wait. If the human is not reviewing right away, stop and tell them what to review instead of waiting in a loop.

## The review loop

Use this when the user asks you to iterate on a render, image, video, model, or document until it is approved.

1. Publish. New work: `create_post`, upload the files, then publish with `update_post` and `status: "published"`. Existing post: `publish_post_version` with the new files in `uploads`, `mediaIds` for the current files to keep, a `changeNote`, and an `idempotencyKey`.
2. Tell the human which post (title and project) and which version is ready, and what kind of feedback you want.
3. Wait with `wait_for_comments` and `annotated: true`, repeating with the returned `since`.
4. Read the open set with `list_post_comments` (`status: "open"`, `annotated: true`). For each, read the anchors and call `get_annotation_frame`.
5. Change the work. Address every `needs_changes`, answer every `question`, and take `suggestion` items that fit. When the user supplies the revised file, check it against each annotation, and resolve only what it visibly fixes.
6. Publish the next version with a `changeNote` listing what changed.
7. For each annotation you addressed, reply with `create_post_comment` (`parentId` set to the annotation) in one plain sentence about the change, then `resolve_post_comment`. Leave questions open after replying.
8. Go back to step 2.

Stop when no open `needs_changes` remain, and ask the human to approve. Stop and ask when feedback is ambiguous, conflicts with other feedback, or goes beyond the request. Reply on the annotation and leave it open.

Never resolve an annotation you did not address. Never delete reviewers' comments or the files they reviewed.

## Give feedback

When the user asks you to review someone's media:

- Get the file's `attachmentId` from `list_media` with `postId`. `get_post` does not list files.
- `create_annotation` with `postId`, `attachmentId`, the anchors, `reviewStatus`, and `content`. `content` can be empty when a drawing says it all. Send an `idempotencyKey`.
- Pin the exact subject. One issue per annotation.
- Use `needs_changes` only when a revision is required. Use `question` when you need an answer and `suggestion` for optional ideas.
- Use a plain post comment for feedback about the whole update.
- Comments, including annotations, are limited to 20 a minute per person.

`update_post_comment` changes `content` and `reviewStatus` at the top level. Moving an annotation goes inside `annotation`: `{annotation: {x, y, timeMs, frame, endFrame, page, camera, drawing}}`. Anchors sent at the top level are rejected, and `endTimeMs` and `lines` cannot be changed after creation. Only the author can edit content or move anchors. The annotation author, the post author, or an admin can change `reviewStatus` and resolve.

## Tasks from feedback

When an annotation needs an owner or a schedule, `create_task_from_comment` with `commentId` and `title` creates a task in the post's project linked to the post. Pass `taskId` instead to link an existing task. Calling it again returns the same task. Use the returned task's `id` for follow-up writes, and update the task after you verify the fix.

## Client portals

Guests in a client portal review shared posts too. When the team asks for a decision, the guest sees Approve and Request changes. Guest feedback moves through Requested, Fixing, Sent, and Checked, and the guest confirms with "It's fixed" or "Still not right". There are no portal tools, so an agent cannot share to a portal or read portal state. Publishing a new workspace version does not update the portal copy. Tell the person to share the new version to the portal.
