package main

import (
	"embed"
	"encoding/base64"
	"fmt"
	"html/template"
	"io"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

//go:embed templates/*
var templateFS embed.FS

type FileInfo struct {
	Name    string
	Size    int64
	ModTime time.Time
	IsDir   bool
	Path    string
	Ext     string
}

type DirData struct {
	Path  string
	Parts []PathPart
	Files []FileInfo
}

type FileData struct {
	Path      string
	Parts     []PathPart
	Name      string
	Size      int64
	Ext       string
	Content   string
	IsText    bool
	IsTooBig  bool
	IsImage   bool
	ImageB64  string
	ImageMime string
	RawURL    string
	WgetCmd   string
}

type PathPart struct {
	Name string
	Path string
}

// 优先读取 DATA_DIR 环境变量，容器内由 entrypoint.sh 设置为 /data/files
var dataRoot = func() string {
	if v := os.Getenv("DATA_DIR"); v != "" {
		return v
	}
	return "data/files"
}()

func main() {
	port := "8080"
	if len(os.Args) > 1 {
		port = os.Args[1]
	}
	if err := os.MkdirAll(dataRoot, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Cannot create %s: %v\n", dataRoot, err)
	}
	http.HandleFunc("/__last_update__", lastUpdateHandler)
	http.HandleFunc("/", handler)
	fmt.Printf("🚀 FileServer running at http://localhost:%s\n", port)
	fmt.Printf("📁 Serving: %s\n", dataRoot)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

// lastUpdateFile 与 dataRoot 同级的上一层目录下的 .last_update 文件
var lastUpdateFile = func() string {
	if v := os.Getenv("DATA_DIR"); v != "" {
		// DATA_DIR=/data/files  →  /data/.last_update
		return filepath.Join(filepath.Dir(v), ".last_update")
	}
	return filepath.Join(filepath.Dir("data/files"), ".last_update")
}()

func lastUpdateHandler(w http.ResponseWriter, r *http.Request) {
	data, err := os.ReadFile(lastUpdateFile)
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	if err != nil {
		w.Write([]byte(""))
		return
	}
	w.Write([]byte(strings.TrimSpace(string(data))))
}

var funcMap = template.FuncMap{
	"formatSize": formatSize,
	"formatTime": func(t time.Time) string { return t.Format("2006-01-02 15:04") },
	"fileIcon":   fileIcon,
	"langClass":  langClass,
	"add":        func(a, b int) int { return a + b },
}

// isBrowser 判断请求是否来自浏览器：Accept 头包含 text/html 即视为浏览器
func isBrowser(r *http.Request) bool {
	return strings.Contains(r.Header.Get("Accept"), "text/html")
}

func handler(w http.ResponseWriter, r *http.Request) {
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	fsPath := filepath.Join(dataRoot, filepath.FromSlash(urlPath))
	absData, _ := filepath.Abs(dataRoot)
	absPath, err := filepath.Abs(fsPath)
	if err != nil || !strings.HasPrefix(absPath, absData) {
		http.Error(w, "Forbidden", 403)
		return
	}
	info, err := os.Stat(fsPath)
	if err != nil {
		http.Error(w, "Not Found: "+urlPath, 404)
		return
	}
	if info.IsDir() {
		// 目录：浏览器显示列表页，wget/curl 返回 404（目录无原始内容）
		if isBrowser(r) {
			serveDir(w, r, fsPath, urlPath)
		} else {
			http.Error(w, "Not a file: "+urlPath, 404)
		}
		return
	}
	// 文件：浏览器显示预览页，wget/curl 直接返回原始内容
	if isBrowser(r) {
		serveFile(w, r, fsPath, urlPath)
	} else {
		serveRaw(w, r, fsPath)
	}
}

func serveDir(w http.ResponseWriter, r *http.Request, fsPath, urlPath string) {
	entries, err := os.ReadDir(fsPath)
	if err != nil {
		http.Error(w, "Error reading directory", 500)
		return
	}
	var files []FileInfo
	for _, e := range entries {
		info, _ := e.Info()
		filePath := urlPath
		if filePath != "" {
			filePath += "/"
		}
		filePath += e.Name()
		ext := ""
		if !e.IsDir() {
			ext = strings.ToLower(filepath.Ext(e.Name()))
		}
		files = append(files, FileInfo{
			Name:    e.Name(),
			IsDir:   e.IsDir(),
			Size:    info.Size(),
			ModTime: info.ModTime(),
			Path:    "/" + filePath,
			Ext:     ext,
		})
	}
	sort.Slice(files, func(i, j int) bool {
		if files[i].IsDir != files[j].IsDir {
			return files[i].IsDir
		}
		return strings.ToLower(files[i].Name) < strings.ToLower(files[j].Name)
	})
	data := DirData{
		Path:  urlPath,
		Parts: buildParts(urlPath),
		Files: files,
	}
	tmpl := template.Must(template.New("dir.html").Funcs(funcMap).ParseFS(templateFS, "templates/dir.html"))
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	tmpl.Execute(w, data)
}

func serveFile(w http.ResponseWriter, r *http.Request, fsPath, urlPath string) {
	info, _ := os.Stat(fsPath)
	ext := strings.ToLower(filepath.Ext(fsPath))
	name := filepath.Base(fsPath)
	scheme := "http"
	if r.TLS != nil {
		scheme = "https"
	}
	rawURL := fmt.Sprintf("%s://%s/%s", scheme, r.Host, urlPath)
	fd := FileData{
		Path:    urlPath,
		Parts:   buildParts(urlPath),
		Name:    name,
		Size:    info.Size(),
		Ext:     ext,
		RawURL:  rawURL,
		WgetCmd: fmt.Sprintf(`wget "%s"`, rawURL),
	}
	if isImageFile(ext) {
		data, err := os.ReadFile(fsPath)
		if err == nil {
			fd.IsImage = true
			fd.ImageB64 = base64.StdEncoding.EncodeToString(data)
			fd.ImageMime = mime.TypeByExtension(ext)
			if fd.ImageMime == "" {
				fd.ImageMime = "image/png"
			}
		}
	} else if isTextFile(ext) {
		if info.Size() > 500*1024 {
			fd.IsTooBig = true
		} else {
			data, err := os.ReadFile(fsPath)
			if err == nil {
				fd.IsText = true
				fd.Content = string(data)
			}
		}
	}
	tmpl := template.Must(template.New("file.html").Funcs(funcMap).ParseFS(templateFS, "templates/file.html"))
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	tmpl.Execute(w, fd)
}

func serveRaw(w http.ResponseWriter, r *http.Request, fsPath string) {
	ext := strings.ToLower(filepath.Ext(fsPath))
	ct := mime.TypeByExtension(ext)
	if ct == "" {
		ct = "application/octet-stream"
	}
	f, err := os.Open(fsPath)
	if err != nil {
		http.Error(w, "Not Found", 404)
		return
	}
	defer f.Close()
	info, _ := f.Stat()
	w.Header().Set("Content-Type", ct)
	w.Header().Set("Content-Length", fmt.Sprintf("%d", info.Size()))
	if !isTextFile(ext) && !isImageFile(ext) {
		w.Header().Set("Content-Disposition",
			fmt.Sprintf(`attachment; filename="%s"`, filepath.Base(fsPath)))
	}
	io.Copy(w, f)
}

func buildParts(urlPath string) []PathPart {
	parts := []PathPart{{Name: "root", Path: "/"}}
	if urlPath == "" {
		return parts
	}
	for _, seg := range strings.Split(urlPath, "/") {
		if seg == "" {
			continue
		}
		prev := parts[len(parts)-1].Path
		if prev == "/" {
			prev = ""
		}
		parts = append(parts, PathPart{Name: seg, Path: prev + "/" + seg})
	}
	return parts
}

func formatSize(size int64) string {
	switch {
	case size < 1024:
		return fmt.Sprintf("%d B", size)
	case size < 1024*1024:
		return fmt.Sprintf("%.1f KB", float64(size)/1024)
	case size < 1024*1024*1024:
		return fmt.Sprintf("%.1f MB", float64(size)/(1024*1024))
	default:
		return fmt.Sprintf("%.1f GB", float64(size)/(1024*1024*1024))
	}
}

func isTextFile(ext string) bool {
	switch ext {
	case ".txt", ".md", ".go", ".py", ".js", ".ts", ".jsx", ".tsx",
		".html", ".htm", ".css", ".scss", ".json", ".xml", ".yaml", ".yml",
		".toml", ".sh", ".bash", ".zsh", ".c", ".cpp", ".h", ".java",
		".rs", ".rb", ".php", ".swift", ".kt", ".scala", ".r", ".sql",
		".graphql", ".proto", ".conf", ".ini", ".env", ".log", ".csv",
		".vue", ".svelte", ".tf", ".gitignore", ".gitattributes", ".dockerfile":
		return true
	}
	return false
}

func isImageFile(ext string) bool {
	switch ext {
	case ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".bmp", ".ico":
		return true
	}
	return false
}

func langClass(ext string) string {
	m := map[string]string{
		".go": "go", ".py": "python", ".js": "javascript", ".ts": "typescript",
		".jsx": "javascript", ".tsx": "typescript", ".html": "html", ".htm": "html",
		".css": "css", ".scss": "scss", ".json": "json", ".xml": "xml",
		".yaml": "yaml", ".yml": "yaml", ".toml": "toml", ".sh": "bash",
		".bash": "bash", ".c": "c", ".cpp": "cpp", ".h": "c", ".java": "java",
		".rs": "rust", ".rb": "ruby", ".php": "php", ".swift": "swift",
		".kt": "kotlin", ".sql": "sql", ".md": "markdown", ".r": "r",
		".proto": "protobuf", ".graphql": "graphql", ".tf": "hcl",
	}
	if lang, ok := m[ext]; ok {
		return lang
	}
	return "plaintext"
}

func fileIcon(f FileInfo) string {
	if f.IsDir {
		return "📁"
	}
	icons := map[string]string{
		".go": "🐹", ".py": "🐍", ".js": "🟨", ".ts": "🔷", ".jsx": "⚛️", ".tsx": "⚛️",
		".html": "🌐", ".css": "🎨", ".json": "📋", ".md": "📝", ".txt": "📄",
		".sh": "⚙️", ".bash": "⚙️", ".pdf": "📕", ".zip": "📦", ".tar": "📦",
		".gz": "📦", ".png": "🖼️", ".jpg": "🖼️", ".jpeg": "🖼️", ".gif": "🖼️",
		".svg": "🖼️", ".mp4": "🎬", ".mp3": "🎵", ".wav": "🎵", ".yml": "⚙️",
		".yaml": "⚙️", ".toml": "⚙️", ".sql": "🗄️", ".rs": "🦀", ".java": "☕",
		".rb": "💎", ".php": "🐘", ".swift": "🍎", ".kt": "🎯", ".csv": "📊",
		".log": "📜", ".env": "🔐", ".conf": "⚙️", ".xml": "📋",
	}
	if icon, ok := icons[f.Ext]; ok {
		return icon
	}
	return "📄"
}
