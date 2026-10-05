# 🔒 SafeRoute AI — Privacy Policy

> **Effective Date**: October 2026  
> **Application**: SafeRoute AI Pedestrian Safety Navigation

SafeRoute AI is designed with a privacy-first mindset. This Privacy Policy details what information the application accesses, stores, and transmits, and how user privacy is safeguarded.

---

## 1. Information Collected & Accessed

### A. Device Location (GPS)
* **Usage**: Location access (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) is used locally on your device to display your current position on the map, provide live turn-by-turn walking guidance, calculate proximity to hazards, and embed current GPS coordinates into Emergency SOS alerts when triggered.
* **Storage & Sharing**: Your continuous GPS trail is **not** uploaded to public servers or sold to third parties. Precise coordinates are transmitted **only** in the following verified scenarios:
  1. When you explicitly trigger an **Emergency SOS alert** (sent directly via SIM SMS to your configured emergency contact).
  2. When submitting a community hazard report (the coordinate of the hazard location is published anonymously to the map).

### B. Account Information
* **Authentication**: When creating an account via Email/Password or 1-Tap Google Sign-In, authentication credentials are processed securely through Firebase Authentication and synchronized with Supabase DB.
* **Data Scoping**: User profiles, custom safety preferences, and emergency contact configurations are user-scoped and protected by database Row Level Security (RLS).

### C. Emergency Contacts
* **Storage**: Primary emergency contact details (Name, Phone Number, Relationship) are saved locally on your device (`SharedPreferences`) for offline emergency reliability and synced with your private user record in Supabase.
* **Display Privacy**: Phone numbers are masked on-screen (`+91 ******1234`) to prevent public shoulder-surfing exposure.

### D. Community Hazard Reports
* **Public Visibility**: Hazard reports (category, location coordinates, timestamp, description, and optional photo) submitted by users are shared publicly to warn other pedestrians.
* **Moderation & Expiry**: Community reports expire automatically based on hazard category (e.g., 24 hours for stray animals, 7 days for poor lighting) to maintain freshness.

---

## 2. Data Security & Storage

* **Row Level Security (RLS)**: PostgreSQL Row Level Security is enforced on Supabase tables to ensure users can only read/write their own private data records.
* **Offline First**: Sensitive emergency configurations are stored locally on device storage so emergency SOS features function even without an internet connection.
* **No Secret Storage in App**: Private API keys and service-role secrets are strictly kept off client mobile devices.

---

## 3. Third-Party Services

SafeRoute AI interacts with open geographic and routing services:
* **OpenStreetMap (OSM)**: Map tiles rendering.
* **OSRM Foot Routing API**: Pedestrian path calculation.
* **Nominatim**: Destination address search.

*These services receive query parameters (search query, origin/destination coordinates) required to compute route navigation.*

---

## 4. Emergency SOS Disclaimer

Emergency SOS alerts transmit your current or last known location directly via native cellular SMS (`SmsManager`) to your primary emergency contact. SafeRoute AI is an emergency assistance tool and does not replace official emergency services (e.g., 112 / 911).

---

## 5. Contact & Updates

For privacy inquiries or account data deletion requests, contact the project maintainers.
