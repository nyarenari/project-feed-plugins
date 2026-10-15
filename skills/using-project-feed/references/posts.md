# Posts

A post is a dated update in one project that says what changed and what response is needed. Posts carry media, versions, comments, annotations, reactions, tags, and links to tasks.

## Write a good post

- Title: name the change, milestone, decision, or question. "Hero shot v3 ready for lighting review" beats "Update".
- Lead with the result and the response you need. Background goes after.
- Use dates, numbers, owners, and next steps. Break long material into headings and short lists.
- Attach the evidence: the screenshot, recording, build, model, or doc. Add before and after media when the comparison matters, and make sure the attached file is the one the text describes.
- Post when a milestone, decision, risk, or review state changes. Fold minor related changes into one post.
- Ask a specific person for a specific response and mention them. A reaction is enough for acknowledgment. Create a task when someone has to change something.

Avoid vague titles, several unrelated updates in one post, a large attachment with no change note or review request, and decisions that live only in comments.

## Draft first

`create_post` defaults to `status: "draft"`. A draft is visible only to its author: it is not in feeds, search, or file lists, and nobody is notified. Use that.

1. `create_post` with `projectId`, `title` (up to 500 characters), `content`, and `contentFormat: "markdown"`.
2. Upload files to the post (see [media.md](media.md)).
3. `get_post` and check the text, attachments, and project.
4. `update_post` with `status: "published"`. Followers are notified the first time a post is published.
5. Tell the user the post title and project. Return `webUrl` if they want a link.

`create_post` takes no idempotency key. Before retrying a failed create, `list_posts` with `status: "draft"` to check whether the first attempt landed.

## Edit or publish a version

| You want to | Use | Effect |
| --- | --- | --- |
| Fix a typo, clarify text, correct the project | `update_post` | Changes the current version in place. No change note, no media changes, no notification |
| Share revised work for another look | `publish_post_version` | New version number with its own title, content, media, and change note. Moves the post to the top of the feed and notifies followers |

Publish a version for every review round so reviewers can compare it with earlier ones. Earlier versions keep their own media and stay read only. There is no restore. To bring back old content, read it with `get_post_version` and publish it as a new version.

Only the post author can publish a version. Publishing a version of a draft also publishes the post.

`publish_post_version` fields:

- `postId` (required), `title` (up to 200), `content` (omit to keep the current text), `contentFormat`, `changeNote` (up to 500).
- `mediaIds`: the current media to keep, in order. Omit it to keep all current media. `[]` drops all.
- `uploads`: up to 10 `{uploadToken, parts}` from `prepare_media_upload`. Do not call `complete_media_upload` for these. The version claims them. If you already completed an upload, that file is on the current version, so list its ID in `mediaIds` instead.
- Kept media plus uploads can total at most 10 files.
- `idempotencyKey` (up to 100). Reuse it on retry. The same key with a different body is refused with `idempotency_key_reused`.

Write the change note as what changed for the reviewer: "Warmer key light, removed lens flare, fixed the logo kerning."

`list_post_versions` is newest first and its `cursor` is a version number. `get_post_version` takes exactly one of `versionId` or `number`.

## Other post fields

- `release`: optional release details on the post (not per version). `version` (up to 40 characters) and `type` (`release`, `beta`, or `alpha`) are required. `compatibility`, `downloadUrl` (https), and `downloadLabel` are optional. `update_post` replaces the whole object and `null` clears it.
- `projectId` on `update_post` moves the post and changes its audience to the destination project. Archived projects take no new posts.
- `update_post` with `status: "draft"` unpublishes. A copy shared to a client portal is separate and stays.
- `delete_post` is a soft delete with no API restore. Author or workspace admin only. Ask first.

## Comments

- `create_post_comment`: whole-post feedback or a reply (`parentId`). Up to 5,000 visible characters. Send an `idempotencyKey` (up to 128). Comments are limited to 20 a minute per person.
- Use `create_annotation` when a spot, time, frame, page, line range, or camera view matters. See [review.md](review.md).
- `list_post_comments` is oldest first. `replyCount` stops at 20. When `replyCountCapped` is true, read the thread with `parentId`.
- Only annotations can be resolved. Plain comments cannot.
- Keep one thread per question. Record the outcome by editing the post or adding a final comment with the decision and the linked task.

## Reactions

`toggle_post_reaction` and `toggle_post_comment_reaction` take a Unicode emoji or `custom:name`. A toggle adds when absent and removes when present, so after a dropped connection read `list_post_reactions` before toggling again.

## Tags

- `list_tags` with `projectId` returns the workspace tags plus that project's tags.
- `set_post_tags` replaces all tags on a post: `tagIds`, `tagNames`, or both, up to 50. `[]` clears. Only the author or a workspace admin can tag a post.
- Tag names are lowercase with hyphens. Reuse an existing tag before creating one with `create_tag`. Tags are categories, not status.

## Linking to tasks

`create_task_link` with `taskId` and `postId` links both ways: the post shows the task and the task shows the post. Turn an annotation into a task with `create_task_from_comment`. Keep follow-up work in tasks, not in a comment list.

## Following

`set_post_follow_state` with `following: false` mutes a post's notifications for the credential's user. It is per person and persists.
