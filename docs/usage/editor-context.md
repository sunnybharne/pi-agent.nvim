# Editor Context

Pi Agent.nvim captures editor context before focus moves into the side panel.

## Captured Context

- Project root.
- Current file path.
- Current filetype.
- Cursor line and column.
- Current line text.
- Visible file list.
- Selected line range and selected text when opened from visual mode.

## Normal Mode

Open a file, press `<leader>cc`, then ask:

```text
which file is this?
```

The assistant can answer using the captured file and cursor position.

## Visual Mode

Select lines, press `<leader>cc`, then ask:

```text
what does this selected block do?
```

The assistant receives a line-numbered copy of the selected range. By default, selected text sent to the runtime is capped at 200 lines.

## Visible Files

The plugin also includes visible file buffers so the assistant can understand what is on screen. By default, up to 12 visible file buffers are listed.
