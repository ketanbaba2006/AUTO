# Google Gemini Setup Guide for AUTO

Google Gemini is the primary reasoning and screen understanding engine for AUTO.

## 1. Obtaining a Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/).
2. Sign in with your Google account.
3. Click **Get API key** in the top navigation.
4. Click **Create API key** (create in a new project or select an existing Google Cloud project).
5. Copy your generated API key.

> [!NOTE]
> Google AI Studio provides free quota tiers for models such as Gemini 2.5 Flash and Gemini 2.0 Flash. Check Google's pricing documentation for quota and rate limits.

---

## 2. Configuring Gemini in AUTO

1. Launch AUTO. The status item appears in your macOS menu bar.
2. Click the AUTO menu bar icon to open the Companion Panel.
3. Click the **Gear icon** in the footer to open **Settings**.
4. Click the **Gemini** tab.
5. In the **API Key** field, paste your Gemini API key.
6. Click **Save**.
   - Your key is immediately saved to the hardware-backed **macOS Keychain** under service `com.auto.desktop.companion`.
   - The key is masked in the UI and never written to plain text configuration or log files.
7. Click **Test Gemini Connection**.
   - AUTO verifies connectivity against `https://generativelanguage.googleapis.com/v1beta/models`.
   - A green checkmark with round-trip latency will confirm the connection.

---

## 3. Selecting Models

In the **Gemini** tab:
- **Default Recommended Model**: `gemini-3.8-flash` (fastest latency, multimodal vision, high rate limit).
- **Complex Reasoning Model**: `gemini-pro-latest` (deeper reasoning on complex desktop states).
- **Dynamic Model Discovery**: Click **Fetch Models** to query Google's live catalog and dynamically update the available models.

