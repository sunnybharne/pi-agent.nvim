# Getting Started

## Open The Panel

Open a code file and press:

```text
<leader>cc
```

The panel opens on the right. Type your question below `## You`, then press Enter in normal or insert mode.

## Ask About The Current File

Open the panel from a normal file buffer and ask:

```text
which file is this?
```

Pi Agent receives the project root, current file, cursor line, cursor column, current line text, and visible file list.

## Ask About A Selection

Select lines in visual mode and press:

```text
<leader>cc
```

Then ask:

```text
what does this selected code do?
```

The selected range and line-numbered selected text are sent as editor context.

## Check Login

Use:

```vim
:PiAgentStatus
```

If it says you are not logged in, run:

```vim
:PiAgentLogin
```
