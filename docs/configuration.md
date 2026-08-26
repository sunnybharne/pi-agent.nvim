# Configuration

Use `setup()` from your Neovim config:

```lua
require("pi_agent").setup({
  agent_cmd = nil,
  sandbox = "read-only",
  approval = "never",
  model = nil,
  effort = nil,
  speed = nil,
  extra_args = {},
  terminal_args = {},
  system_prompt = "You are Pi Agent, a concise AI coding assistant running inside Neovim.",
  window = {
    width = 0.85,
    height = 0.85,
    border = "rounded",
  },
  chat = {
    width = 0.38,
    min_width = 52,
    storage_dir = nil,
    selection_max_lines = 200,
    visible_files_max = 12,
  },
  mappings = {
    submit = "<CR>",
    close = "q",
  },
})
```

## Runtime Options

| Option | Default | Purpose |
| --- | --- | --- |
| `agent_cmd` | `nil` | Backend command. When unset, uses bundled `bin/pi-agent`. |
| `model` | `nil` | Optional model override. |
| `effort` | `nil` | Optional reasoning effort override. |
| `speed` | `nil` | Optional service tier override. |
| `sandbox` | `"read-only"` | Runtime sandbox setting passed to the backend. |
| `approval` | `"never"` | Runtime approval policy accepted by the backend. |
| `extra_args` | `{}` | Additional args for `pi-agent exec`. |
| `terminal_args` | `{}` | Additional args for `pi-agent cli`. |

## Chat Options

| Option | Default | Purpose |
| --- | --- | --- |
| `chat.width` | `0.38` | Right panel width. Fractions are relative to editor width. |
| `chat.min_width` | `52` | Minimum right panel width. |
| `chat.storage_dir` | `nil` | Override chat history directory. |
| `chat.selection_max_lines` | `200` | Maximum selected lines included in runtime context. |
| `chat.visible_files_max` | `12` | Maximum visible files listed in runtime context. |
