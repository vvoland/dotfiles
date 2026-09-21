# ghactions.nvim

Open GitHub Actions references with `gx` or terminal hyperlinks (OSC 8).
Requires Neovim 0.10+; terminal hyperlinks also need OSC 8 support.

```yaml
uses: docker/login-action@dbcb813823bdd20940b903addbd779551569679f # v4.6.0
```

In YAML buffers, `gx` on the reference opens the `v4.6.0` release. A
version-only comment selects a release under that exact tag; otherwise the
link opens the commit, tag, or branch. Subdirectories and reusable workflows
work too. Local and container actions are left alone.

In Kitty, **Ctrl+Shift-click** opens the same link without enabling Neovim's
mouse mode. Hyperlinks update as you edit.

## Setup

With lazy.nvim and a local checkout:

```lua
{
  dir = "/path/to/ghactions.nvim",
  ft = { "yaml", "yaml.gha" },
  main = "ghactions",
  opts = {},
}
```

Without a plugin manager, add this directory to `runtimepath` and call
`require("ghactions").setup()`.

Only normal-mode `gx` in YAML buffers is changed. Other links use the
previous mapping, including custom Lua, string, or expression mappings.
If `gx` was unmapped, it does nothing outside action references.

## Tests

From this directory:

```fish
nvim --headless -u NONE -i NONE -l tests/ghactions.lua
```

To check lazy loading with either filetype opening first:

```fish
for ft in yaml yaml.gha
    env LAZY_NVIM_PATH=/path/to/lazy.nvim GHACTIONS_TEST_FILETYPE=$ft nvim --headless -u NONE -i NONE -l tests/lazy.lua
end
```
