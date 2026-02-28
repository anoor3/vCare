# vCare

An iOS companion for caregivers that combines daily mood check-ins, strict medication adherence tracking, and digestible wellbeing insights in one SwiftUI experience.

## Overview
- Built with SwiftUI, MVVM, Core Data, ActivityKit, and UserNotifications.
- Focused on at-home care routines: capture mood & energy, manage scheduled medications, and surface adherence trends.
- Includes a guided “Calm” mode breathing exercise plus an opt-in Family Care Portal for sharing encrypted snapshots.

## Feature Highlights
- **Daily care check-ins** – `HomeView` pairs a hero medication status card, streak tracking, Quick Actions, and the `DailyCheckInCardView` so users can log mood (1–5), energy (0–100), notes, and whether meds were taken.
- **Medication schedules & reminders** – `MedicationViewModel` generates day-of `MedicationLog` entries from `MedicationSchedule` definitions, handles status transitions (upcoming/taken/missed/skipped), and drives `UNUserNotificationCenter` reminders with actionable buttons.
- **Insightful analytics** – `InsightsViewModel` aggregates `CareEntry` and medication log data over 7/14/30 day windows, computing mood trends, energy variance, adherence deltas, and insight flags visualized by dedicated card views.
- **Calm mode** – `ResetView` + `BreathingCircleView` animate a haptic-backed 4-4 breathing exercise to quickly reset during stressful care moments.
- **Family portal (feature flagged)** – When `AppFeatures.familyPortalEnabled == true`, the Settings tab unlocks share & join flows that encrypt Core Data snapshots via `CarePortalManager`, persist them with `PortalPersistence`, and hydrate caregiver dashboards through `AppState`.
- **Live Activities + Deep Links** – `NextDoseLiveActivityManager` publishes upcoming doses to the Lock Screen/Dynamic Island (iOS 16.1+), while `NotificationManager` deep-links back to the Medications tab using custom `Notification.Name` events.

## Tab Experiences
- **Home** – Provides greeting, hero medication status, Quick Actions, check-in card, medication snapshot, and lightweight insights. Supports caregiver mode banners when connected to a portal snapshot.
- **Medications** – Shows adherence summary, next dose card with countdown & urgency, actionable schedule rows, and `AddMedicationView` for CRUD workflows (frequency, time slots, reminders, color tags, notes).
- **Insights** – Lets users pick a range, review care status, read alerts, and inspect mood/energy/adherence visualizations before a narrative summary. Falls back to portal-provided analytics when in caregiver mode.
- **Calm (Reset)** – Minimal breathing exercise with gradient backdrop, timed instructions, and haptics.
- **Settings** – Currently hosts family portal sharing/joining UI when the feature flag is enabled; otherwise it communicates that the portal is disabled.

## Architecture Snapshot
- **SwiftUI + MVVM** – `Views` render declarative UI, bind to `ViewModels` that encapsulate Core Data + business logic, and use `@StateObject`/`@ObservedObject` for updates.
- **Global state** – `AppState` (singleton `ObservableObject`) stores the selected tab, caregiver role, and imported portal snapshot, so any view can respond to portal mode.
- **Core Data** – `PersistenceController` configures the stack, preview data, merge policies, and exposes the context through SwiftUI `environment`. Each entity has a strongly-typed `Model` mirror that performs conversion to/from managed objects.
- **Feature toggles** – `AppFeatures` centralizes compile-time switches (right now only `familyPortalEnabled`).
- **Services** – `NotificationManager`, `NextDoseLiveActivityManager`, and the `CarePortal` helpers abstract platform-specific work away from the views.

## Data & Persistence
- Entities (`CareEntryEntity`, `MedicationEntity`, `MedicationScheduleEntity`, `MedicationLogEntity`) model the journaling and medication domain inside `vCare.xcdatamodeld`.
- Models like `CareEntry`, `Medication`, `MedicationSchedule`, and `MedicationLog` keep the UI decoupled from Core Data APIs and encapsulate mapping/validation logic.
- `HomeViewModel` computes statistics such as streaks, weekly averages, missed doses, and micro insights directly from Core Data queries.
- `InsightsViewModel` pulls historical ranges, builds per-day `DayMetric` structs, calculates averages/variance/standard deviation, correlates missed doses with mood dips, and generates user-facing flags.
- `MedicationViewModel` is responsible for generating daily logs, marking statuses, cleaning up changed schedules, and saving edits while also orchestrating notifications and live activities.

## Notifications, Live Activities & Deep Links
- `NotificationManager` requests authorization, defines categories/actions, schedules primary reminders, follow-ups, “daily summary” digests, and handles interactive responses (mark taken / remind later) which post `Notification.Name.medicationAction` or `.medicationDeepLink` events.
- `ContentView` listens for `.medicationDeepLink` and forces the TabView selection back to Medications so the user lands on the relevant log.
- Live Activities (available when ActivityKit exists) mirror the next dose countdown on the Lock Screen and Dynamic Island. `NextDoseLiveActivityManager` starts/updates/ends activities as logs change, and gracefully no-ops on older OS versions.

## Family Care Portal
- **Sharing** – `PortalShareView` invokes `CarePortalManager.generateShareToken`, which builds a `CareShareProfileDTO` snapshot from Core Data, encrypts it with AES.GCM (`CryptoKit`), and renders both a share code and QR code.
- **Joining** – `PortalJoinView` accepts tokens, decrypts them, and stores the snapshot via `PortalPersistence` + `KeychainStore`, flipping `AppState.role` to `.caregiverPortal` so UI swaps to read-only dashboards.
- **Enabling the feature** – Set `AppFeatures.familyPortalEnabled = true` (currently `false` to keep the UI hidden). Verify you add the required “Associated Domains”/custom URL scheme so `vcare://portal?...` tokens resolve correctly.

## Project Structure
```
vCare/
├─ README.md
├─ vCare/
│  ├─ vCareApp.swift / ContentView.swift
│  ├─ AppState.swift / AppFeatures.swift
│  ├─ PersistenceController.swift
│  ├─ Models/
│  │  ├─ CareEntry.swift, Medication*.swift, InsightsMetrics.swift
│  ├─ ViewModels/
│  │  ├─ HomeViewModel.swift, MedicationViewModel.swift, InsightsViewModel.swift
│  ├─ Views/
│  │  ├─ HomeView.swift, MedicationsView.swift, InsightsView.swift,
│  │  │  ResetView.swift, SettingsView.swift + supporting cards/components
│  ├─ Components/ (BreathingCircleView, MoodSelectorView, MedicationCardView, …)
│  ├─ CarePortal/ (AppRole, CarePortalManager, Payload/Crypto helpers, DTOs, persistence)
│  ├─ LiveActivities/ (NextDoseAttributes + manager)
│  ├─ Utilities/ (DateFormatter extensions)
│  ├─ NotificationManager.swift
│  ├─ Assets.xcassets
│  └─ vCare.xcdatamodeld
├─ vCareTests/
│  └─ vCareTests.swift (Swift Testing template)
└─ vCareUITests/
   ├─ vCareUITests.swift
   └─ vCareUITestsLaunchTests.swift
```

### Directory Notes
- `Views/` holds all user-facing screens and reusable cards/banners for each tab.
- `Components/` contains generic, shareable UI widgets (breathing animation, medication cards, mood selector).
- `CarePortal/` encapsulates everything needed for encrypted sharing/joining (DTOs, crypto, persisted snapshots, keychain helpers).
- `LiveActivities/` isolates ActivityKit support so builds on unsupported OS versions still compile.
- `Models/` + `ViewModels/` implement the MVVM layer and are the main touch point for business logic.
- `NotificationManager.swift` & `Utilities/` offer cross-cutting helpers that any view model can import.
- `Tests/` folders host the default Xcode Swift Testing and UI Testing stubs for future automation.

## Getting Started
1. **Requirements** – Xcode 15+, iOS 17 simulator or device (ActivityKit + SwiftData features rely on iOS 16.1+, notifications/live activities need a real device to fully validate).
2. **Open the project** – `cd vCare` (repo root) and either double-click `vCare.xcodeproj` or run `xed .` to launch Xcode.
3. **Select the `vCare` scheme** and build/run on your desired simulator/device.
4. **Seed some data** – Use the preview data provided in `PersistenceController.preview`, or log a few entries/medications via the UI to unlock Insights.
5. **Allow notifications** the first time you open the Medications tab so reminders, deep links, and Live Activities can be scheduled.

## Development Tips
- Toggle family portal availability via `AppFeatures.familyPortalEnabled` and make sure you clean stored snapshots with `PortalPersistence.shared.clearSnapshot()` when switching roles.
- `NotificationManager` is initialized early by `MedicationViewModel`; if you need background notification handling, wire it into `UIApplicationDelegate` lifecycle too.
- When iterating on Live Activities, confirm the device supports ActivityKit and that “Live Activities” capability is enabled in the Signing & Capabilities panel.
- Extend insights by adding new `InsightFlag` cases or summary bullet builders inside `InsightsViewModel`—the card views automatically render them.
- The Swift Testing template in `vCareTests` is empty; add async unit tests around your view model logic (e.g., medication adherence calculations) as the next step.

## Next Steps / Ideas
- Persist Care Alerts in `CarePortalManager.createCareAlertIfNeeded` once cloud sync or push targets are defined.
- Back your medication schedules with HealthKit or Reminders exports for better ecosystem integration.
- Expand Settings with toggles for notification quiet hours, custom reminder sounds, or portal refresh intervals once `AppFeatures` grows beyond the single flag.
