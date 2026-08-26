# Installation

## Requirements

- Neovim 0.10 or newer.
- A plugin manager such as `lazy.nvim`.
- The bundled `bin/pi-agent` backend.
- A working Codex login when using the bundled backend.

## lazy.nvim

```lua
{
  "sunnybharne/pi-agent.nvim",
  cmd = {
    "PiAgentPanel",
    "PiAgent",
    "PiAgentChat",
    "PiAgentCLI",
    "PiAgentCmd",
    "PiAgentActions",
    "PiAgentAsk",
    "PiAgentBuffer",
    "PiAgentSelection",
    "PiAgentEdit",
    "PiAgentLogin",
    "PiAgentStatus",
  },
  build = "chmod +x bin/pi-agent",
  keys = {
    { "<leader>cc", "<cmd>PiAgentPanel<cr>", desc = "Open Pi Agent panel" },
    { "<leader>cc", ":PiAgentPanel<cr>", mode = "v", desc = "Open Pi Agent panel with selection" },
  },
  config = function()
    require("pi_agent").setup({
      sandbox = "read-only",
      approval = "never",
    })
  end,
}
```

## Runtime

With `agent_cmd = nil`, the plugin uses its bundled `bin/pi-agent` command. On macOS, that backend prefers the Codex binary bundled with the ChatGPT app when it exists, then falls back to `codex` on `PATH`.

Set `agent_cmd` only if you have a separate Pi Agent runtime command.
