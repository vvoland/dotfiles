# Neovim config

## GitHub Actions links

In YAML buffers, press `gx` on a `uses: owner/repo@ref` reference to open it
on GitHub. A version-only comment selects a release; otherwise the link
opens the commit, tag, or branch. Subdirectories and reusable workflows work too.

```yaml
uses: docker/login-action@dbcb813823bdd20940b903addbd779551569679f # v4.6.0
```

This opens the `v4.6.0` release, which must exist under that exact tag.
References are also terminal hyperlinks (OSC 8): **Ctrl+Shift-click** in
Kitty, even with Neovim's mouse mode disabled. Links update as you edit;
other links keep normal `gx` behavior.

Requires Neovim 0.10+; terminal hyperlinks also require OSC 8 support.
Implemented by the local [ghactions.nvim plugin](lua/plugins/ghactions),
loaded by lazy.nvim for YAML buffers.

## `:Diff [revision]`

Compare a revision (default `HEAD~1`) against the working tree, with editable
working-tree files.

```fish
nvim -c Diff
nvim -c 'Diff main'
```

## `:GHLines`

Copy a GitHub permalink at `HEAD` for the current line or an Ex/Visual line
range. Requires a file committed at `HEAD` and a GitHub `origin` remote (HTTPS
or SSH). The link goes to the unnamed register and, when available, the system
clipboard. Local edits trigger a warning: line numbers refer to `HEAD`, not
the edited buffer.

```vim
:GHLines
:42,58GHLines
:'<,'>GHLines
```

## `:Paw [comment]`

Queue a comment for Paw with the current line or an Ex/Visual line range,
including unsaved buffer text. Without a comment, prompt for one. Buffers
without a local file context send only the comment.

```vim
:Paw Explain this fallback
:42,58Paw Can this be simpler?
:Paw
```

Requires Neovim 0.10+ and a `paw` executable supporting `paw send --json`.
Start Neovim from the intended Kitty pane so Paw can route the comment.
Replies stay in Paw; “Queued for Paw” confirms enqueue, not an answer.
See [the Paw integration guide](PAW.md) for configuration, delivery caveats,
and workflow details.

## `:AI`

Request an inline code suggestion at the cursor from the OpenAI API. This
sends nearby buffer text, including unsaved changes, and the filetype to
OpenAI. Requires `curl` and an API key from `OPENAI_API_KEY`, the macOS
Keychain service `OpenAI`, or the `OpenAI` entry in `pass`, in that order.

In Insert mode, `<C-l>` requests a suggestion or accepts the displayed ghost
text. Typing, moving the cursor in Insert mode, or leaving Insert mode
discards it. Accepting while the response streams inserts what has arrived
so far.

## `:Quotes [quote]`

Replace all single quotes with double quotes in the current buffer by
default, or all double quotes with single quotes when passed `'`. Only `'`
and `"` are accepted. This is a whole-buffer text substitution, not a
syntax-aware conversion; it also changes quotes in comments and strings.

```vim
:Quotes
:Quotes '
:Quotes "
```
