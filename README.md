# SafeRoute AI - Smart Walking Navigation (Phase 1 & Phase 2)

> **Disclaimer:** Phase 1 & Phase 2 provide pedestrian walking navigation and community hazard reporting functionality. AI safety scoring, Gemini safety intelligence, and AI route ranking will be introduced in subsequent phases.

---

## 1. Overview

**SafeRoute AI** is a modern, premium pedestrian navigation mobile application built for Android using **Flutter**, **OpenStreetMap (OSM)**, and **Supabase**. 

- **Phase 1**: Centering on Nagpur (Maharashtra, India), device GPS location permissions, destination search (Nominatim), OSRM walking routes, route stats, and navigation preview.
- **Phase 2**: Real backend integration via **Supabase**, community hazard reporting, GPS auto-capture, optional description & photo upload to Supabase Storage, interactive map hazard markers with custom icons, category filter bar, and detailed report bottom sheets.

---

## 2. Technology Stack

- **Framework**: Flutter (Dart 3.x)
- **Map Engine**: OpenStreetMap tiles via `flutter_map`
- **Geocoding Service**: OpenStreetMap Nominatim (`https://nominatim.openstreetmap.org`)
- **Routing Engine**: OSRM Public Foot Routing API (`https://router.project-osrm.org`)
- **Backend & Database**: Supabase (PostgreSQL with optional PostGIS)
- **Storage**: Supabase Storage bucket (`hazard-reports`)
- **Photo Upload**: `image_picker`
- **Location & GPS**: `geolocator` with native Android location permissions
- **Typography**: Inter via `google_fonts`
- **Design Tokens**: Custom emerald green (`#059669`), dark charcoal (`#0F172A`), soft white background (`#F8FAFC`), spacing, radius, and elevation tokens.

---

## 3. Phase 2 Supabase Setup Guide

### 1. Create a Supabase Project
1. Go to [https://supabase.com](https://supabase.com) and create a new project.
2. Note down your **Project URL** (`SUPABASE_URL`) and **Anon/Public API Key** (`SUPABASE_ANON_KEY`).

### 2. Execute SQL Schema
1. Open the **SQL Editor** in your Supabase Dashboard.
2. Copy and paste the contents of `supabase/schema.sql`.
3. Click **Run** to create the `reports` table, indexes, PostGIS spatial features, RLS policies, and `hazard-reports` storage bucket.

### 3. Run the App with Supabase Credentials
Pass your credentials when launching the Flutter application via `--dart-define`:

```bash
flutter run -d 10BF5Z2TJE002CR --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

If credentials are not provided at runtime, the application runs gracefully in fallback mode without crashing.

---

## 4. Project Architecture

```text
lib/
├── main.dart                      # App entry point & Supabase initialization
├── config/
│   └── supabase_config.dart       # Supabase URL & Anon Key environment reader
├── screens/
│   ├── splash_screen.dart          # Splash screen with smooth transitions
│   ├── home_screen.dart            # Primary map with floating search, hazard markers & filters
│   └── navigation_screen.dart      # Navigation preview screen
├── widgets/
│   ├── hazard_marker.dart          # Custom map pins for community reported hazards
│   ├── hazard_filter.dart          # Horizontal filter bar (Show All, Lighting, Damage, etc.)
│   ├── report_form.dart            # Bottom sheet for creating & submitting hazard reports
│   ├── report_details_sheet.dart   # Bottom sheet displaying hazard info & disclaimer
│   ├── search_bar_widget.dart      # Floating search bar with debounced search
│   ├── location_button.dart        # Floating GPS location button
│   ├── route_info_sheet.dart       # Route stats & Start Navigation sheet
│   └── error_banner.dart           # Floating error banner
├── services/
│   ├── supabase_service.dart       # Supabase initialization & anonymous auth manager
│   ├── report_service.dart         # Fetching nearby reports & inserting new hazard reports
│   ├── storage_service.dart        # Supabase Storage photo upload helper
│   ├── location_service.dart       # Device GPS location provider
│   ├── geocoding_service.dart      # OpenStreetMap Nominatim search service
│   └── routing_service.dart        # OSRM foot routing service
├── models/
│   ├── hazard_report.dart          # Community hazard report model with 10 categories
│   ├── destination.dart            # Destination place model
│   └── route_model.dart            # Walking route geometry and stats model
├── theme/
│   ├── app_theme.dart              # Material 3 light theme configuration
│   ├── app_colors.dart             # Palette tokens (Emerald primary, Charcoal, Surface)
│   ├── app_typography.dart         # Inter typography hierarchy
│   └── app_spacing.dart            # Spacing & radius tokens
└── utils/
    └── constants.dart              # Nagpur coordinates, API URLs, constants
```

---

## 5. How to Run

### Steps

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run Static Code Analysis**:
   ```bash
   flutter analyze
   ```

3. **Run Unit & Model Tests**:
   ```bash
   flutter test
   ```

4. **Launch Application on Android Device**:
   ```bash
   flutter run -d 10BF5Z2TJE002CR
   ```

---

## 6. Roadmap & Future Architecture

- **Phase 1** (Done): Walking Navigation & Map Foundation.
- **Phase 2** (Done): Supabase Backend & Community Hazard Reporting.
- **Phase 3**: Safety Scoring Engine (Hazard weightings, lighting scores, sidewalk condition weights).
- **Phase 4**: Gemini AI Integration (Conversational safety queries, route reasoning, contextual summaries).
- **Phase 5**: Real-Time Alerts & Rerouting.
- **Phase 6**: Turn-by-turn Voice Guidance & Haptic Feedback.
