---
layout: home

hero:
  name: Pi Agent.nvim
  text: Your coding agent, inside Neovim.
  tagline: A focused assistant panel that understands your project, file, cursor, and selected lines—without pulling you out of the editor.
  image:
    src: /logo.png
    alt: Pi Agent logo
  actions:
    - theme: brand
      text: Get started
      link: /getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/sunnybharne/pi-agent.nvim

features:
  - icon: "⌁"
    title: Project-root chats
    details: Keep a separate conversation for each codebase, restored automatically from the nearest Git root.
  - icon: "↳"
    title: Editor-native context
    details: Ask about your active file, cursor, visible buffers, or selected lines without restating where you are.
  - icon: "π"
    title: A small, replaceable core
    details: Pi Agent owns the Neovim experience while a lightweight backend owns the model runtime.
---

<HomeShowcase />
