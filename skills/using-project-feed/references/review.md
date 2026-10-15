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

- `list_post_comments` with `postId`, `annotated: true`, and `status: "open"` returns every open annotation, oldest first. Add `attachmentId` for one file.
- `get_post_comment` returns one annotation with its anchors, `reviewStatus`, reply count, and linked task.
- `get_annotation_frame` with `commentId` returns the picture the reviewer marked plus the anchors. Read it before changing visual work.
  - `source: "snapshot"` is the frame with the marks already drawn (`marksDrawn: true`).
  - `frame`, `video_thumbnail`, and `media` are the unmarked picture. Read it together with `annotation.drawing`.
  - `source: null` means no picture exists. Work from the anchors and the drawing.
  - It needs both `media:read` and `comments:read`.

## Wait for feedback

`wait_for_comments` holds the request open until new comments arrive on a post or the timeout passes.

- `postId` (required), optional `attachmentId`, `annotated`, and `timeoutSeconds` (0 to 50, default 25).
- Pass the returned `since` into the next call unchanged. Without `since`, it waits for comments created after the call starts.
- `annotated: true` skips replies. Leave it off when you also need replies to your own answers.
- When comments arrive, re-read the full open set with `list_post_comments`, not only the new ones.

MCP event subscriptions are off on the hosted server, so `wait_for_comments` is the way to wait. Between rounds, if the human is not reviewing right away, stop and tell them what to review instead of waiting in a loop.

## The review loop

Use this when the user asks you to iterate on a render, image, video, model, or document until it is approved.

1. **Publish.** New work: `create_post`, upload the files, publish. Existing post: `publish_post_version` with the new files in `uploads`, `mediaIds` for the files to keep, and a `changeNote`.
2. **Ask.** Tell the human which post (title and project) and which version is ready, and what kind of feedback you want.
3. **Wait.** `wait_for_comments` with `annotated: true`, repeating with the returned `since`.
4. **Read.** `list_post_comments` with `status: "open"` and `annotated: true`. For each, read the anchors and call `get_annotation_frame`.
5. **Change.** Address every `needs_changes`. Answer every `question`. Take `suggestion` items that fit.
6. **Publish the next version** with a `changeNote` listing what changed.
7. **Close the round.** For each annotation you addressed, reply with `create_post_comment` (`parentId` set to the annotation) in one plain sentence about the change, then `resolve_post_comment`. Leave questions open after replying.
8. Go back to step 2.

Stop when no open `needs_changes` remain, and ask the human to approve. Stop and ask when feedback is ambiguous, conflicts with other feedback, or goes beyond the request. Reply on the annotation and leave it open.

Never resolve an annotation you did not address. Never delete reviewers' comments or the files they reviewed.

## Give feedback

When the user asks you to review someone's media:

- `create_annotation` with `postId`, `attachmentId` (from `get_post` or `list_media`), the anchors, `reviewStatus`, and `content`. Send an `idempotencyKey`.
- Pin the exact subject. One issue per annotation.
- Use `needs_changes` only when a revision is required. Use `question` when you need an answer and `suggestion` for optional ideas.
- Use a plain post comment for feedback about the whole update.
- Comments, including annotations, are limited to 20 a minute per person.

`update_post_comment` can change `content`, `reviewStatus`, and the anchors `x`, `y`, `timeMs`, `frame`, `endFrame`, `page`, `camera`, and `drawing`. Only the author can edit content or move anchors. The annotation author, the post author, or an admin can change `reviewStatus` and resolve.

## Tasks from feedback

When an annotation needs an owner or a schedule, `create_task_from_comment` with `commentId` and `title` creates a task in the post's project linked to the post, or links an existing `taskId`. Calling it again returns the same task. Update the task after you verify the fix.

## Client portals

Guests in a client portal review shared posts too. When the team asks for a decision, the guest sees Approve and Request changes. Guest feedback moves through Requested, Fixing, Sent, and Checked, and the guest confirms with "It's fixed" or "Still not right". Publishing a new workspace version does not update the portal copy. A person shares the new version to the portal.
