# Publishing

Each client has a separate public listing and review process. A merged manifest does not publish the plugin automatically.

## Cursor

Submit `https://github.com/nyarenari/project-feed-plugins` through the Cursor Marketplace publisher form. The repository root contains the Cursor marketplace and plugin manifests.

## Codex and ChatGPT

The repository marketplace supports local and team installation. For the shared ChatGPT and Codex Plugins Directory, prepare a separate public ZIP with listing metadata, review cases, and a working demo recording URL. Provide the dedicated review account only through the portal's secure reviewer-access fields.

Upload the completed ZIP through the OpenAI Platform plugin dashboard, connect the hosted MCP server with OAuth, and complete the saved-version tests, scans, and publisher requirements. Keep private `.app.json` bindings out of the public upload. Submission for review and publication after approval are separate steps.

## Claude Code

The repository can be installed directly as a Claude Code marketplace. An organization owner submits its GitHub source through the [Claude directory portal](https://claude.ai/directory/manage). Submit the hosted MCP connector and plugin bundle separately. Run `claude plugin validate --strict --profile directory .` before submitting the bundle.

## Gemini CLI

Add the `gemini-cli-extension` topic to the public GitHub repository. Gemini CLI discovers gallery entries from public tagged repositories with `gemini-extension.json` at the repository root.

## Release checklist

1. Run `./scripts/validate.sh`.
2. Test the package locally in each installed client.
3. Confirm the hosted MCP endpoint and authentication flow from that client.
4. Bump every client manifest to the same version.
5. Tag the repository only after the client packages agree.
6. Submit or refresh each public listing separately.
