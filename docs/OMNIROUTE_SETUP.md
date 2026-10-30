# OmniRoute Gateway Setup Guide for AUTO

OmniRoute is an optional, open-source AI routing gateway that allows AUTO to communicate with local models (e.g., via Ollama, vLLM, LM Studio) or alternative remote cloud providers.

Official project:
[https://github.com/omni-route/omni-route](https://github.com/omni-route/omni-route)

---

## 1. Local Setup

### 1.1 Running a Local Gateway
When running OmniRoute locally, it typically exposes an OpenAI-compatible endpoint on port 20128:
```bash
http://localhost:20128/v1
```

### 1.2 Configuring Local Profile in AUTO
1. Open **AUTO Settings** > **OmniRoute** tab.
2. Toggle **Enabled** to ON.
3. The default profile `Local OmniRoute Gateway` is configured with:
   - Base URL: `http://localhost:20128/v1`
   - Connection Type: `Local`
4. If your local gateway requires authentication, paste your token in the API Key field and click **Save Key**.
5. Click **Test OmniRoute Connection**.

---

## 2. Remote Profile Setup

To connect to a self-hosted OmniRoute instance on your home server or cloud VPS:
1. Open **AUTO Settings** > **OmniRoute** tab.
2. Click **+ Add Profile**.
3. Enter:
   - **Profile Name**: e.g. `Home Lab Server`
   - **Base URL**: e.g. `https://omniroute.internal.lan/v1`
   - **Type**: `Remote`
4. Click **Create Profile**.
5. Select the profile and paste your bearer token in the **API Key** field.
6. Click **Test OmniRoute Connection**.

---

## 3. Dynamic Model Discovery

Click **Refresh** under **Models & Routing** > **Dynamic Model Browser** to inspect all models reported by the OmniRoute server via `GET /v1/models`.
Models supporting vision will automatically display the `Vision` badge.

---

## 4. Automatic Fallback Behavior

If OmniRoute is selected for a task but the local or remote server becomes unreachable (e.g., server offline, connection refused), AUTO automatically logs a warning, alerts the user, and routes the request to **Google Gemini** so your desktop companion never leaves you hanging.

