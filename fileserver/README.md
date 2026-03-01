# 📦 FileServer

A GitHub-style file browser written in Go. Serves files from `data/files/` with syntax highlighting, image preview, raw view, and wget support.

## Features

- 📁 Directory listing with file icons and metadata
- 🔍 GitHub-style file viewer with syntax highlighting (via highlight.js)
- 🖼️ Image preview (PNG, JPG, GIF, SVG, WebP...)
- ⬡ Raw view for any file
- ⤓ Direct download
- 📋 One-click wget command copy
- 🔒 Path traversal protection
- 📦 Single binary with embedded templates (no external files needed)

## Quick Start

```bash
# Build
go build -o fileserver .

# Run (default port 8080)
./fileserver

# Run on custom port
./fileserver 9000
```

Then open http://localhost:8080

## File Layout

```
.
├── main.go
├── go.mod
├── templates/
│   ├── dir.html
│   └── file.html
└── data/
    └── files/         ← put your files here
        ├── README.md
        ├── images/
        └── ...
```

## Supported Previews

| Type | Extensions |
|------|-----------|
| Code | .go .py .js .ts .rs .java .c .cpp .rb .php .sh ... |
| Markup | .html .css .json .xml .yaml .toml .md |
| Images | .png .jpg .gif .svg .webp .bmp .ico |
| Other | Download prompt |

## Usage

- **Click a folder** → browse its contents  
- **Click a file** → GitHub-style preview  
- **Raw button** → raw file content (for text/images) or download (for binary)  
- **Download button** → force download  
- **wget command** → click Copy and paste in terminal  

```bash
# Example wget
wget "http://localhost:8080/path/to/file.txt?raw=1"
```

## Build for Multiple Platforms

```bash
# Linux
GOOS=linux GOARCH=amd64 go build -o fileserver-linux .

# macOS
GOOS=darwin GOARCH=arm64 go build -o fileserver-mac .

# Windows
GOOS=windows GOARCH=amd64 go build -o fileserver.exe .
```
