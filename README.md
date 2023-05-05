# Autoedit

A script for editing GNU Autoconf configuration.

Runs `./config.status --config` (if generated) and lets the user edit the
existing configuration using their preferred text editor (configured by the
`EDITOR` environment variable). Afterwards, runs the `./configure` command with
the resulting configuration.

The operation may be canceled by putting a `@` at the beginning of the temporary
file.

Autoedit supports line comments prepended with `#` and uses them to provide the
user with useful information (much like what Git does with commit messages
and/or interactive rebases).


## Installation

Simply copy or symlink the `autoedit.sh` file somewhere onto your `PATH`.


## License

MIT license -- see `LICENSE` for more info
