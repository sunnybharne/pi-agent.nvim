# Authentication

Pi Agent.nvim does not store API keys, tokens, passwords, or session credentials.

When using the bundled backend, authentication is handled by Codex. Run:

```vim
:PiAgentLogin
```

You can also log in from a terminal:

```sh
codex login
```

After login, verify from Neovim:

```vim
:PiAgentStatus
```

If a prompt returns `Runtime is not logged in`, complete `:PiAgentLogin` and retry.

## API Keys

The default path is ChatGPT sign-in through Codex. If you explicitly configure Codex to use API keys, billing and permissions belong to the API account behind that key.
