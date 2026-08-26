# Chat Buffer

The chat buffer is the main Pi Agent.nvim surface.

Open it with:

```vim
:PiAgentPanel
```

or:

```vim
:PiAgentChat Toggle
```

Type below `## You`, then press Enter in normal or insert mode to submit.

Press `q` in normal mode to close the chat window.

## Project Root

Pi Agent resolves the chat root from the source buffer:

- If the buffer is inside a Git repository, the Git top-level directory is used.
- If no Git repository is found, the current folder is used.

Chat history is stored per root and restored when you reopen the same project.

## Panel Header

The panel shows the active runtime and editor context:

```text
Root: /Users/sunnybharne/code/youtube
Context: lua/pi_agent/init.lua:42:3
Selection: lua/pi_agent/init.lua:7-9
Model: gpt-5.5 | Effort: xhigh | Speed: priority | Last: not run yet
```

`Last` updates after each response with duration and character throughput.
