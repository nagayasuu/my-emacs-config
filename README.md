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

## Additional key bindings

| Key | Command | Description |
| --- | --- | --- |
| `C-tab` | `consult-buffer` | Switch between buffers and recent files. |
| `C-c r` | `consult-ripgrep` | Select a directory and search its contents with ripgrep. |
| `C-c l` | `org-store-link` | Store a link to the current location. |
| `C-c a` | `org-agenda` | Open the Org agenda dispatcher. |
| `C-c c` | `org-capture` | Capture a new entry using an Org capture template. |
| `C-c e` | `org-emphasize` | Add emphasis to text in an Org buffer. |
