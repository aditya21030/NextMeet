# NextMeet AI Agent Operating Guidelines & Architecture
**Project:** NextMeet (Intimate Couple Digital Space) • **Version:** `1.0.39+86`  
**Stack:** Flutter 3.10+ / Dart 3 • Firebase (Auth, Firestore, Cloud Messaging, Cloud Storage)  
**Configuration File:** `agents.md`

---

## 1. Project Mission & Core Principles

NextMeet is a dedicated, private, and romantic digital space for couples—especially those navigating long distances. Every line of code, interaction, and visual component must embody:
* **Romantic Warmth & Delight:** Interactions must feel intimate, tactile, and heartfelt (e.g. gentle haptic pulses, floating heart particles), never cold, robotic, or transactional.
* **Instantaneous Pairing:** The journey from downloading the app to connecting hearts must happen in under 30 seconds with minimal typing.
* **Rock-Solid Stability:** Zero crashes, zero startup freezes, and zero unhandled stream errors. Couples rely on NextMeet for continuous connection.
* **Strict Privacy & Security:** Couple data, love letters, and shared photos must remain encrypted, private, and accessible only to the paired partners.

---

## 2. Universal Directives & Guardrails (Immutable Rules)

All AI agents interacting with this repository MUST strictly adhere to the following rules:

> [!CAUTION]
> **RULE 1: STRICT BUILD BAN**  
> **NEVER execute `flutter build apk` or any APK build command.** APK builds consume immense CPU, trigger quota locks, and are strictly forbidden unless the user explicitly requests one with the exact words *"build apk"*.

> [!IMPORTANT]
> **RULE 2: ZERO-ANALYSIS DEFECT TOLERANCE**  
> Every change must maintain **0 errors and 0 warnings** under `flutter analyze`. If an edit introduces any lint or type error, it must be resolved immediately before concluding the task.

> [!IMPORTANT]
> **RULE 3: MEMORY LEAK PREVENTION**  
> Every `StreamSubscription`, `Timer`, `ScrollController`, `TextEditingController`, and `AnimationController` created in a `StatefulWidget` **MUST** be explicitly cancelled or disposed inside `dispose()`.

> [!IMPORTANT]
> **RULE 4: ASYNC SAFETY & LIFECYCLE GUARDS**  
> Never call `setState()`, `Navigator.push()`, or `ScaffoldMessenger` across an `await` gap without checking `if (!mounted) return;`. All network/Firestore queries must specify timeouts (`.timeout(const Duration(seconds: ...))`) to prevent infinite UI freezes.

> [!NOTE]
> **RULE 5: PRESERVE DOCUMENTATION INTEGRITY**  
> Maintain existing docstrings, rationale comments, and license headers. Never wipe out comments unrelated to your changes.

---

## 3. Specialized Agent Personas & Domain Ownership

```mermaid
graph TD
    subgraph Agents [NextMeet Agent Roster]
        A1["🛡️ QAGuardian<br><i>(Code Health, Lints, Memory Safety)</i>"]
        A2["⚡ BackendSpecialist<br><i>(Firestore, Security Rules, Transactions, FCM)</i>"]
        A3["🎨 UIDesigner<br><i>(Animations, Ergonomics, WCAG, Haptics)</i>"]
        A4["🚀 FunnelEngineer<br><i>(Onboarding, FTUE, Clipboard, Pairing)</i>"]
    end

    A4 -->|Frictionless Pairing| A2
    A2 -->|Reactive State| A3
    A3 -->|Widget Tree Integrity| A1
```

### Agent 1: `BackendSpecialist` (Cloud Architecture & Real-Time Sync)
* **Domain Ownership:**
  * [`lib/core/services/cloud_relationship_service.dart`](file:///d:/Flutter/NextMeet/lib/core/services/cloud_relationship_service.dart)
  * [`lib/core/services/firebase_auth_service.dart`](file:///d:/Flutter/NextMeet/lib/core/services/firebase_auth_service.dart)
  * [`lib/core/services/notification_service.dart`](file:///d:/Flutter/NextMeet/lib/core/services/notification_service.dart)
  * [`firestore.rules`](file:///d:/Flutter/NextMeet/firestore.rules)
  * [`functions/`](file:///d:/Flutter/NextMeet/functions/)
* **Core Responsibilities:**
  * Enforce atomic, safe Firestore transactions. Keep non-critical metrics (such as global counters) outside atomic couple pairing blocks to avoid permission-denied rollbacks.
  * Guarantee deterministic real-time query streams (e.g. prioritizing `status == 'active'` in `streamRelationship()` over orphaned waiting documents).
  * Maintain clean Firestore Security Rules that strictly validate UID ownership while allowing seamless partner pairing.
  * Optimize Firestore read/write quotas by throttling battery, GPS, and touch updates.

---

### Agent 2: `UIDesigner` (Visual Craftsmanship, Ergonomics & Micro-Interactions)
* **Domain Ownership:**
  * [`lib/core/constants.dart`](file:///d:/Flutter/NextMeet/lib/core/constants.dart) & [`lib/core/theme.dart`](file:///d:/Flutter/NextMeet/lib/core/theme.dart)
  * [`lib/features/home/home_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/home/home_screen.dart)
  * [`lib/features/home/chat_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/home/chat_screen.dart)
  * [`lib/features/home/main_navigation_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/home/main_navigation_screen.dart)
  * [`lib/features/private_space/`](file:///d:/Flutter/NextMeet/lib/features/private_space/)
* **Core Responsibilities:**
  * Eliminate the `SnackBar` anti-pattern for intimate couple actions ("Miss You", "Hug", "Touch"). Replace them with delightful floating particle bursts and ambient screen glows.
  * Enforce WCAG AA accessibility standards: ensure all secondary text achieves at least a 4.5:1 contrast ratio against `#F8FAFC`. Avoid low-opacity text (`alpha: 0.4`).
  * Ensure one-handed thumb reachability: position critical daily actions (like Chat) within the comfortable lower half of tall smartphone screens.
  * Gesture disambiguation: ensure long-press actions (like "Heart Sync") are immune to accidental triggers during vertical scrolling.

---

### Agent 3: `FunnelEngineer` (Onboarding, FTUE & Conversion Optimization)
* **Domain Ownership:**
  * [`lib/features/onboarding/splash_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/onboarding/splash_screen.dart)
  * [`lib/features/auth/login_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/auth/login_screen.dart)
  * [`lib/features/auth/create_account_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/auth/create_account_screen.dart)
  * [`lib/features/onboarding/setup_couple_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/onboarding/setup_couple_screen.dart)
  * [`lib/features/onboarding/create_couple_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/onboarding/create_couple_screen.dart)
  * [`lib/features/onboarding/join_couple_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/onboarding/join_couple_screen.dart)
  * [`lib/features/onboarding/connection_success_screen.dart`](file:///d:/Flutter/NextMeet/lib/features/onboarding/connection_success_screen.dart)
* **Core Responsibilities:**
  * Solve the 90% couple drop-off problem by eliminating every possible barrier to pairing.
  * Implement instant clipboard auto-detection on app launch so copied 6-digit codes automatically guide invited partners to pair in 1 tap.
  * Eradicate "Create vs Join" choice paralysis: clearly distinguish "I have a code" from "I'm starting a journey" on `SetupCoupleScreen`.
  * Ensure reactive real-time feedback: attach a live snapshot listener on `CreateCoupleScreen` so Partner A's phone instantly celebrates and transitions when Partner B joins.

---

### Agent 4: `QAGuardian` (Reliability, Performance & Quality Gatekeeper)
* **Domain Ownership:**
  * Global codebase linting and static analysis (`flutter analyze`).
  * Timeout management on splash and auth transitions.
  * Performance profiling: ensuring animations render at 60fps and `IndexedStack` maintains state without unneeded widget rebuilds.
* **Core Responsibilities:**
  * Verify that all asynchronous futures are wrapped in guarded `try/catch` blocks.
  * Confirm that un-paired and offline states present clean, informative prompts instead of permanent spinning loaders.
  * Audit PRs and code modifications before merging to prevent regressions.

---

## 4. Inter-Agent Execution Workflow (Phase & Step Cadence)

When implementing items from [`plan.md`](file:///d:/Flutter/NextMeet/plan.md), agents execute sequentially following this protocol:

```
[ Step 1: Remove ] ──► [ Step 2: Fix Backend ] ──► [ Step 3: Polish UI/UX ] ──► [ Step 4: Verify ]
     (UIDesigner)          (BackendSpecialist)          (Funnel & UI)             (QAGuardian)
```

1. **Step Identification:** Identify the target Phase and Step from `plan.md`.
2. **Pre-Flight Health Check:** Run `flutter analyze` to ensure the codebase starts in a clean state.
3. **Surgical Implementation:** Apply focused, single-block replacements using `replace_file_content` or `write_to_file`. Avoid sweeping multi-file rewrites in a single step.
4. **Post-Flight Verification:** Run `flutter analyze` immediately after edits.
5. **Plan Synchronization:** Update the status checkbox in `plan.md` to record completion.

## 5. Cross-File Reference Architecture

To maintain a clean separation of concerns across the repository:
* **Master Implementation Plan:** [`plan.md`](file:///d:/Flutter/NextMeet/plan.md) — Strict Phase & Step-wise technical execution roadmap with checklists and acceptance criteria.
* **Design System & UI/UX Specs:** [`design.md`](file:///d:/Flutter/NextMeet/design.md) — Single source of truth for color tokens, WCAG AA contrast rules, typography scale, micro-interactions, haptics, and component library.
* **Agent Guidelines:** [`agents.md`](file:///d:/Flutter/NextMeet/agents.md) — Autonomous agent operational roles, universal directives, domain ownership, and handoff protocols.

