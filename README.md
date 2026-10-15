# NextMeet 💓
### *The Intimate Digital Sanctuary for Couples*

![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend%20%26%20Realtime-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)

---

## 🌹 Overview

**NextMeet** is a private, dedicated digital space designed for couples—especially those navigating long distances. Built with romantic warmth, gentle tactile micro-interactions, and real-time synchronization, NextMeet bridges physical distance and keeps two hearts connected throughout the day.

---

## ✨ Core Features

### 💓 1. Real-Time Sanctuary & Presence
- **Live Heart Sync:** Simultaneous long-press interaction causing shared biometric vibration pulses across both phones.
- **Intimate Micro-Touches:** Send tactile "Miss You", "Warm Hug", and "Gentle Touch" notifications with ambient screen glows.
- **Battery & State Sync:** Always know if your partner is low on battery, charging, or available.
- **Timezone & Distance Matrix:** Visual dual clocks with live distance calculation (km/miles) and flight time estimates.

### 📸 2. Shared Memories (WebP Optimized)
- **Romantic Timeline:** Collaborative photo album documenting your milestones, reunions, and dates.
- **Hardware-Accelerated WebP Compression:** Photos are compressed on-device (~60–80 KB per picture) prior to upload, providing stunning 1200px visual intimacy while reducing storage usage by 95% (allowing over 15,000 photos on free tier).
- **Interactive Map:** Visualize every memory pinned on a shared interactive globe.

### 🔐 3. Private Space & Secret Vault
- **Love Letters:** Digital handwritten letters with scheduled delivery dates (openable only on special anniversaries).
- **Voice Whispers:** High-fidelity private audio notes.
- **Secret Photo Vault:** Encrypted, PIN-protected personal photo albums with biometric (FaceID/Fingerprint) unlock.
- **Dual-Approval PIN Reset:** Prevents accidental lockouts through a secure partner-verified OTP handshake.

### 📅 4. Couple Planner & Countdown
- **Next Meetup Countdown:** High-contrast, romantic countdown timer to your next physical reunion.
- **Shared Calendar:** Schedule upcoming movie nights, calls, visits, and anniversaries.
- **Bucket List & Date Discovery:** Curated date ideas and collaborative goal tracking.
- **Love Streaks:** Daily check-ins, streak shields, and milestone achievement badges.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── constants.dart            # Design tokens, color palette, Supabase credentials
│   ├── theme.dart                # Typography (Google Fonts), WCAG AA contrast rules
│   ├── models/                   # Immutable models (RelationshipModel, MemoryModel, MilestoneModel)
│   └── services/
│       ├── cloud_relationship_service.dart # Realtime sync & PostgreSQL data layer
│       ├── image_compression_service.dart  # Hardware-accelerated WebP converter
│       ├── notification_service.dart       # Push notification handlers
│       └── vibration_service.dart          # Rich tactile haptic engine
├── features/
│   ├── auth/                     # Login, Registration, Password recovery
│   ├── home/                     # Sanctuary Tab, Shared Map, Memories, Calendar, Planner
│   ├── onboarding/               # Frictionless 6-digit invite code pairing & splash flow
│   ├── private_space/            # Secret Vault, Love Letters, Voice Whispers, Rituals
│   └── profile/                  # Account management, haptic tuning, NextMeet+ tier
└── widgets/                      # Reusable GlassCard, LoveConstellation, PrimaryButton
```

- **Frontend:** Flutter 3.41+ / Dart 3.11+
- **Backend & Realtime:** Supabase (`supabase_flutter`)
  - **Database:** PostgreSQL with Row Level Security (RLS)
  - **Auth:** GoTrue (Scrypt password verification + Google Sign-In)
  - **Storage:** Public and authenticated WebP media buckets
  - **Realtime:** Low-latency WebSocket replication
- **Image Pipeline:** `flutter_image_compress` (WebP lossy quality 75)
- **Haptics:** Multi-pattern physical feedback via `HapticFeedback`

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.10.8`)
- Android Studio / Xcode
- A Supabase Project (Mumbai `ap-south-1` recommended for lowest latency in Asia)

### 1. Clone the Repository
```bash
git clone https://github.com/aditya21030/NextMeet.git
cd NextMeet
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Supabase Credentials
Ensure your Supabase project credentials are set in `lib/core/constants.dart`:
```dart
class SupabaseConfig {
  static const String url = 'https://your-project-ref.supabase.co';
  static const String anonKey = 'your-anon-publishable-key';
}
```

### 4. Database Setup
Execute the SQL schema in `supabase_schema.sql` inside your Supabase **SQL Editor** to create the necessary tables, indexes, storage buckets, and realtime publications.

### 5. Run the Application
```bash
flutter run
```

---

## 🛡️ Quality Guidelines

This repository follows strict code quality directives:
* **Zero Defect Tolerance:** All contributions must pass `flutter analyze` with **0 errors and 0 warnings**.
* **Memory Leak Guard:** All `StreamSubscription`, `Timer`, `ScrollController`, and `AnimationController` instances must be cleanly disposed in `dispose()`.
* **Async Safety:** No `setState()` or `Navigator` calls across asynchronous gaps without an `if (!mounted) return;` guard.
* **Build Restriction:** APK builds consume intensive CPU and are restricted from automated CI runs without explicit manual dispatch.

---

## 📄 License
Copyright © 2026 YousFul Studio. All rights reserved. Private and confidential.
