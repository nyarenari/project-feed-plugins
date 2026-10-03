---
name: media-review-loop
description: Revise a video, image, or other media post from reviewer annotations until it is approved. Use when the user asks to iterate on a render with their feedback, address review comments on a video, or keep revising until approved.
---

# Media review loop

Publish media to a Project Feed post, wait for the human's annotations, change the work, publish the next version, and repeat.

## Publish

1. For a new piece of work, call `create_post` with a `projectId`, then upload each file with `prepare_media_upload` (destination `{type: "post", id: postId}`), transfer the bytes to the returned URL, and call `complete_media_upload`. Use `upload_media` only for small files.
2. For an existing post, call `list_post_versions` to find the current version, then call `publish_post_version` with the post ID, a short `changeNote`, and the new files in `uploads`. Pass `mediaIds` to drop media that the new version replaces.
3. Tell the human which post is ready (title and project) and which version, and ask them to review it in Project Feed.

## Wait

1. Call `wait_for_comments` with the `postId` and `annotated` set to true. It holds the request open for up to 50 seconds. Call it again with the returned `since` until comments arrive.
2. If the client supports MCP events, subscribing to `comment.created` is an alternative to waiting.
3. When comments arrive, call `list_post_comments` with `status` set to `open` and `annotated` set to true to get every open annotation, not only the new ones.

## Address each annotation

1. Read the anchor: `timeMs` and `endTimeMs` for video and audio, `frame`, `page`, `lines`, `x` and `y`, `camera`, and the `drawing`. Read `reviewStatus` too.
2. Call `get_annotation_frame` with the `commentId`. It returns the frame with the reviewer's marks and the anchors. When `source` is null there is no image, so work from the `drawing` and the anchors. When `marksDrawn` is false, read the image together with the `drawing`.
3. Make the change the annotation asks for.
4. Treat `needs_changes` as work to do. A `question` gets a reply and no change. A `comment`, `suggestion`, or `approved` annotation needs no change unless its text asks for one.

## Close the round

1. Publish the next version with `publish_post_version` and a `changeNote` that lists what changed.
2. For each annotation you addressed, call `create_post_comment` with `parentId` set to the annotation and one plain sentence on what changed, then call `resolve_post_comment`.
3. Leave a question unresolved. Reply to it and ask what you need to know.
4. Tell the human which version to review next, then go back to Wait.

## Stop

- Stop when no open `needs_changes` annotations remain. Say so and ask the human to approve.
- Stop and ask when feedback is ambiguous, conflicts with other feedback, or asks for something outside the request. Reply on the annotation and leave it open.
- Do not resolve an annotation you did not change the work for.
- Do not delete comments or media.
