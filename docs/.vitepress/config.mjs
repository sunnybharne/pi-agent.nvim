import { defineConfig } from "vitepress";

export default defineConfig({
  title: "Pi Agent.nvim",
  description: "A small Neovim assistant panel backed by Pi Agent.",
  base: "/pi-agent.nvim/",
  cleanUrls: true,
  lastUpdated: true,
  head: [
    ["link", { rel: "icon", href: "/pi-agent.nvim/logo.svg" }],
    ["meta", { property: "og:type", content: "website" }],
    ["meta", { property: "og:title", content: "Pi Agent.nvim" }],
    ["meta", { property: "og:description", content: "A small Neovim assistant panel backed by Pi Agent." }],
  ],
  themeConfig: {
    logo: "/logo.svg",
    siteTitle: "Pi Agent.nvim",
    nav: [
      { text: "Guide", link: "/getting-started" },
      { text: "Commands", link: "/commands" },
      { text: "GitHub", link: "https://github.com/sunnybharne/pi-agent.nvim" },
    ],
    sidebar: [
      {
        text: "Getting Started",
        items: [
          { text: "Introduction", link: "/" },
          { text: "Installation", link: "/installation" },
          { text: "Getting Started", link: "/getting-started" },
          { text: "Authentication", link: "/authentication" },
        ],
      },
      {
        text: "Usage",
        items: [
          { text: "Chat Buffer", link: "/usage/chat-buffer" },
          { text: "Editor Context", link: "/usage/editor-context" },
          { text: "Inline Actions", link: "/usage/inline-actions" },
          { text: "Commands", link: "/commands" },
        ],
      },
      {
        text: "Reference",
        items: [
          { text: "Configuration", link: "/configuration" },
          { text: "Troubleshooting", link: "/troubleshooting" },
          { text: "Contributing", link: "/contributing" },
        ],
      },
    ],
    socialLinks: [
      { icon: "github", link: "https://github.com/sunnybharne/pi-agent.nvim" },
    ],
    search: {
      provider: "local",
    },
    editLink: {
      pattern: "https://github.com/sunnybharne/pi-agent.nvim/edit/main/docs/:path",
      text: "Edit this page on GitHub",
    },
    footer: {
      message: "Released as a personal Neovim assistant plugin.",
      copyright: "Copyright © 2026 Sunny Bharne",
    },
  },
});
