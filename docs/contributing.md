# Contributing

Pi Agent.nvim is intentionally small. Contributions should keep the Neovim surface predictable and keep runtime-specific behavior behind the backend command.

## Local Docs

Install dependencies:

```sh
npm install
```

Run the docs locally:

```sh
npm run docs:dev
```

Build the static site:

```sh
npm run docs:build
```

Preview the built site:

```sh
npm run docs:preview
```

## Release Shape

- Plugin code lives under `lua/pi_agent`.
- User commands are registered from `setup()`.
- The backend command lives at `bin/pi-agent`.
- Vim help lives at `doc/pi-agent.txt`.
- Website docs live under `docs`.
