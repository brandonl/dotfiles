# APM project templates

These manifests are not installed by the dotfiles installer. Copy one into a
project, rename its `name`, and resolve fresh versions for that project:

```bash
cp ~/dotfiles/apm/templates/react-typescript/apm.yml .
apm install
```

For an existing `apm.yml`, merge the template's `dependencies.apm` entries and
`dependencies.mcp` entries instead of overwriting the project manifest.

Templates intentionally have no lockfiles. Commit the project-generated
`apm.lock.yaml`, then use `apm install --frozen` for reproducible installs.

The React + TypeScript template includes Playwright MCP. The browser-extension
template includes Playwright and Chrome DevTools MCP. APM deploys their MCP
configuration only to Claude Code; Codex and Cursor must use their native
project MCP configuration. Skills remain in the shared `.agents/skills/`
directory.
