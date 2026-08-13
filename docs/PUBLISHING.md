# Publishing

Each client has a separate public listing and review process. A merged manifest does not publish the plugin automatically.

## Cursor

Submit `https://github.com/nyarenari/project-feed-plugins` through the Cursor Marketplace publisher form. The repository root contains the Cursor marketplace and plugin manifests.

## Codex and ChatGPT

The repository marketplace supports local and team installation. A public listing in the shared ChatGPT and Codex Plugins Directory also requires registering the hosted MCP connection in ChatGPT developer mode, adding its `plugin_asdk_app...` mapping to `.app.json`, and submitting the plugin through the OpenAI Platform review flow.

Do not add a placeholder connector identifier. Register the production Project Feed MCP server before creating `.app.json`.

## Claude Code

The repository can be installed directly as a Claude Code marketplace. Submit the plugin through the Claude plugin form when it is ready for the official marketplace.

## Gemini CLI

Add the `gemini-cli-extension` topic to the public GitHub repository. Gemini CLI discovers gallery entries from public tagged repositories with `gemini-extension.json` at the repository root.

## Release checklist

1. Run `./scripts/validate.sh`.
2. Test the package locally in each installed client.
3. Confirm the hosted MCP endpoint and authentication flow from that client.
4. Bump every client manifest to the same version.
5. Tag the repository only after the client packages agree.
6. Submit or refresh each public listing separately.
