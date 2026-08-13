#!/usr/bin/env bash
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

node --input-type=module - "$plugin_root" <<'NODE'
import { access, readFile, readdir } from "node:fs/promises";
import path from "node:path";

const pluginRoot = process.argv[2];
const errors = [];

async function readJson(relativePath) {
  try {
    return JSON.parse(await readFile(path.join(pluginRoot, relativePath), "utf8"));
  } catch (error) {
    errors.push(`${relativePath} is not valid JSON: ${error.message}`);
    return {};
  }
}

async function requirePath(relativePath) {
  try {
    await access(path.join(pluginRoot, relativePath));
  } catch {
    errors.push(`${relativePath} is missing`);
  }
}

const manifests = {
  agent: await readJson("plugin.json"),
  cursor: await readJson(".cursor-plugin/plugin.json"),
  codex: await readJson(".codex-plugin/plugin.json"),
  claude: await readJson(".claude-plugin/plugin.json"),
  gemini: await readJson("gemini-extension.json"),
};

const marketplaceFiles = [
  ".cursor-plugin/marketplace.json",
  ".agents/plugins/marketplace.json",
  ".claude-plugin/marketplace.json",
];
const marketplaces = await Promise.all(marketplaceFiles.map(readJson));

for (const [client, manifest] of Object.entries(manifests)) {
  if (manifest.name !== "project-feed") {
    errors.push(`${client} manifest has the wrong plugin name`);
  }
  if (!/^\d+\.\d+\.\d+$/.test(manifest.version ?? "")) {
    errors.push(`${client} manifest has an invalid version`);
  }
  if (!manifest.description) {
    errors.push(`${client} manifest is missing a description`);
  }
}

const versions = new Set(Object.values(manifests).map((manifest) => manifest.version));
if (versions.size !== 1) {
  errors.push("client manifest versions do not match");
}

for (const [index, marketplace] of marketplaces.entries()) {
  if (marketplace.name !== "project-feed") {
    errors.push(`${marketplaceFiles[index]} has the wrong marketplace name`);
  }
  if (!marketplace.plugins?.some((plugin) => plugin.name === "project-feed")) {
    errors.push(`${marketplaceFiles[index]} does not list project-feed`);
  }
}

for (const field of ["license", "logo", "skills", "mcpServers"]) {
  if (!manifests.cursor[field]) {
    errors.push(`Cursor manifest is missing ${field}`);
  }
}
if (manifests.cursor.displayName !== "Project Feed") {
  errors.push("Cursor manifest has the wrong display name");
}

const cursorMarketplacePlugin = marketplaces[0].plugins?.find(
  (plugin) => plugin.name === "project-feed",
);
if (cursorMarketplacePlugin?.displayName !== "Project Feed") {
  errors.push("Cursor marketplace entry has the wrong display name");
}

for (const field of ["license", "skills", "mcpServers", "interface"]) {
  if (!manifests.codex[field]) {
    errors.push(`Codex manifest is missing ${field}`);
  }
}

for (const manifest of [manifests.cursor, manifests.codex, manifests.claude]) {
  for (const field of ["skills", "mcpServers"]) {
    if (manifest[field]) {
      await requirePath(manifest[field].replace(/^\.\//, ""));
    }
  }
}

await requirePath(manifests.cursor.logo);

const cursorVariables = manifests.cursor.variables?.properties ?? {};
const cursorMcp = await readJson("mcp.json");
for (const match of JSON.stringify(cursorMcp).matchAll(/\$\{([A-Z0-9_]+)\}/g)) {
  if (!cursorVariables[match[1]]) {
    errors.push(`Cursor MCP variable ${match[1]} is not declared`);
  }
}

if (cursorMcp.$schema !== "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json") {
  errors.push("Agent Plugins MCP schema is missing");
}
if (cursorMcp.mcpServers?.["Project Feed"]?.type !== "streamable-http") {
  errors.push("Agent Plugins MCP transport is not streamable HTTP");
}

const claudeMcp = await readJson(".claude-mcp.json");
if (claudeMcp.mcpServers?.["Project Feed"]?.type !== "http") {
  errors.push("Claude MCP transport is not HTTP");
}
if (!manifests.claude.userConfig?.api_key?.sensitive) {
  errors.push("Claude API key setting must be sensitive");
}
if (!JSON.stringify(claudeMcp).includes("${user_config.api_key}")) {
  errors.push("Claude MCP does not use the sensitive API key setting");
}

const codexMcp = await readJson(".mcp.json");
if (codexMcp["Project Feed"]?.bearer_token_env_var !== "PROJECT_FEED_API_KEY") {
  errors.push("Codex MCP does not use PROJECT_FEED_API_KEY");
}

const geminiSetting = manifests.gemini.settings?.find(
  (setting) => setting.envVar === "PROJECT_FEED_API_KEY",
);
if (!geminiSetting?.sensitive) {
  errors.push("Gemini API key setting must be sensitive");
}

const endpoints = [
  cursorMcp.mcpServers?.["Project Feed"]?.url,
  claudeMcp.mcpServers?.["Project Feed"]?.url,
  codexMcp["Project Feed"]?.url,
  manifests.gemini.mcpServers?.["project-feed"]?.httpUrl,
];
if (endpoints.some((endpoint) => endpoint !== "https://projectfeed.app/api/mcp")) {
  errors.push("MCP endpoint differs between clients");
}

const skillRoot = path.join(pluginRoot, "skills");
for (const entry of await readdir(skillRoot, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  const skillPath = path.join(skillRoot, entry.name, "SKILL.md");
  let content;
  try {
    content = await readFile(skillPath, "utf8");
  } catch {
    errors.push(`${entry.name} is missing SKILL.md`);
    continue;
  }
  const frontmatter = content.match(/^---\n([\s\S]*?)\n---\n/);
  if (!frontmatter) {
    errors.push(`${entry.name} is missing frontmatter`);
    continue;
  }
  if (!/^name:\s*[a-z0-9-]+\s*$/m.test(frontmatter[1])) {
    errors.push(`${entry.name} has an invalid or missing name`);
  }
  if (!/^description:\s*\S.+$/m.test(frontmatter[1])) {
    errors.push(`${entry.name} is missing a description`);
  }
}

for (const relativePath of [
  "README.md",
  "SECURITY.md",
  "LICENSE",
  "docs/PUBLISHING.md",
]) {
  await requirePath(relativePath);
}

if (errors.length) {
  for (const error of errors) console.error(`error: ${error}`);
  process.exit(1);
}

console.log("Client manifests and shared plugin files are valid.");
NODE

if rg -n '[–—]' "$plugin_root" --glob '*.md' --glob '*.json'; then
  printf 'Found en or em dashes in shipped copy.\n' >&2
  exit 1
fi

if rg -n 'pf_(live|test)_[A-Za-z0-9]+' "$plugin_root"; then
  printf 'Found a Project Feed credential in the repository.\n' >&2
  exit 1
fi

if rg -n 'project-feed-cursor-plugin' "$plugin_root" --glob '!*.git/*' --glob '!scripts/validate.sh'; then
  printf 'Found the old repository name.\n' >&2
  exit 1
fi

printf 'Copy and credential checks passed.\n'
