import { defineConfig } from "vitepress";

export default defineConfig({
  title: "Pi Agent.nvim",
  description: "AI pair programming, inside Neovim.",
  base: "/pi-agent.nvim/",
  cleanUrls: true,
  lastUpdated: true,
  head: [
    ["link", { rel: "icon", type: "image/png", sizes: "32x32", href: "/pi-agent.nvim/favicon-32x32.png" }],
    ["link", { rel: "apple-touch-icon", sizes: "180x180", href: "/pi-agent.nvim/apple-touch-icon.png" }],
    ["meta", { name: "theme-color", content: "#20302c" }],
    ["meta", { property: "og:type", content: "website" }],
    ["meta", { property: "og:title", content: "Pi Agent.nvim" }],
    ["meta", { property: "og:description", content: "AI pair programming, inside Neovim." }],
    ["meta", { property: "og:url", content: "https://sunnybharne.github.io/pi-agent.nvim/" }],
    ["meta", { property: "og:image", content: "https://sunnybharne.github.io/pi-agent.nvim/og.png" }],
    ["meta", { name: "twitter:card", content: "summary_large_image" }],
    ["meta", { name: "twitter:title", content: "Pi Agent.nvim" }],
    ["meta", { name: "twitter:description", content: "AI pair programming, inside Neovim." }],
    ["meta", { name: "twitter:image", content: "https://sunnybharne.github.io/pi-agent.nvim/og.png" }],
  ],
  sitemap: {
    hostname: "https://sunnybharne.github.io/pi-agent.nvim/",
  },
  themeConfig: {
    logo: "/logo.png",
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
    outline: {
      level: [2, 3],
      label: "On this page",
    },
    editLink: {
      pattern: "https://github.com/sunnybharne/pi-agent.nvim/edit/main/docs/:path",
      text: "Edit this page on GitHub",
    },
    footer: {
      message: "A focused coding agent for Neovim.",
      copyright: "Copyright © 2026 Sunny Bharne",
    },
    docFooter: {
      prev: "Previous page",
      next: "Next page",
    },
  },
});
