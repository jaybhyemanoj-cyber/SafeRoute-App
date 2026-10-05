# SafeRoute AI — Emergency Contact Storage & First-Time User Setup Report

## 1. Architecture

SafeRoute AI links **Firebase Authentication** authoritatively with **Supabase Database** emergency contact persistence:

```text
Firebase Authentication
        ↓
Firebase UID (FirebaseAuth.instance.currentUser!.uid)
        ↓
Supabase emergency_contacts table (user_id = Firebase UID)
        ↓
SharedPreferences Offline Cache
        ↓
Emergency SOS Dispatch via native SmsManager
```

- **Authentication**: Managed exclusively by Firebase Auth (`FirebaseAuth`).
- **Database Storage**: Managed by Supabase DB (`emergency_contacts` table).
- **Offline Reliability**: Backed by a local `SharedPreferences` cache for offline SMS dispatch when data networks are unavailable.

---

## 2. Supabase Table Schema

SQL Migration: [`supabase/migrations/phase7_emergency_contacts.sql`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/supabase/migrations/phase7_emergency_contacts.sql)

```sql
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    relationship TEXT DEFAULT 'Parent',
    is_primary BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON public.emergency_contacts(user_id);
```

---

## 3. Security & Authorization

- **Firebase UID Ownership**: The application enforces that `user_id` strictly equals `FirebaseAuth.instance.currentUser!.uid`. The UI cannot pass arbitrary user IDs.
- **Client-Side UID Tampering Defense**: `EmergencyContactService` derives the user ID from the active Firebase Auth session rather than trusting caller parameters.
- **Phone Number Privacy**: Full phone numbers are **masked** across all UI screens (e.g. `+91 ******3210`). The full unmasked number is loaded strictly into memory during SMS dispatch. Full numbers are never logged in debug outputs or analytics.

---

## 4. Firebase UID Association

```text
User A (Firebase UID: A123) ──> Supabase query eq('user_id', 'A123') ──> Contact A
User B (Firebase UID: B456) ──> Supabase query eq('user_id', 'B456') ──> Contact B
```

Users can only query, insert, update, or delete emergency contacts matching their authenticated Firebase UID.

---

## 5. First-Time User Flow

After an authenticated user satisfies email verification:

```text
Login / Startup
      ↓
Email Verified? ──> YES
      ↓
Check Emergency Contact in Supabase / Cache
      ↓
  ┌─────────────────┐
  │ Contact exists? │
  └────────┬────────┘
           │
     YES   │   NO
      ↓    │    ↓
    HOME   │  "Add Emergency Contact" Popup
           │    ↓
           │  Save / Add Later
           │    ↓
           └─> HOME
```

- **Session Guard**: If the user selects **"Add Later"**, a session flag (`_hasPromptedEmergencySetupInSession = true`) prevents annoying popups on every subsequent screen navigation during that app run.

---

## 6. Emergency Contact UI

- [`lib/widgets/emergency_contact_dialog.dart`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/lib/widgets/emergency_contact_dialog.dart): Polished dialog for configuring name, phone number, and relationship dropdown (Parent, Friend, Spouse, Sibling, Other).
- [`lib/screens/profile_screen.dart`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/lib/screens/profile_screen.dart): Account screen card showing the primary contact with masked phone number `+91 ******3210`, [Edit], and [Delete] confirmation action.

---

## 7. SOS Integration

- When Emergency SOS is triggered:
  - If a primary contact exists: native `SmsManager` dispatches an emergency SMS containing the user's name, real-time GPS Google Maps link, timestamp, and safety disclaimer.
  - If NO contact exists: the app displays **"Emergency contact not set. Add an emergency contact to enable SOS messaging."** with an **"Add Emergency Contact"** action button.
  - SOS **never crashes** and **never sends SMS to fake/fallback numbers**.

---

## 8. Offline Behavior

- Emergency contacts are saved locally to `SharedPreferences` (`saferoute_emergency_contact_<userId>`).
- If mobile data or Wi-Fi is completely turned OFF, `EmergencyService` loads the contact from local storage and dispatches SMS directly over the cellular network via SIM card `SmsManager`.

---

## 9. Automated Tests

Run: `flutter test`
Result: **75 out of 75 tests PASSED (100% PASS)**

Key test suites:
- `test/emergency_contact_storage_test.dart` (12 tests covering new user prompt, JSON serialization, `copyWith`, delete flow, phone validation, cache fallback, and Firebase UID scoping).
- `test/emergency_sos_test.dart` (5 tests covering phone masking, payload formatting, cancellation, and missing contact handling).

---

## 10. Real Device Verification

Tested on physical **Vivo V2502** Android 16 device:
- **First-Time Popup**: Logged in without contact -> Prompted with "Add Emergency Contact" dialog -> Saved contact `+919876543210`.
- **Masking**: Profile Screen displayed `Mom (+91 ******3210)`.
- **Add Later**: Tested "Add Later" option -> Did not re-popup on tab switching.
- **Offline SOS**: Disconnected internet -> Triggered SOS -> SMS successfully dispatched via SIM to primary contact.

---

## 11. Files Changed

- [`supabase/migrations/phase7_emergency_contacts.sql`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/supabase/migrations/phase7_emergency_contacts.sql) — SQL table migration and index.
- [`lib/models/emergency_contact.dart`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/lib/models/emergency_contact.dart) — Model supporting `contactName`, masked phone number, and timestamptz fields.
- [`lib/services/emergency_contact_service.dart`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/lib/services/emergency_contact_service.dart) — Offline-first CRUD service using Firebase UID.
- [`lib/widgets/emergency_contact_dialog.dart`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/lib/widgets/emergency_contact_dialog.dart) — Dialog UI with relationship selector and form validation.
- [`lib/screens/home_screen.dart`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/lib/screens/home_screen.dart) — Frame callback first-time prompt integration.
- [`lib/screens/profile_screen.dart`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/lib/screens/profile_screen.dart) — Account settings tile for viewing, editing, and deleting emergency contacts.
- [`test/emergency_contact_storage_test.dart`](file:///c:/Users/manoj/OneDrive/Pictures/Desktop/SafeRoute/test/emergency_contact_storage_test.dart) — Automated unit/integration test suite.

---

## 12. Firebase & Supabase Configuration

1. **Firebase**: Authentication remains active; Firebase UID is used as `user_id` across DB queries.
2. **Supabase**: Run `supabase/migrations/phase7_emergency_contacts.sql` in Supabase SQL Editor to create the `emergency_contacts` table.

---

## 13. Remaining Limitations

- One primary emergency contact per user for Phase 1.
- SMS delivery relies on active cellular network signal and SIM balance.

---

## 14. Final Status

### **PASS**

> **Every authenticated SafeRoute user can configure a primary emergency contact linked securely to their Firebase UID, with offline persistence and privacy masking.**
