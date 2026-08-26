# pi-agent.nvim

A personal Neovim assistant that talks to the `pi-agent` backend.

The command shape is inspired by CodeCompanion, but this plugin stays small.
Neovim calls Pi Agent; the backend owns the model/runtime integration.

## Requirements

- Neovim 0.10+
- The bundled `bin/pi-agent` backend
- A working model/runtime behind Pi Agent

## Install With lazy.nvim

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
  keys = {
    { "<leader>cc", "<cmd>PiAgentPanel<cr>", desc = "Open Pi Agent panel" },
    { "<leader>aa", "<cmd>PiAgentActions<cr>", desc = "Pi Agent actions" },
    { "<leader>ac", "<cmd>PiAgentChat Toggle<cr>", desc = "Toggle Pi Agent chat" },
    { "<leader>ai", "<cmd>PiAgent<cr>", desc = "Pi Agent inline" },
    { "<leader>aq", "<cmd>PiAgentAsk<cr>", desc = "Ask Pi Agent" },
    { "<leader>ab", "<cmd>PiAgentBuffer<cr>", desc = "Ask with buffer" },
    { "<leader>as", ":PiAgentSelection<cr>", mode = "v", desc = "Ask with selection" },
    { "<leader>ae", ":PiAgentEdit<cr>", mode = "v", desc = "Edit selection" },
    { "<leader>aC", "<cmd>PiAgentCLI<cr>", desc = "Open Pi Agent CLI" },
    { "<leader>a:", "<cmd>PiAgentCmd<cr>", desc = "Generate Vim command" },
    { "<leader>al", "<cmd>PiAgentLogin<cr>", desc = "Pi Agent login" },
    { "<leader>at", "<cmd>PiAgentStatus<cr>", desc = "Pi Agent status" },
  },
  config = function()
    require("pi_agent").setup()
  end,
}
```

## Commands

| Command | Purpose |
| --- | --- |
| `:PiAgentPanel` | Open the Pi Agent panel on the right. |
| `:PiAgent [prompt]` | Inline-style prompt. With a visual range, selected text is included as context. |
| `:PiAgentChat [prompt]` | Open the chat buffer, or send a prompt to it. |
| `:PiAgentChat Toggle` | Toggle the chat buffer. |
| `:PiAgentChat New` / `Clear` | Reset the current chat. |
| `:'<,'>PiAgentChat Add` | Add selected text to the chat input. |
| `:PiAgentCLI [prompt]` | Open interactive Pi Agent in a floating terminal. |
| `:PiAgentCmd [request]` | Generate a Vim command and place it on the command line. |
| `:PiAgentActions` | Open the action palette. |
| `:PiAgentBuffer [prompt]` | Ask Pi Agent with the current buffer as context. |
| `:'<,'>PiAgentSelection [prompt]` | Ask Pi Agent with selected lines as context. |
| `:'<,'>PiAgentEdit [instruction]` | Replace selected lines with Pi Agent output. |
| `:PiAgentLogin` | Run Pi Agent login. |
| `:PiAgentStatus` | Check whether Pi Agent auth is ready. |

## Chat Buffer

Open it with `:PiAgentChat` or `:PiAgentChat Toggle`.

Type below `## You`, then press Enter in normal or insert mode to submit.
Press `q` in normal mode to close the chat window.

## Configuration

```lua
require("pi_agent").setup({
  agent_cmd = nil,
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
    submit = "<CR>",
    close = "q",
  },
})
```

With `agent_cmd = nil`, the plugin uses its bundled `bin/pi-agent` command.
That backend currently delegates to the local Codex CLI, so auth remains outside
Neovim and the plugin does not store API keys or tokens. Set `agent_cmd` to a
different executable when you have a separate Pi Agent runtime.
