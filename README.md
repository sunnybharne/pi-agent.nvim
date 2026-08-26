# pi-agent.nvim

A small personal Neovim bridge to the local Codex CLI.

It does not store API keys or tokens. Authentication stays with `codex login`.

## Requirements

- Neovim 0.10+
- `codex` available in `PATH`
- Codex logged in on the machine

## Install With lazy.nvim

```lua
{
  "sunnybharne/pi-agent.nvim",
  cmd = {
    "PiAgent",
    "PiAgentAsk",
    "PiAgentBuffer",
    "PiAgentSelection",
    "PiAgentLogin",
    "PiAgentStatus",
  },
  keys = {
    { "<leader>aa", "<cmd>PiAgent<cr>", desc = "Open Codex agent" },
    { "<leader>aq", "<cmd>PiAgentAsk<cr>", desc = "Ask Codex" },
    { "<leader>ab", "<cmd>PiAgentBuffer<cr>", desc = "Ask with buffer" },
    { "<leader>as", ":PiAgentSelection<cr>", mode = "v", desc = "Ask with selection" },
    { "<leader>al", "<cmd>PiAgentLogin<cr>", desc = "Codex login" },
    { "<leader>at", "<cmd>PiAgentStatus<cr>", desc = "Codex status" },
  },
  config = function()
    require("pi_agent").setup()
  end,
}
```

## Commands

| Command | Purpose |
| --- | --- |
| `:PiAgent` | Open interactive Codex in a floating terminal |
| `:PiAgentAsk` | Ask Codex and show the response in a scratch buffer |
| `:PiAgentBuffer` | Ask Codex with the current buffer as context |
| `:PiAgentSelection` | Ask Codex with selected lines as context |
| `:PiAgentLogin` | Run `codex login --device-auth` |
| `:PiAgentStatus` | Check whether Codex auth is ready |

## Configuration

```lua
require("pi_agent").setup({
  codex_cmd = "codex",
  sandbox = "read-only",
  approval = "never",
  model = nil,
  extra_args = {},
  terminal_args = {},
  window = {
    width = 0.85,
    height = 0.85,
    border = "rounded",
  },
})
```
