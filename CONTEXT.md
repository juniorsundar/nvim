# Neovim Configuration

Personal editing workflows and their behaviour.

## Language

### Windows

**Panel**:
A transient window, floating or split, that micro creates, owns and cleans up to show generated content such as hover docs, the per-window statusline, the treesitter tree or web search results. Panel buffers are tagged so other features can recognise and skip them.
_Avoid_: popup, scratch window, eldoc window

### Completion

**Completion source**:
A provider of suggestions for the text being edited. The required sources are language-server suggestions, filesystem paths, and buffer words.

**Completion candidate**:
A suggestion offered for selection, together with the information needed to display it and apply it to the text.

**Path context**:
An editing position where the token being completed is path-shaped, such as `./src/`, `../`, `~/`, or `/tmp/`. Relative filesystem paths are interpreted from the effective working directory, not the current file's directory.

**Language context**:
An editing position that is not a path context. Language-server candidates and words from the current editing buffer may coexist here; neither source is restricted to fallback-only visibility.
