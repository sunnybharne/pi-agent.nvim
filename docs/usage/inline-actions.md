# Inline Actions

Pi Agent.nvim includes smaller commands for one-off prompts.

## Ask

```vim
:PiAgentAsk explain this project
```

The response opens in a floating result window.

## Current Buffer

```vim
:PiAgentBuffer summarize this file
```

The current buffer is attached as context.

## Selection

Select lines and run:

```vim
:'<,'>PiAgentSelection explain this function
```

The selected lines are attached as context.

## Edit Selection

Select lines and run:

```vim
:'<,'>PiAgentEdit simplify this code
```

The selected lines are replaced with the model output. Review the diff before saving.
