# my-emacs-config

My Emacs configuration files.

## Requirements

Install [ripgrep](https://github.com/BurntSushi/ripgrep) and make sure the
`rg` executable is available on `PATH`. It is used by the project-wide search
command described below.

## Installation

Run the following command to clone the configuration files into `~/.emacs.d`:

```sh
git clone git@github.com:nagayasuu/my-emacs-config.git ~/.emacs.d
```

## External packages

The following external Emacs packages are installed automatically by
`use-package`:

| Package | Purpose |
| --- | --- |
| [`catppuccin-theme`](https://github.com/catppuccin/emacs) | Provides the Catppuccin Frappé color theme. |
| [`simple-modeline`](https://github.com/gexplorer/simple-modeline) | Provides a minimal mode line. |
| [`nerd-icons`](https://github.com/rainstormstudio/nerd-icons.el) | Adds file-type icons to tab-line tabs. |
| [`easy-kill`](https://github.com/leoliu/easy-kill) | Provides context-aware commands for copying and marking text. |
| [`mini-frame`](https://github.com/muffinmad/emacs-mini-frame) | Displays the minibuffer in a child frame. |
| [`vertico`](https://github.com/minad/vertico) | Displays minibuffer completion candidates vertically. |
| [`orderless`](https://github.com/oantolin/orderless) | Enables order-independent completion matching. |
| [`marginalia`](https://github.com/minad/marginalia) | Adds contextual annotations to completion candidates. |
| [`consult`](https://github.com/minad/consult) | Provides enhanced navigation and search commands. |
| [`corfu`](https://github.com/minad/corfu) | Displays completion-at-point candidates in a popup. |
| [`cape`](https://github.com/minad/cape) | Adds completion-at-point backends for words and file paths. |
| [`org-appear`](https://github.com/awth13/org-appear) | Reveals hidden Org markup around the cursor. |
| [`org-journal`](https://github.com/bastibe/org-journal) | Creates and manages journal entries in Org mode. |

## Additional key bindings

| Key | Command | Description |
| --- | --- | --- |
| `C-tab` | `consult-buffer` | Switch between buffers and recent files. |
| `C-c f` | `consult-find` | Select a directory and find files by name. |
| `C-c g` | `consult-ripgrep` | Select a directory and search its contents with ripgrep. |
| `C-c h` | `consult-org-agenda` | Select a heading from the Org agenda files. |
| `C-c l` | `org-store-link` | Store a link to the current location. |
| `C-c a` | `org-agenda` | Open the Org agenda dispatcher. |
| `C-c c` | `org-capture` | Capture a new entry using an Org capture template. |
| `C-c e` | `org-emphasize` | Add emphasis to text in an Org buffer. |
| `C-c j j` | `org-journal-new-entry` | Create a new Org journal entry. |
| `C-c j o` | `org-journal-open-current-journal-file` | Open the current Org journal file. |
