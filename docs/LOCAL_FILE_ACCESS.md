# AUTO Sandboxed Local File Operations

## 1. Overview

AUTO provides safe, sandboxed file operations via [LocalFileManager.swift](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Agent/LocalFileManager.swift). This capability allows the companion agent to assist users with common desktop organization tasks—such as tidying up the `Downloads` directory, inspecting downloaded documents, and locating recent screenshots—while maintaining rigorous filesystem boundaries.

---

## 2. Allowed & Prohibited Directories

To prevent accidental modification of critical system files or private user credentials, AUTO strictly limits file manipulation to standard user document locations.

### Allowed Folders:
- `~/Desktop`
- `~/Downloads`
- `~/Documents`

### Strictly Blocked Paths:
- `/System`
- `/usr`
- `/bin`, `/sbin`
- `/etc`, `/var`, `/private`
- `~/.ssh`
- `~/.aws`, `~/.config`
- `~/Library/Keychains`

Any attempt to resolve, inspect, or move files within a blocked directory throws an immediate `AgentExecutionError.unauthorizedPath` error.

---

## 3. Supported File Capabilities

### 1. Directory Listing (`listDirectory`)
Returns file metadata including:
- File name and path
- File size (formatted as KB, MB, GB)
- Creation and modification timestamps
- File extension and uniform type identifier (UTI)

### 2. File Preview Extraction (`readFilePreview`)
Safely extracts text previews of text files (plain text, markdown, source code, CSV) up to a 4KB boundary, preventing memory exhaustion when reading large data files.

### 3. Safe File Organization (`organizeFiles`)
Groups files in a directory into neat subfolders based on file category:
- **Images**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.heic`, `.svg` -> `Images/`
- **Documents**: `.pdf`, `.docx`, `.pages`, `.xlsx`, `.pptx`, `.txt` -> `Documents/`
- **Archives**: `.zip`, `.tar`, `.gz`, `.dmg`, `.pkg` -> `Archives/`
- **Audio & Video**: `.mp3`, `.wav`, `.mp4`, `.mov`, `.mkv` -> `Media/`
- **Code**: `.swift`, `.py`, `.js`, `.ts`, `.json`, `.html`, `.css` -> `Code/`

Files are moved using `FileManager.default.moveItem(at:to:)`. Existing files with identical names are renamed with numeric suffixes (`file_1.pdf`) to avoid data overwrite or loss.

