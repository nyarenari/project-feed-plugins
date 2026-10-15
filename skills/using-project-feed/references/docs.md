# Docs

Docs are pages for briefs, specs, decisions, and runbooks that people read in order and keep current. Posts report progress and canvases arrange material on a board. Search for an existing doc before creating one.

## Structure

- A space holds docs. `list_doc_spaces` lists them, and with `projectId` it lists a project's spaces. A project may have none yet. Create one with `create_doc_space` and `projectId` (space `visibility` is `shared` or `private`).
- Docs nest under other docs. `create_doc` always creates at the top level of the space, so call `move_doc` with `parentId` afterwards to nest it.
- Doc `visibility` is `public` (the default), `shared`, or `private`. Public and shared docs are visible to everyone who can see the space. Private docs are visible to owners, admins, the creator, and people it is shared with. Pass `visibility: "private"` when the content is sensitive. None of these publish outside the workspace.

## Read

- `list_docs` with `spaceId` and `state` (`active` or `archived`) returns docs without content. Pass `nextCursor` back as `cursor` while `hasMore` is true.
- `get_doc` returns the content as Plate JSON blocks plus plain `contentText`.
- `list_doc_versions` is newest first. Page with its `nextCursor`.

## Write

- `create_doc` with `spaceId`, `title`, `content`, and `contentFormat: "markdown"`. Content can be up to 1 MB.
- `update_doc` changes title, icon, `fullWidth`, or visibility. Changing visibility needs manage access.
- `update_doc_content` replaces the whole body. Pass a `changeNote`. It returns `{status, generation, version}`.
- `duplicate_doc` copies content into "Title (copy)" but not subdocs or comments.

### Replacing content safely

`update_doc_content` overwrites the whole body, including edits people are making in an open editor. There is no version check, so the last write wins.

1. `get_doc` and `list_doc_versions` first, so you know the current state.
2. Avoid replacing a doc while teammates are editing it. Ask when in doubt.
3. Build the full new body from the current one. Do not send only the new section, or everything else disappears.
   - To keep all existing formatting, edit the Plate JSON from `get_doc` and send it back with `contentFormat: "platejs"`.
   - For a simple doc, rewriting the whole page as Markdown with `contentFormat: "markdown"` is fine.
4. Replace with a `changeNote` that says what changed.
5. If `status` is `pending`, live editors are still merging the change. Call `get_doc` again before building on it. If another replace is in progress the call fails. Wait and retry once.
6. If the replace was wrong, `restore_doc_version` with the earlier `version` brings it back.

## Move, lock, archive, delete

- `move_doc` moves a doc with its subdocs. Omitting `parentId` or sending `null` puts it at the top level, so to reorder a doc inside its parent, send the same `parentId` with the new `position`. `spaceId` moves it to another space. A move that changes who can see the doc needs manage access.
- `lock_doc` and `unlock_doc` are for owners and admins. Only they can edit or move a locked doc.
- `watch_doc` marks a doc as Watching in the Docs directory for the signed-in person.
- `archive_doc` removes a doc from navigation and keeps its history. `restore_doc` brings it back. Check subdocs and links before archiving.
- `delete_doc` is permanent and refused while the doc has subdocs. Ask before deleting.
- Spaces: `archive_doc_space` archives every doc in it. `restore_doc_space` does not restore the docs, so restore them one by one. `delete_doc_space` requires an archived space with no docs at all, archived ones included.

## Comments

- `create_doc_comment` with `docId`, `content`, and optional `parentId` for a reply. Threads are one level deep.
- `anchorId` and `anchorExcerpt` store which text a comment is about, but through the API they do not add a highlight to the page. Quote the exact text in the comment itself so readers can find it.
- `resolve_doc_comment` and `reopen_doc_comment` act on the whole thread. `update_doc_comment` edits your own comment.
- `list_doc_comments` is newest first.

## Files

Insert an image or file into a doc with `prepare_media_upload` and `destination: {type: "doc", id, afterBlockId}`. Omit `afterBlockId` to append. It needs `docs:write` as well as `media:write`. See [media.md](media.md).
