# Project Feed for Cursor

Use Project Feed from Cursor to plan work, manage tasks, and prepare project updates.

The plugin connects Cursor to Project Feed's hosted MCP server and includes skills for task execution, project planning, status reports, and backlog triage.

## Install

Install Project Feed from the Cursor Marketplace, then open **Customize > Project Feed > Configure**.

Create a dedicated API key in your Project Feed workspace developer settings and paste it into the plugin configuration. Choose the **Project/task automation** preset if you want Cursor to manage projects and tasks. A read-only key limits Cursor to the matching read tools.

Project Feed MCP access requires a Pro workspace. API keys belong to one workspace, so change the configured key when you want to switch workspaces.

## Try it

- "Pick up PRO-123 and keep the task current while you work."
- "Turn this feature brief into a task plan in Project Feed."
- "Give me a status update for the mobile app project."
- "Triage the open backlog and show me what needs attention."

Cursor asks for approval before MCP tool calls unless your Cursor run mode or team policy allows them automatically.

## Local development

Clone the repository and link it into Cursor's local plugin directory:

```bash
git clone https://github.com/nyarenari/project-feed-cursor-plugin.git
cd project-feed-cursor-plugin
./scripts/install-local.sh
```

Restart Cursor or run **Developer: Reload Window**. The plugin appears under **Customize > Installed**.

Run the local checks with:

```bash
./scripts/validate.sh
```

## Permissions and data

The plugin sends Project Feed tool requests to `https://projectfeed.app/api/mcp`. Project Feed applies the permissions from the API key configured in Cursor. The plugin does not include analytics, background hooks, or local executables.

Cursor stores the configured value for the plugin and supplies it to the MCP connection. Do not commit an API key to this repository or a workspace configuration file. Revoke the key from Project Feed if a device or Cursor account is no longer trusted.

See the [Project Feed MCP documentation](https://projectfeed.app/docs/mcp) and [Project Feed privacy policy](https://projectfeed.app/privacy) for service details.

## Support

Open an issue in this repository for plugin packaging or workflow problems. Contact `support@projectfeed.app` for account, workspace, or hosted MCP problems.

Security reports should go to `security@projectfeed.app`. Do not include credentials or private workspace data in a public issue.
