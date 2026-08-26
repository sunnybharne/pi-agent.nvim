# Troubleshooting

## Runtime Is Not Logged In

If the chat shows:

```text
Runtime is not logged in
```

Run:

```vim
:PiAgentLogin
```

Then retry your prompt.

## Wrong Project Root

The panel root is resolved from the source buffer.

If the project is a Git repository, check:

```sh
git rev-parse --show-toplevel
```

If there is no Git repository above the file, Pi Agent uses the current folder.

## Selection Missing

Use visual mode and trigger:

```text
<leader>cc
```

The panel should show a `Selection:` line in the header. If it does not, check that your Neovim config includes the visual-mode mapping.

## Backend Not Found

If the plugin says the backend was not found, confirm the bundled script is executable:

```sh
chmod +x bin/pi-agent
```

With `lazy.nvim`, keep this in the plugin spec:

```lua
build = "chmod +x bin/pi-agent"
```
