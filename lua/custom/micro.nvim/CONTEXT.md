# Neovim Configuration

Personal editing workflows and their behaviour.

## Language

### Windows

**Panel**:
A transient window, floating or split, that micro creates, owns and cleans up to show generated content such as hover docs, the per-window statusline, the treesitter tree or web search results. Panel buffers are tagged so other features can recognise and skip them.
_Avoid_: popup, scratch window, eldoc window

### Cursor features

**Cursor context**:
The focused editing window, displayed document, cursor position and document text that hover or signature help refers to. Moving the cursor, editing the document or leaving the window ends that context, even if the same position is restored later.

### Completion

**Completion source**:
A provider of suggestions for the text being edited. The required sources are language-server suggestions, filesystem paths, and buffer words.

**Completion candidate**:
A suggestion offered for selection, together with the information needed to display it and apply it to the text.

**Candidate ranking**:
The order of completion candidates in a language context: language-server candidates before buffer words; within each group, better match quality first, then the server's own order (language server) or alphabetical order (buffer words).
_Avoid_: kind priority, sorting

**Path context**:
An editing position where the token being completed is path-shaped, such as `./src/`, `../`, `~/`, or `/tmp/`. Relative filesystem paths are interpreted from the effective working directory, not the current file's directory.

**Language context**:
An editing position that is not a path context. Language-server candidates and words from the current editing buffer may coexist here; neither source is restricted to fallback-only visibility.
