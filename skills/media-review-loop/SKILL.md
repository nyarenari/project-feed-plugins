---
name: media-review-loop
description: Publishes a render, image, video, 3D model, animation, or document to a Project Feed post, then revises it from reviewers' annotations version by version until it is approved. Use when the user asks to share work for review and iterate on the feedback, address annotations or review comments on a post, "keep revising until approved", or run a review round on media in Project Feed.
---

# Media review loop

Publish the work, collect annotations, change the work, publish the next version, close the feedback you addressed, and repeat until nothing needs changes.

Annotations are comments pinned to one file: a point (`x`, `y` in percent), a time (`timeMs`), a frame, a page, a line range, or a 3D `camera`, often with a `drawing` of marks. Each has a `reviewStatus`: `needs_changes`, `question`, `suggestion`, `comment`, or `approved`.

## 1. Publish

- New work: `create_post` (a draft by default) with `projectId`, `title`, and Markdown `content`. Upload each file: `prepare_media_upload` with `destination: {type: "post", id: postId}`, transfer the bytes as `transfer.type` says, then `complete_media_upload`. Publish with `update_post` and `status: "published"`.
- Next round on an existing post: prepare and transfer the new files, then `publish_post_version` with `uploads: [{uploadToken}]` (add `parts` for `put` and `multipart` transfers), `mediaIds` listing current files to keep (`[]` drops them all), a `changeNote` saying what changed, and an `idempotencyKey`. Do not call `complete_media_upload` for files you pass in `uploads`.
- Only the post's author can publish versions.

Tell the human which post (title and project) and which version is ready, and what kind of feedback you want.

## 2. Wait

Call `wait_for_comments` with `postId`, `annotated: true`, and `timeoutSeconds: 50`. It returns new comments or an empty list, plus a `since` value. Pass `since` back unchanged on the next call.

MCP event subscriptions are off on the hosted server, so this is the way to wait. If several waits come back empty and the human is not reviewing right now, stop and tell them what is ready instead of looping.

## 3. Read every open annotation

When something arrives, read the whole open set, not only the new comments:

1. `list_post_comments` with `postId`, `annotated: true`, and `status: "open"`. Annotations left on earlier versions stay open until someone resolves them.
2. For each one, read the anchors and call `get_annotation_frame` with its `commentId`. With `source: "snapshot"` the marks are already drawn on the image. With `frame`, `video_thumbnail`, or `media`, read the image together with `annotation.drawing`. With `source: null` there is no picture, so work from the anchors.
3. Read all frames before you publish the next version. Once a version drops a file, `get_annotation_frame` returns no image for annotations on it. `get_post_version` with the earlier `number` still lists that file.

## 4. Change the work

| Status | Action |
| --- | --- |
| `needs_changes` | Change the work |
| `question` | Reply with the answer. Change nothing unless the answer leads to a change |
| `suggestion` | Take it if it fits the request. Otherwise reply with why not |
| `comment`, `approved` | Act only if the text asks for something |

Stop and ask the human when feedback is ambiguous, conflicts with other feedback, or goes beyond what they asked for. Reply on the annotation and leave it open.

## 5. Close the round

1. Publish the next version as in step 1. List the changes in `changeNote`.
2. For each annotation you addressed, reply with `create_post_comment` (`parentId` set to the annotation) in one plain sentence about what changed and in which version. Then call `resolve_post_comment`.
3. Leave questions open after answering, so the reviewer can confirm.
4. Tell the human which version to review next, then go back to step 2.

## Stop

Stop when no open `needs_changes` annotations remain, say so, and ask the human to approve.

Never resolve an annotation you did not address, and never delete reviewers' comments or the files they reviewed. Resolving is a claim that the feedback was handled.
