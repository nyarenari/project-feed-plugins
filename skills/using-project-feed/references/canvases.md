# Canvases

A canvas is an open board in one project. It holds notes, shapes, text, links, frames, drawings, and cards for tasks and posts. Use a doc when reading order matters and a post for dated updates.

## Read

- `list_canvases` with `projectId` and `includeArchived`. Pages can be short. Pass `nextCursor` back as `cursor` while `hasMore` is true.
- `get_canvas` returns the canvas with `items` and `connectors`, oldest first. It has no paging. Past 2,000 items or 4,000 connectors it sets `truncated`, and you are not seeing everything, so place new items well clear of what you can see.

Read the canvas before adding to it, so new items land in empty space or inside the right frame.

## Create

- `create_canvas` with `projectId`, `name` (up to 200), `description`, and `visibility`: `shared` (the default) for everyone in the project, `private` for only the creator.
- `update_canvas` renames it or changes its description or visibility.
- `create_canvas_item` with `canvasId` and an `item` object. Unknown item fields are rejected with "Unsupported item field".

## Items

Every item needs `type`, `x`, `y`, `width`, and `height`. `x` and `y` are the top-left corner in canvas units. Width and height must be positive. A note at `x: 120, y: 80` sized 240 by 160 is a normal size.

| `type` | Fields |
| --- | --- |
| `note` | `content` (plain text), `color` |
| `text` | `content` or `richContent` (Plate JSON), `textAlign` |
| `shape` | `shapeKind` (`rectangle`, `roundedRectangle`, `ellipse`, `diamond`, `triangle`, `line`), `content`, `fillStyle`, `strokeStyle`, `strokeWidth`, `rotation` (radians) |
| `url` | `url` (http or https), `urlLabel` |
| `frame` | `frameKind` (`section`, `frame`, `stack`), `frameTitle`, `borderStyle`. Frames and stacks go inside a section |
| `draw` | `drawKind` (`freehand`, `line`, `arrow`), `drawPoints` (flat `[x1, y1, x2, y2, ...]` from 0 to 1 within the item box), `drawRoute` (`straight`, `curved`, `elbow`) |
| `task` | `taskId` (internal ID, not `PRO-42`) |
| `post` | `postId` (internal ID) |

Shared style fields: `color`, `backgroundColor`, `backgroundFill`, `backgroundBorder`, `backgroundRadius`, `opacity` (0 to 100).

`frameId` places an item inside a frame on the same canvas. A canvas holds up to 5,000 items.

## Images and files

Media items cannot be created with `create_canvas_item`. Upload with `prepare_media_upload` and `destination: {type: "canvas", id, x, y, width, height, frameId}`. Without a position the file lands at 0, 0 sized 400 by 300, on top of whatever is there. It needs `canvas:write` as well as `media:write`. See [media.md](media.md).

## Connectors

Connectors between items are created in the app and are read only through the API. A `draw` item with `drawKind: "arrow"` makes a free arrow that does not follow items.

## Change and remove

- `update_canvas_item` with `canvasId`, `itemId`, and `changes`, which holds only the fields to change (`{"x": 320}` moves an item and keeps its size). Locked items cannot change.
- `delete_canvas_item` on a frame keeps the items inside it.
- `archive_canvas` makes a canvas read only and `unarchive_canvas` restores it. Prefer archiving when work is done.
- `delete_canvas` removes the canvas and its items with no API restore. Copy decisions into a doc or task first, and ask before deleting.
- Only the creator and workspace owners or admins can update, archive, or delete a canvas.
