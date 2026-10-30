# AUTO API Configuration & Credential Security

## 1. Security Architecture

AUTO adheres to strict privacy and credential isolation standards on macOS:

1. **macOS Keychain Storage**:
   - API keys are never stored in `UserDefaults`, JSON files, plain-text plists, environment variables, or Git repositories.
   - Keys are encrypted with AES-256 via Apple's Security framework (`SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate`, `SecItemDelete`).
   - Service name: `com.auto.desktop.companion`
   - Accounts:
     - `gemini_api_key`: Google Gemini API Key

2. **Zero Plain-Text Credential Display**:
   - Once saved to Keychain, keys are masked in the UI with bullet characters (`••••••••`).
   - The user can clear the key at any time using the **Clear** button.

3. **Zero Telemetry**:
   - AUTO does not bundle analytics libraries (no PostHog, Google Analytics, Firebase, or Sentry).
   - All network calls originate strictly between your Mac and the Google Gemini API you configure.

---

## 2. API Endpoints Reference

### Google Gemini API
| Purpose | Method | Path |
| :--- | :--- | :--- |
| Model Discovery | `GET` | `/v1beta/models?key={apiKey}` |
| Generate Content | `POST` | `/v1beta/models/{modelId}:generateContent?key={apiKey}` |
| Streaming Response | `POST` | `/v1beta/models/{modelId}:streamGenerateContent?alt=sse&key={apiKey}` |

---

## 3. Error Handling and Recovery

| Error Type | HTTP Status | Description & User Guidance |
| :--- | :--- | :--- |
| `authenticationFailed` | 401, 403 | Invalid API key or expired token. Verify key in Settings. |
| `rateLimitExceeded` | 429 | Provider rate limit exceeded. AUTO automatically retries with exponential backoff (1s, 2s). |
| `modelNotFound` | 404 | Model ID is incorrect or deprecated. Use Dynamic Model Discovery to select an active model. |
| `serverUnavailable` | 500, 502, 503 | Server error. Complex tasks fall back to local offline capabilities. |
| `requestTimeout` | Timeout | Network latency exceeded timeout. Configurable in settings. |
| `cancelled` | - | User triggered a new request or hit Cancel. Active connection is aborted cleanly. |
