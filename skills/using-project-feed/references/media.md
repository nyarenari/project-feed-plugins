# Media and files

Files attach to posts, tasks, comments, chat messages, canvases, and docs. Project Feed renders most of them in a viewer that people can annotate.

## What renders

| `fileType` | Formats |
| --- | --- |
| `image` | JPG, PNG, GIF, WebP, SVG, AVIF, HEIC, HEIF |
| `video` | MP4, MOV, WebM, MKV, and more. Plays once processing finishes |
| `audio` | MP3, M4A, WAV, OGG, Opus, FLAC, AAC, AIFF |
| `document` | PDF |
| `model` | GLB, glTF (buffers and textures embedded as data URIs), OBJ, FBX, STL, PLY, USD, USDA, USDZ, DAE, 3DS, 3MF, AMF, WRL, STEP, IGES, BREP |
| `animation` | Rive `.riv` |
| `lottie` | Lottie JSON. Pass `mediaType: "lottie"` to `prepare_media_upload`, or `upload_media` detects it from the content |
| `file` | Everything else. Text and code under 2 MB, Office files, and CSV open in a viewer. Archives, `.lottie`, `.blend`, `.max`, `.c4d`, `.dwg`, and other native project files are download only |

Download-only files cannot be annotated. When you want feedback on a native project file, upload a rendered image, video, or GLB of it as well.

## Upload a file

Never put file bytes in tool arguments. Prepare, transfer the bytes over HTTP, then complete.

1. `prepare_media_upload` with:
   - `destination: {type, id}`. Types: `post`, `task`, `comment` (post comment), `taskComment`, `chatMessage`, `canvas`, `doc`. Extra placement fields go inside `destination`: `afterBlockId` for docs (omit to append), and `x`, `y`, `width`, `height`, `frameId` for canvases (default 0, 0, 400, 300).
   - `fileName` (up to 255 characters, no slashes), `fileSize` (exact bytes, up to 1 GiB), and `mimeType` if you know it.
   - Docs, chat, and canvas destinations also need `docs:write`, `chat:write`, or `canvas:write`.
2. Transfer according to `transfer.type`:

   | Type | How |
   | --- | --- |
   | `form` | `POST` multipart to `url` with the file in a field named `file`. Small images usually get this |
   | `tus` | Video. TUS 1.0: `HEAD` for `Upload-Offset`, then `PATCH` from that offset with `Content-Type: application/offset+octet-stream`, `Tus-Resumable: 1.0.0`, and `Upload-Offset` |
   | `put` | `PUT` the body to `url` with `transfer.headers`. Keep the `ETag` response header |
   | `multipart` | `PUT` each byte range to its `parts[i].url` with `transfer.headers`. Keep each `ETag` |

   Send Project Feed credentials only to Project Feed, never to the transfer URL.
3. `complete_media_upload` with `uploadToken`, plus `parts: [{partNumber, etag}]` for `put` and `multipart`. Completing is safe to retry with the same token.
4. Status `ready` means done. `processing` means a video is still encoding. `pending` then `attached` is a doc insert saving. After a dropped connection, `get_media_upload` reports where it got to.

Upload tokens last 6 hours. Each prepare call makes a new token, so prepare again only when you need a new upload.

To add files to a new post version, prepare with `destination: {type: "post", id: postId}`, transfer, and pass `{uploadToken}` (plus `parts` for `put` and `multipart`) in `publish_post_version.uploads` without calling complete. See [posts.md](posts.md).

If your client cannot make HTTP requests or read local files, it cannot upload. Use the `pf` CLI (`pf media upload <file> --post <id>`), which runs all three steps.

## Small files without a transfer

`upload_media` takes `postId`, `fileName`, `mimeType`, and base64 `fileData` for one post: up to 50 MiB, no raster images and no video. It suits SVG, PDF, audio, Rive, Lottie, 3D, and text. It is limited to 50 uploads an hour per key and is unavailable in workspaces with encrypted media. Prefer the prepare flow for anything large.

## Limits

- Up to 10 files per post version, comment, task, task comment, and chat message.
- Uploads are refused when the workspace is out of storage.
- Image settings (avatar, logos, project images, custom reactions) take PNG, JPEG, GIF, or WebP and become public.
- Only the post author can upload to a post. Anyone who can edit a task can upload to it.

## Read and delete

- `list_media` with `postId` lists the files on the post's current version. `get_media` reads one. Files from earlier versions come from `get_post_version` with that version's `number`. `get_media` returns nothing for a file the current version dropped.
- `list_task_attachments` lists a task's files.
- `url` and `thumbnailUrl` are short-lived signed links. Read the file again for a fresh link instead of storing one.
- `delete_media` removes a file. Files under a retention policy return 409. Ask before deleting.

## Publishing from an installed tool

Unreal, Blender, Godot, Steamworks, and Aseprite integrations keep one post per source object through tool artifacts. `get_tool_artifact` looks up `provider` plus `externalArtifactId`. `upsert_tool_artifact` with `projectId`, `provider`, `externalArtifactId`, and `displayName` (plus optional `postId`, `attachmentId`, and `context`) binds that identity to a project, post, and attachment so repeated publishes land on the same post. Derive `externalArtifactId` from stable source data, never from a file path or display name. Pass `createOnly: true` on the first write to avoid two publishers racing.
