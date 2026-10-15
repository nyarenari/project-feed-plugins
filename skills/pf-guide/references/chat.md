# Chat

Chat is for open questions that need replies or a decision. Progress goes in posts, and feedback about one post or file goes in its comments.

## Model

- One Workspace room (`kind: general`) and one room per project. There are no direct messages.
- A root message starts a discussion. Replies go in that discussion. Discussions are `open` or `resolved`.
- Discussions can link to posts, tasks, canvases, docs, and projects.
- Chat must be on for the workspace. Otherwise chat tools return `feature_disabled`. An empty `list_chat_rooms` is normal before anyone has used chat. `get_chat_room` opens or creates a room.

## Discuss an item

Before starting a discussion about a post, task, canvas, doc, or project:

1. `list_object_discussions` with `objectType` and `objectId` (internal IDs). Each discussion has a `roomId` and a `threadId`.
2. If one exists, reply with `send_chat_message`, passing both `roomId` and `threadId`.
3. If not, `start_object_discussion` with `objectType`, `objectId`, `content`, a `title`, and an `idempotencyKey`. It opens in the item's project room, or the Workspace room for items outside a project, with the item linked. It returns the discussion as `id` plus `roomId`.
4. When the question is answered, `update_chat_thread` with `roomId`, `threadId`, and `status: "resolved"`.

## Send

- `get_chat_room` with `projectId` (omit for the Workspace room) returns the `roomId`.
- `send_chat_message` with `roomId` and `content`. Omit `threadId` to start a discussion (with an optional `title`). Set it to reply. Replying to a resolved discussion reopens it.
- `links`: up to 5 `{objectType, objectId, label}` items.
- Send an `idempotencyKey` (up to 128) and reuse it on retry.
- New discussions are limited to 4,000 visible characters. Replies in a discussion that mirrors a post, task, or doc thread follow that item's comment limit. Everyone shares a limit of 30 messages a minute per person.
- To mention someone, send a plain string with `@username` and leave `contentFormat` unset. Look up usernames with `list_members`.
- Files attach to a message that already exists. Send the message, then `prepare_media_upload` with `destination: {type: "chatMessage", id: messageId}`. Files cannot be added when editing a message.

## Read

- `list_chat_rooms`, then `list_chat_threads` with `roomId` and `status`, `pinned`, or `following` filters. Keep paging while `nextCursor` is set.
- `list_chat_messages` with `roomId` and optional `threadId`. Use `beforeMessageId` or `afterMessageId` to page.
- Message and thread IDs belong to one room. Passing the wrong `roomId` returns 404.

## Manage

- `update_chat_thread` renames, resolves, reopens, pins, or follows. Only owners and admins pin, up to 5 per room. The discussion author and admins resolve.
- `edit_chat_message` edits your own messages. `delete_chat_message` leaves a placeholder.
- `link_chat_thread_object` adds a linked item. `list_chat_thread_links` returns each link's `linkId`, which `remove_chat_thread_link` needs. The item a discussion started from cannot be unlinked.
- `agentId` on `send_chat_message` posts as an approved chat agent identity. It is for workspace owners and admins with a configured agent, cannot be combined with `title`, `links`, or `replyToMessageId`, and its messages cannot be edited. Ignore it otherwise.
