# Commands

| Command | Purpose |
| --- | --- |
| `:PiAgentPanel` | Open the right-side panel. With a visual range, selected lines are attached as editor context. |
| `:PiAgent [prompt]` | Run an inline-style prompt. With a visual range, selected text is included as context. |
| `:PiAgentChat [prompt]` | Open the chat buffer or send a prompt to it. |
| `:PiAgentChat Toggle` | Toggle the chat buffer. |
| `:PiAgentChat New` | Clear the current project chat. |
| `:PiAgentChat Clear` | Clear the current project chat. |
| `:'<,'>PiAgentChat Add` | Add selected text to the chat input. Without a visual range, the current buffer is added. |
| `:PiAgentCLI [prompt]` | Open interactive Pi Agent in a floating terminal. |
| `:PiAgentCmd [request]` | Generate a Vim command and place it on the command line without executing it. |
| `:PiAgentActions` | Open the action palette. |
| `:PiAgentBuffer [prompt]` | Ask Pi Agent with the current buffer as context. |
| `:'<,'>PiAgentSelection [prompt]` | Ask Pi Agent with selected lines as context. |
| `:'<,'>PiAgentEdit [instruction]` | Replace selected lines with Pi Agent output. |
| `:PiAgentLogin` | Run Pi Agent login. |
| `:PiAgentStatus` | Check whether Pi Agent auth is ready. |

## Default Keys

| Key | Mode | Purpose |
| --- | --- | --- |
| `<leader>cc` | Normal | Open the panel for the current project and file. |
| `<leader>cc` | Visual | Open the panel and attach the selected line range. |
