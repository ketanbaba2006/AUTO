# Security Policy

## Supported Versions

Only the latest release of AUTO receives security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

---

## Reporting a Vulnerability

We take the security of AUTO and your workstation with utmost seriousness.

If you believe you have discovered a security vulnerability in AUTO (such as credential exposure, unauthorized local file access, improper permission elevation, or prompt injection that bypasses safety gating):

1. **Do NOT report security vulnerabilities via public GitHub issues.**
2. Report the vulnerability privately via **GitHub Private Vulnerability Reporting** on the repository page (under *Security* -> *Report a vulnerability*).
3. If private reporting is unavailable, contact the project maintainers directly via private email or encrypted communication.

### What to Include
- Detailed steps to reproduce the vulnerability.
- Proof of concept code or instructions.
- Target macOS version and architecture (Apple Silicon / Intel).
- An explanation of potential impact and proposed mitigations if known.

### Response Timeline
- We will acknowledge receipt of your report within 48 hours.
- We will evaluate the impact and provide status updates every 72 hours until a fix is deployed.
- A public security advisory will be published once the patch is released.

---

## Security Guarantees & Built-In Defenses

- **Local Hardware Keychain**: All API secrets (Google Gemini, OmniRoute) are stored via macOS Keychain Services (`kSecClassGenericPassword`).
- **RAM-Only Ephemeral Captures**: Screen snapshots and microphone recordings exist in volatile memory only during active inference and are purged immediately.
- **Three-Tier Action Gating**: Destructive actions require explicit modal confirmation from the user.
- **Hardware-Level Stop**: Dedicated local emergency stop halts simulated actions in under 10 milliseconds.
- **Sandboxed Local File Operations**: The agent is restricted to standard user document locations (`~/Desktop`, `~/Downloads`, `~/Documents`) and blocked from accessing system folders or credentials (`~/.ssh`, `~/Library/Keychains`).

