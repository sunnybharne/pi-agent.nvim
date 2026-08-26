---
layout: home

hero:
  name: Pi Agent.nvim
  text: Small AI chat for Neovim.
  tagline: A right-side assistant panel that knows your current project, file, cursor, and selected lines.
  image:
    src: /logo.svg
    alt: Pi Agent logo
  actions:
    - theme: brand
      text: Get Started
      link: /getting-started
    - theme: alt
      text: Install
      link: /installation

features:
  - title: Project-root chats
    details: The panel uses the nearest Git root when available, then restores chat history for that project.
  - title: Editor context
    details: Ask about the file, cursor, visible buffers, or selected lines without retyping where you are.
  - title: Minimal runtime bridge
    details: The bundled backend delegates to Codex today, while the Neovim plugin stays small and replaceable.
---

## What It Does

Pi Agent.nvim is a personal Neovim assistant plugin. It opens a compact chat panel on the right, sends prompts to the bundled `pi-agent` backend, and keeps context attached to the project you are editing.

It is intentionally smaller than broad assistant frameworks. The plugin owns the Neovim experience: windows, mappings, editor context, and chat history. The backend owns the model runtime.

## Core Workflow

```text
Open file -> press <leader>cc -> ask Pi Agent -> get an answer in the side panel
```

When you open the panel from visual mode, Pi Agent captures the selected range and sends the selected text with line numbers.
