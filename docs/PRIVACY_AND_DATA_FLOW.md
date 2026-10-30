# Privacy Architecture & Data Flow in AUTO

## Overview

AUTO is engineered around an uncompromising **Privacy-First Mandate**:
- **Zero Telemetry**: No analytics, crash loggers, trackers, or usage beacons.
- **Zero Cloud Storage**: All memory, settings, preferences, and action history remain on the user's Mac in local SQLite.
- **Zero-Screenshot Transmission by Default**: Screen images are parsed locally using Apple Vision OCR; raw pixels are never uploaded without explicit consent.
- **Hardware-Backed Key Storage**: API keys are saved exclusively in macOS Keychain (`kSecClassGenericPassword`).

---

## 1. End-to-End Data Flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Mic as AutoVoiceManager (AVFoundation)
    participant Speech as Apple Speech Recognizer (On-Device)
    participant Screen as AutoScreenManager (ScreenCaptureKit)
    participant Vision as Apple Vision OCR (Neural Engine)
    participant Memory as AutoMemoryManager (SQLite)
    participant Firewall as Sensitive Data Firewall
    participant Gemini as Google Gemini API (HTTPS)
    participant Engine as AutoExecutionEngine (Local Swift)

    User->>Mic: Hold Control Key & Speak
    Mic->>Speech: Audio Stream (Local)
    Speech->>Memory: Raw User Text
    Note over Memory,Firewall: Regex Firewall Scrubs Tokens/Passphrases
    
    opt When Screen Context Needed
        Memory->>Screen: Request Frame
        Screen->>Vision: Local OCR Analysis
        Vision-->>Firewall: Extracted Text & Element Bounds
    end
    
    Firewall->>Gemini: Clean Prompt + Local OCR Text
    Note over Gemini: Reasoning & Step Decomposition
    Gemini-->>Engine: Structured Action Proposal (JSON)
    Engine->>User: Native Execution on macOS Desktop
```

---

## 2. Zero-Screenshot Transmission Policy

Unlike standard cloud desktop agents that continually stream raw 4K video or screenshots to third-party cloud servers, AUTO adheres to a **Local-First Visual Extraction** principle:

1. **Local Vision OCR**:
   - `AutoScreenManager` captures frames via `ScreenCaptureKit`.
   - The Apple Vision framework (`VNRecognizeTextRequest`) extracts text strings and bounding rectangles locally using the on-device Apple Neural Engine.
   - Only the structured text and coordinate boxes are sent to Gemini for semantic understanding.

2. **Visual Transmission Gate**:
   - In **Settings -> Hybrid Engine**, users have an explicit toggle: `Allow Screenshot Transmission`.
   - When **disabled (default)**, Gemini receives only text and OCR structural metadata.
   - When **enabled**, compressed screenshots (JPEG, 70% quality, 1920px max dimension) are transmitted over TLS directly to Gemini for multimodal spatial reasoning.

---

## 3. Sensitive Data Firewall

Before any text is saved to local SQLite memory or forwarded to Gemini:
`AutoMemoryManager` filters content through sensitive credential regex patterns:
- High-entropy API tokens (e.g., `AIzaSy...`, `sk-proj-...`, `ghp_...`)
- Private RSA/ED25519 keys (`-----BEGIN PRIVATE KEY-----`)
- Password assignment formats (`password = ...`, `token: ...`)
- Credit card sequences and security numbers

Matching fragments are immediately redacted (`[REDACTED SENSITIVE DATA]`) and prevented from entering conversational context.

---

## 4. Local SQLite Memory Isolation

All memory is stored in:
`~/Library/Application Support/AUTO/memory.sqlite`

- Managed using native SQLite C-bindings (`import SQLite3`).
- Partitioned into structured categories: `preferences`, `context`, `task_history`, and `facts`.
- Users can view, search, export, or completely purge local memory at any time with one click in **Settings -> Privacy**.
