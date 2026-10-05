# 🛡️ SafeRoute AI — Security Policy

## 1. Security Philosophy

SafeRoute AI follows a defense-in-depth security model:
1. **Zero Secret Exposure**: No service-role secrets or private backend API keys are shipped inside client mobile binaries.
2. **Server-Side Enforcement**: Client-side validations are supplemented by database Row Level Security (RLS) policies on Supabase tables.
3. **Fail-Safe Offline Execution**: Critical emergency SOS features rely on native device hardware (`SmsManager` & physical SIM) to guarantee operation even during complete internet or server outages.
4. **Input Sanitization**: Strict validation of coordinates (-90 to +90 lat, -180 to +180 lon), phone numbers, and string parameters.

---

## 2. Reporting a Vulnerability

If you discover a security vulnerability in SafeRoute AI, please report it responsibly:

* **Email**: Security vulnerability reports should be sent directly to project maintainers.
* **Response Timeline**: Acknowledgment within 48 hours; status updates provided during triage and remediation.
* **Public Disclosure**: Please allow maintainers time to patch identified vulnerabilities before public disclosure.

---

## 3. Supported Versions

| Version | Supported |
| :--- | :--- |
| 1.0.x (Current Release) | ✅ Supported |
| < 1.0.0 | ❌ Not Supported |

---

## 4. Known Security & Technical Limitations

* **Foreground Volume SOS**: Volume button sequence interception (`3 presses in 3s`) operates when SafeRoute AI is active in the foreground. Background/lock-screen key triggering is restricted by standard Android UI window listeners.
* **OpenStreetMap & Public OSRM**: Map data and public foot routing APIs are community-maintained; rate limiting or service unavailability on public servers can occur.
* **Cellular SMS Delivery**: Emergency SMS delivery depends on mobile network carrier availability, active SIM status, and recipient network state.
* **Deterministic Safety Scoring**: Calculated safety scores are informative indicators based on available signals and do not guarantee 100% real-world physical safety.
