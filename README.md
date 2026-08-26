# pi-agent.nvim

A personal Neovim assistant that talks to the local Codex CLI.

The command shape is inspired by CodeCompanion, but this plugin stays small and
uses your existing `codex` login instead of API keys.

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
  keys = {
    { "<leader>aa", "<cmd>PiAgentActions<cr>", desc = "Pi Agent actions" },
    { "<leader>ac", "<cmd>PiAgentChat Toggle<cr>", desc = "Toggle Pi Agent chat" },
    { "<leader>ai", "<cmd>PiAgent<cr>", desc = "Pi Agent inline" },
    { "<leader>aq", "<cmd>PiAgentAsk<cr>", desc = "Ask Codex" },
    { "<leader>ab", "<cmd>PiAgentBuffer<cr>", desc = "Ask with buffer" },
    { "<leader>as", ":PiAgentSelection<cr>", mode = "v", desc = "Ask with selection" },
    { "<leader>ae", ":PiAgentEdit<cr>", mode = "v", desc = "Edit selection" },
    { "<leader>aC", "<cmd>PiAgentCLI<cr>", desc = "Open Codex CLI" },
    { "<leader>a:", "<cmd>PiAgentCmd<cr>", desc = "Generate Vim command" },
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
| `:PiAgent [prompt]` | Inline-style prompt. With a visual range, selected text is included as context. |
| `:PiAgentChat [prompt]` | Open the chat buffer, or send a prompt to it. |
| `:PiAgentChat Toggle` | Toggle the chat buffer. |
| `:PiAgentChat New` / `Clear` | Reset the current chat. |
| `:'<,'>PiAgentChat Add` | Add selected text to the chat input. |
| `:PiAgentCLI [prompt]` | Open interactive Codex in a floating terminal. |
| `:PiAgentCmd [request]` | Generate a Vim command and place it on the command line. |
| `:PiAgentActions` | Open the action palette. |
| `:PiAgentBuffer [prompt]` | Ask Codex with the current buffer as context. |
| `:'<,'>PiAgentSelection [prompt]` | Ask Codex with selected lines as context. |
| `:'<,'>PiAgentEdit [instruction]` | Replace selected lines with Codex output. |
| `:PiAgentLogin` | Run `codex login --device-auth`. |
| `:PiAgentStatus` | Check whether Codex auth is ready. |

## Chat Buffer

Open it with `:PiAgentChat` or `:PiAgentChat Toggle`.

Type below `## You`, then press `<C-s>` in normal or insert mode to submit.
Press `q` in normal mode to close the chat window.

## Configuration

```lua
require("pi_agent").setup({
  codex_cmd = "codex",
  sandbox = "read-only",
  approval = "never",
  model = nil,
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
  },
  mappings = {
    submit = "<C-s>",
    close = "q",
  },
})
```

Authentication is handled by the Codex CLI. This plugin does not store API keys
or tokens.
