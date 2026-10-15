# The pf CLI

Agents with a shell can use the `pf` CLI instead of MCP, or alongside it for uploads. It calls the same REST API.

## Set up

```bash
npm install -g pfeed-cli   # or: npx pfeed-cli ... (search, chat, time, and bulk need 0.5.9 or later)
pf auth login              # prompts for an API key. Avoid --token, it lands in shell history
pf auth check              # shows the workspace and effective scopes
pf link <project>          # writes .pf/config.json so --project can be omitted. Add .pf/ to .gitignore
```

- Key precedence: `--api-key`, then `PROJECT_FEED_API_KEY` (including a `.env` in the current directory), then the saved profile. An environment key silently beats `--profile`.
- With several workspaces, pass `--workspace <slug>` or set `PROJECT_FEED_WORKSPACE`.
- Profiles: `pf config profile create <name>`, `use <name>`, `list`, or `--profile <name>` per command.

## Habits

- Add `--json` (or `--json id,title,status`) for machine-readable output. On `tasks list` and `posts list`, add `--page` to keep `hasMore` and `nextCursor`, then pass `--cursor` for the next page.
- Pass IDs explicitly. Interactive pickers fail without a terminal.
- Task references accept an ID, `PRO-42`, or a number. Quote `'#42'` so the shell does not treat it as a comment.
- In an agent's shell there is no terminal, so delete commands run immediately without asking. Run them with `--dry-run` first, and only delete what the user asked for.
- Reads retry on server errors and writes do not, although a 429 is retried for both. Check before re-running a failed write.
- `pf limits` shows the remaining rate-limit budget.
- `pf api <METHOD> </path> --data '<json>'` calls any REST endpoint under `/api/v1` for anything without a command.

## Common commands

| Job | Command |
| --- | --- |
| Find | `pf search "<query>" --type task,post` |
| Tasks | `pf tasks list --status in_progress`, `pf tasks view PRO-42`, `pf tasks create --title "..." --description-md "..."`, `pf tasks edit PRO-42 --status in_review` |
| Task comments | `pf tasks comment add PRO-42 --content "..."` |
| Checklist | `pf checklist list PRO-42`, `pf checklist add PRO-42 --text "..."`, `pf checklist check PRO-42 <itemId>` |
| Subtasks | `pf subtasks add PRO-42 --title "..."` |
| Bulk | `pf tasks bulk status <ids...> --status done --dry-run` |
| Posts | `pf posts create --title "..." --content "..." --project <id>` (draft by default), `pf posts publish <id>` |
| Versions | `pf posts versions publish <post> --file render.mp4 --note "..." --idempotency-key <key>` (`--media-id` keeps files, `--drop-media` drops all) |
| Uploads | `pf media upload <file> --post <id>` (also `--task`, `--comment`, `--task-comment`, `--doc`, `--chat-message`, `--canvas`) |
| Comments and annotations | `pf comments list <post> --annotated --status open`, `pf comments add <post> --attachment <id> --time-ms 4200 --review-status needs_changes --content "..."`, `pf comments resolve <post> <comment>` |
| Annotation to task | `pf comments to-task <post> <comment> --title "..."` |
| Docs | `pf docs view <id> --content`, `pf docs set-content <id> --content-file doc.json --change-note "..."` |
| Canvases | `pf canvases items add <canvas> --type note --x 0 --y 0 --width 240 --height 160 --content "..."` |
| Chat | `pf chat discuss task <id> --content "..." --title "..."`, `pf chat start <room> --content "..."` (new discussion), `pf chat send <room> <thread> --content "..."` (reply) |
| Time | `pf time start --task PRO-42`, `pf time stop --note "..."` |
| Handoffs (person side) | `pf handoffs get <id>`, `pf handoffs decide <id> accept`, `pf handoffs answer <id> <attempt> "<answer>"` |

## Gaps compared with MCP

- `pf docs create` and `set-content` take Plate JSON files only. Use MCP with `contentFormat: "markdown"` for Markdown.
- `pf posts create --content` sends plain text.
- `pf comments add` has no drawing or camera flags and there is no wait or annotation-frame command. Use MCP for those.
- There is no CLI for listing, requesting, claiming, or submitting handoffs.
- Bare numbers in `pf time --duration` mean minutes. Prefer explicit units like `90m` or `1h30m`.
