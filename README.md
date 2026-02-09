# MDView

A lightweight macOS app for reading Markdown files. Renders `.md` files with GitHub-flavored styling, syntax-highlighted code blocks, and live reload on file changes.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-Apache%202.0-green)

## Features

- **Live reload** -- automatically re-renders when the file changes on disk
- **Quick Open** (`Cmd+P`) -- fuzzy-search any Markdown file in the current directory
- **Drag & drop** -- drop a file or folder onto the window to open it
- **Directory-aware** -- open a folder to browse all its Markdown files
- **GitHub styling** -- light and dark themes that follow your system appearance
- **Syntax highlighting** -- fenced code blocks highlighted via highlight.js
- **External links** -- clicked links open in your default browser
- **No dependencies** -- pure Swift + WebKit, no external packages

## Install

```sh
make install
```

This builds a release binary, bundles it into `MDView.app`, and copies it to `/Applications`.

## Build & Run

```sh
# Build and open the app
make run

# Or just build
make
```

## Usage

```sh
# Open a file
open -a MDView README.md

# Open a directory (auto-loads README if present)
open -a MDView ~/projects/my-repo

# Or pass a path directly
.build/release/MDView ~/notes/todo.md
```

Inside the app:

| Shortcut | Action |
|----------|--------|
| `Cmd+O` | Open a file or directory |
| `Cmd+P` | Quick Open (fuzzy file search) |
| `Cmd+R` | Reload current file |

## Project Structure

```
Sources/MDView/
  App.swift             # Entry point, menus, CLI arg handling
  AppState.swift        # Core state: file loading, directory scanning, file watching
  ContentView.swift     # Main window layout, drag & drop, quick open overlay
  MarkdownWebView.swift # WKWebView wrapper that renders Markdown via marked.js
  HTMLTemplate.swift    # Self-contained HTML/CSS/JS (marked.js, highlight.js, GitHub themes)
  FileWatcher.swift     # DispatchSource-based file system watcher
  DirectoryScanner.swift# Recursive Markdown file discovery with smart directory skipping
  FuzzyMatch.swift      # Fuzzy string matching with streak/boundary bonuses
  QuickOpenView.swift   # Cmd+P palette UI with keyboard navigation
```

## How It Works

Markdown is rendered client-side in a `WKWebView` using [marked.js](https://github.com/markedjs/marked) and [highlight.js](https://github.com/highlightjs/highlight.js). The HTML template, CSS themes, and JS libraries are all embedded in `HTMLTemplate.swift` -- no network requests, no external files.

File changes are detected via GCD's `DispatchSource` file system events. When the file is modified, the new content is base64-encoded and sent to the web view via `evaluateJavaScript`.

## License

Apache 2.0 -- see [LICENSE](LICENSE).
