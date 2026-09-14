# Send buffer comments to Paw

This config provides `:Paw` through `lua/paw.lua`, enabled in `init.lua`.
Requires **Neovim 0.10+** and a Paw executable implementing **`paw send --json`**
with the version 1 editor payload. The Neovim integration does not implement
that CLI or access Paw's inbox files.

## Usage

```vim
:Paw Explain this fallback
:42,58Paw Can this be simpler?
:Paw
```

- With no range, send the **current cursor line** with the comment.
- With an Ex range, send all lines in that range, inclusively.
- From Visual mode, press `:` and enter `Paw Can this be simpler?`; Neovim
  supplies `'<,'>`. All selections are **linewise**, even characterwise and
  blockwise selections. No column-accurate selection is implied.
- Without arguments, prompt with `vim.ui.input`. Cancel or blank input sends
  nothing. The buffer, path, filetype, modified flag, and selected lines are
  captured **before** opening the prompt, not when the answer arrives.

Snapshots come from the in-memory buffer, including unsaved changes, without
saving or adding a final newline. They are not evidence of current disk
contents. Named local files need not exist yet. Unnamed, special, and URI
buffers send only the comment, with a notification explaining the missing
context. Encoded payloads larger than 1 MiB are rejected, never truncated.

`Queued for Paw` means Paw reported a durable enqueue, **not** that Paw has read
or answered the comment. Replies stay in Paw's UI. On errors, read the
notification for CLI diagnostics. A timeout or invalid response may occur
after enqueue: the result is uncertain, and sending again could duplicate the
comment. This integration never retries automatically.

## Configuration

The existing setup call uses `paw` from Neovim's inherited `PATH`. To change it,
replace that call in `init.lua` with, for example:

```lua
require("paw").setup({ paw_executable = "/absolute/path/to/paw" })
```

This is one executable path/name, not a shell command with flags. Arguments,
comments, and snapshots are never interpolated into shell commands. The send
runs asynchronously with a five-second timeout; it does not change cwd or the
environment, signal Paw, resume it, or acquire the terminal.

No key mappings are installed. Optional mappings can invoke the same command:

```lua
vim.keymap.set("n", "<leader>ap", "<cmd>Paw<CR>", { desc = "Comment to Paw" })
vim.keymap.set("x", "<leader>ap", ":Paw<CR>", { desc = "Comment on lines to Paw" })
```

## Kitty workflow and remaining end-to-end verification

Start Neovim **from the intended Kitty pane**. Paw routes using inherited
`KITTY_PID` and `KITTY_WINDOW_ID`, independent of Neovim's cwd. An existing
Neovim server launched elsewhere retains its own environment; connecting a UI
from this pane does not fix its routing. No Kitty remote-control configuration
is needed.

Once the Paw CLI/receiver implementation is available, verify in real Kitty:

1. Start interactive Paw, submit work, and press Ctrl+Z.
2. Start `nvim` in the same pane, optionally from another directory. Edit a
   named file without saving; use cursor and Visual-range `:Paw` commands to
   send several comments. Check for `Queued for Paw` without background
   terminal output or Paw resuming.
3. Close Neovim normally, preserving any edits you want to keep, and run `fg`.
   Confirm Paw shows the comments and exact unsaved snapshots as follow-up
   input. Also test sending while Paw is running.
4. Start a newer Paw in the pane and verify latest-instance routing. Exit that
   instance and confirm sends fail rather than reaching an older instance.
   Check missing Kitty environment and dead-target diagnostics as well.

The real Paw/Kitty suspend/edit/send/resume workflow is **not yet verified** by
this Neovim-only change. The queue's crash-recovery semantics belong to Paw;
this module relies only on its public CLI response and never replays messages.

## Tests

From this Neovim config directory:

```sh
nvim --headless -u NONE -l tests/paw.lua
```

The suite uses real Neovim buffers and Ex commands with a stubbed `vim.system`
to inspect argv, JSON, pre-prompt capture, state preservation, limits, errors,
and notifications. It also exercises real subprocess success with a temporary
fake CLI, a missing executable, and a real timeout (the suite takes at least
five seconds). No plugin manager, actual Paw inbox, or Kitty is required.
Fake CLI tests are not a substitute for the real workflow above.
