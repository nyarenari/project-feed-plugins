# Project Feed plugins

Use Project Feed from Cursor, Codex, Claude Code, Gemini CLI, and clients that support the Agent Plugins standard.

The repository packages one hosted MCP connection with shared skills for task execution, project planning, status reports, and backlog triage. Client-specific manifests stay thin so every client receives the same workflows.

## Supported clients

| Client | Package | Local install |
| --- | --- | --- |
| Cursor | Cursor Plugin | `./scripts/install-local.sh cursor` |
| Codex and ChatGPT | Codex Plugin | `./scripts/install-local.sh codex` |
| Claude Code | Claude Code Plugin | `./scripts/install-local.sh claude` |
| Gemini CLI | Gemini CLI Extension | `./scripts/install-local.sh gemini` |
| Agent Plugins clients | Agent Plugin | Install this repository with the client's plugin command |

## Configure access

Create a dedicated API key in your Project Feed workspace developer settings. Choose the **Project/task automation** preset if you want the agent to manage projects and tasks. A read-only key limits the agent to matching read tools.

Project Feed MCP access requires a Pro workspace. API keys belong to one workspace, so use a different key when you want to switch workspaces.

### Cursor

When the listing is live, install Project Feed from the Cursor Marketplace, then open **Customize > Project Feed > Configure** and enter the API key.

For local development:

```bash
git clone https://github.com/nyarenari/project-feed-plugins.git
cd project-feed-plugins
./scripts/install-local.sh cursor
```

Restart Cursor or run **Developer: Reload Window**.

### Codex and ChatGPT

Add this repository as a marketplace and install the plugin:

```bash
codex plugin marketplace add nyarenari/project-feed-plugins
codex plugin add project-feed@project-feed
```

Set `PROJECT_FEED_API_KEY` in the environment that starts Codex. The repository marketplace also appears in supported ChatGPT plugin surfaces.

### Claude Code

Add the marketplace and install the plugin:

```bash
claude plugin marketplace add nyarenari/project-feed-plugins
claude plugin install project-feed@project-feed
```

Claude Code asks for the Project Feed API key when the plugin is enabled and stores it as sensitive plugin configuration.

### Gemini CLI

Install the extension from GitHub:

```bash
gemini extensions install https://github.com/nyarenari/project-feed-plugins.git
```

Gemini CLI asks for the Project Feed API key during installation and stores it as a sensitive extension setting.

## Try it

- "Pick up PRO-123 and keep the task current while you work."
- "Turn this feature brief into a task plan in Project Feed."
- "Give me a status update for the mobile app project."
- "Triage the open backlog and show me what needs attention."

Clients may ask for approval before MCP tool calls according to their run mode or team policy.

## Development

Run the repository checks with:

```bash
./scripts/validate.sh
```

The client manifests are:

- `.cursor-plugin/plugin.json` and `.cursor-plugin/marketplace.json`
- `.codex-plugin/plugin.json` and `.agents/plugins/marketplace.json`
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- `gemini-extension.json`
- `plugin.json` for the Agent Plugins standard

See [Publishing](docs/PUBLISHING.md) for the separate marketplace release steps.

## Permissions and data

The plugins send Project Feed tool requests to `https://projectfeed.app/api/mcp`. Project Feed applies the permissions from the configured API key. The packages do not include analytics, background hooks, or local executables.

Do not commit an API key to this repository or a workspace configuration file. Revoke the key from Project Feed if a device or client account is no longer trusted.

See the [Project Feed MCP documentation](https://projectfeed.app/docs/mcp) and [Project Feed privacy policy](https://projectfeed.app/privacy) for service details.

## Support

Open an issue in this repository for packaging or workflow problems. Contact `support@projectfeed.app` for account, workspace, or hosted MCP problems.

Security reports should go to `security@projectfeed.app`. Do not include credentials or private workspace data in a public issue.
