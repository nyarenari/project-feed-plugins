# Docs

Docs are pages for briefs, specs, decisions, and runbooks that people read in order and keep current. Posts report progress and canvases arrange material on a board. Search for an existing doc before creating one.

## Structure

- A **space** holds docs. The workspace has its own spaces and each project has a space. `list_doc_spaces` with `projectId` finds a project's spaces.
- Docs nest under other docs through a parent. `create_doc` always creates at the top level of the space. Call `move_doc` with `parentId` afterwards to nest it.
- Doc `visibility` is `public`, `shared`, or `private`. Public and shared docs are visible to everyone who can see the space. Private docs are visible only to owners, admins, the creator, and people it is shared with. None of them publish outside the workspace.

## Read

- `list_docs` with `spaceId` and `state` (`active` or `archived`) returns docs without content. Page with `nextCursor`.
- `get_doc` returns the content as Plate JSON plus `contentText`.
- `list_doc_versions` is newest first. Its `cursor` is a version number.

## Write

- `create_doc` with `spaceId`, `title`, `content`, and `contentFormat: "markdown"`. Content can be up to 1 MB.
- `update_doc` changes title, icon, `fullWidth`, or visibility. Changing visibility needs manage access.
- `update_doc_content` replaces the whole body. Pass a `changeNote`.
- `duplicate_doc` copies content, icon, and visibility into "Title (copy)" but not subdocs or comments.

### Replacing content safely

`update_doc_content` overwrites everything, including unsaved edits in an open editor, and closes editor sessions. There is no version check. The last write wins.

1. `get_doc` and `list_doc_versions` first, so you know the current state.
2. Avoid replacing a doc while teammates are editing it. Ask when in doubt.
3. Replace with a `changeNote`.
4. If the result is `pending`, `get_doc` again before building on it. If another replace is in progress the call fails. Wait and retry once.
5. If the replace was wrong, `restore_doc_version` records the old version as a new one, so history is kept.

Because the body is replaced whole, read the current content, apply your change to it, and send the full result. Do not send only the new section.

## Move, lock, archive, delete

- `move_doc` moves a doc with its subdocs. Omitting `parentId` or sending `null` puts it at the top level. A move that changes who can see the doc needs manage access.
- `lock_doc` and `unlock_doc` are for owners and admins. A locked doc can be edited only by them.
- `watch_doc` subscribes the credential's user to changes.
- `archive_doc` removes a doc from navigation and keeps its history. Check subdocs and links first.
- `delete_doc` is permanent and refused while the doc has subdocs. Ask before deleting.
- Spaces: `archive_doc_space` archives every doc in it in the background. `restore_doc_space` does not restore the docs. `delete_doc_space` requires an archived space with no docs at all, archived ones included.

## Comments

- `create_doc_comment` with `docId`, `content`, and optional `parentId` for a reply. Threads are one level deep.
- An inline comment takes `anchorId` and `anchorExcerpt` (the text the comment is about, up to 200 characters). The highlight is added after the comment saves.
- `resolve_doc_comment` and `reopen_doc_comment` act on the whole thread.
- `list_doc_comments` is newest first.

## Files

Insert an image or file into a doc with `prepare_media_upload` and `destination: {type: "doc", id, afterBlockId}`. See [media.md](media.md).
