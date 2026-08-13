#!/usr/bin/env bash
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

node --input-type=module - "$plugin_root" <<'NODE'
import { readFile, readdir, access } from "node:fs/promises";
import path from "node:path";

const pluginRoot = process.argv[2];
const manifestPath = path.join(pluginRoot, ".cursor-plugin", "plugin.json");
const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
const mcp = JSON.parse(await readFile(path.join(pluginRoot, "mcp.json"), "utf8"));
const errors = [];

if (!/^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$/.test(manifest.name ?? "")) {
  errors.push("plugin name must be lowercase kebab-case");
}

for (const field of ["description", "version", "license", "logo"]) {
  if (!manifest[field]) errors.push(`manifest is missing ${field}`);
}

try {
  await access(path.join(pluginRoot, manifest.logo));
} catch {
  errors.push("manifest logo does not exist");
}

const variables = manifest.variables?.properties ?? {};
const mcpText = JSON.stringify(mcp);
for (const match of mcpText.matchAll(/\$\{([A-Z0-9_]+)\}/g)) {
  if (!variables[match[1]]) errors.push(`MCP variable ${match[1]} is not declared`);
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

for (const relativePath of ["README.md", "SECURITY.md", "LICENSE"]) {
  try {
    await access(path.join(pluginRoot, relativePath));
  } catch {
    errors.push(`${relativePath} is missing`);
  }
}

if (errors.length) {
  for (const error of errors) console.error(`error: ${error}`);
  process.exit(1);
}

console.log("Plugin files are valid.");
NODE

if rg -n '[–—]' "$plugin_root" --glob '*.md' --glob '*.json'; then
  printf 'Found en or em dashes in shipped copy.\n' >&2
  exit 1
fi

if rg -n 'pf_(live|test)_[A-Za-z0-9]+' "$plugin_root"; then
  printf 'Found a Project Feed credential in the repository.\n' >&2
  exit 1
fi

printf 'Copy and credential checks passed.\n'
