# vCare

vCare is a calm, supportive companion designed for caregivers and families managing daily medication routines.
Caring for someone — whether it’s a parent, grandparent, or child — often means tracking medications, watching mood changes, and trying to notice patterns before problems grow. vCare brings those responsibilities into one clear, gentle space.
Instead of overwhelming dashboards, vCare focuses on what matters today:
What needs to be taken
What was missed
How the person is feeling
Whether trends show stability or concern
The goal is simple: reduce stress, increase consistency, and give caregivers quiet confidence.

vCare is a calm, supportive iOS companion designed to help caregivers manage daily medication routines with clarity and confidence.
Caring for someone — whether it’s a parent, grandparent, child, or even yourself — often means remembering schedules, watching for mood changes, and trying to notice patterns before they become problems. That responsibility can feel heavy.
vCare was built to reduce that burden.


## Product Overview
- Daily care check-ins capture mood, energy, notes, and whether medication was taken through `DailyCheckInCardView` and `HomeViewModel`.
- Medication schedules generate day-of logs, countdowns, and reminders managed by `MedicationViewModel` and rendered across the Medications tab.
- Insight cards surface rolling analytics, adherence trends, and alert flags powered by `InsightsViewModel` plus the Charts framework.
- Calm Moment provides a guided breathing sheet with completion tracking tied to the Home dashboard.
- Optional Family Care Portal sharing lets owners export encrypted snapshots for caregivers when `AppFeatures.familyPortalEnabled` is true.

## Tech Stack
- SwiftUI with an MVVM presentation layer.
- Core Data via `PersistenceController` for entries, schedules, and logs.
- Combine for refresh hooks and timer publishers.
- UserNotifications for interactive reminders plus deep link routing.
- ActivityKit Live Activities for the next dose countdown (iOS 16.1+).
- CryptoKit, Base64URL helpers, and QR codes for secure portal payloads.
- Charts, SF Symbols, and UIKit haptics for polish across cards and controls.

## App Surfaces

### Home
- `HomeView` presents a hero medication status card, streak counters, and quick actions.
- Daily check-ins expand for mood sliders, notes, and medication confirmation with haptic feedback through `HomeViewModel`.
- Calm session totals and last-run timestamps are stored in `@AppStorage` so the Reset card remains in sync.
- Medication snapshots summarize morning through night adherence using the `MedicationTime` helpers defined in `PersistenceController`.

### Medications
- `MedicationsView` groups logs by time of day, supports inline actions for taking, skipping, or undoing a dose, and highlights the next dose with urgency badges.
- Toolbar buttons open `AddMedicationView` for CRUD workflows and `ManageSchedulesView` for editing or deleting schedules without leaving the tab.
- `MedicationViewModel` generates daily `MedicationLogEntity` rows, auto-marks overdue doses, schedules notifications, reacts to deep link events, and manages countdown timers that keep the overview card current.

### Insights
- `InsightsView` lets users pick 7, 14, or 30 day windows via `RangePickerView`.
- `InsightsViewModel` aggregates `CareEntry` and `MedicationLog` data into trend lines, adherence gauges, variance stats, missing check-in counts, and summary bullets.
- Dedicated cards (`MoodTrendCardView`, `EnergyTrendCardView`, `AlertsCardView`, `SummaryCardView`, etc.) combine Charts with custom copy to explain the data.

### Calm Moment
- `CalmMomentView` replaces the legacy reset tab with a gradient breathing exercise that tracks completion cycles, offers supportive tips, and writes timestamps for future insight work.

### Settings and Portal
- When sharing is enabled, `SettingsView` surfaces `PortalShareView` and `PortalJoinView` so owners can generate encrypted QR tokens and caregivers can import them.
- `PortalStatusBannerView` keeps portal users aware that the app is in read-only caregiver mode, and `SettingsPortalSectionView` provides exit actions.
- `AppState` centralizes portal snapshot data, selected tab state, and highlighted medication log IDs for consistent behavior across tabs.

## Architecture Notes
- Views bind to dedicated view models located in `vCare/ViewModels`. Each model performs Core Data queries, handles transforms into lightweight structs (`CareEntry`, `MedicationSchedule`, `MedicationLog`), and exposes derived metrics for SwiftUI to render.
- Global UI state and feature toggles reside in `AppState` and `AppFeatures`. `AppState` is also responsible for reading and persisting portal snapshots via `PortalPersistence`.
- Services such as `NotificationManager`, `NextDoseLiveActivityManager`, and portal helpers are isolated under `vCare/` to keep views declarative.

### Project Structure
```
vCare/
├─ vCareApp.swift / ContentView.swift
├─ AppState.swift / AppFeatures.swift
├─ PersistenceController.swift
├─ Models/
├─ ViewModels/
├─ Views/
├─ Components/
├─ CarePortal/
├─ LiveActivities/
├─ Utilities/
├─ NotificationManager.swift
├─ Assets.xcassets
├─ vCare.xcdatamodeld
├─ vCareTests/
└─ vCareUITests/
```

## Data and Persistence
- Core Data entities: `CareEntryEntity`, `MedicationEntity`, `MedicationScheduleEntity`, and `MedicationLogEntity` capture journaling plus schedule data.
- Model mirrors wrap each entity with convenient initializers and `apply` helpers to keep Core Data out of views.
- `MedicationTime` enumerates morning through night buckets so Home and Medications screens can summarize status by part of day.
- `PersistenceController.preview` seeds demo records for SwiftUI previews and experimentation without running the full app.

## Notifications and Live Activities
- `NotificationManager` registers interactive categories, requests permission, schedules primary reminders, missed follow ups, nightly summaries, and snoozes. Notification responses post `medicationAction` and `medicationDeepLink` events so the Medications tab can highlight the relevant log.
- `NextDoseLiveActivityManager` mirrors the upcoming dose countdown on the Lock Screen and Dynamic Island when ActivityKit is available. It gracefully no-ops on older OS versions and updates status as logs change.

## Family Care Portal
- `CarePortalManager` builds read-only snapshots for a requested day range, encrypts them with AES.GCM through `CarePortalCrypto`, and wraps the payload into a share token or QR code via `QRCodeGenerator`.
- Caregivers import tokens with `PortalJoinView`, which decrypts the payload and persists it via `PortalPersistence` and `KeychainStore`. `AppState` then flips to `AppRole.caregiverPortal`, showing read-only banners and portal specific cards.
- Sharing related UI is feature flagged. Set `AppFeatures.familyPortalEnabled = true` to expose the Settings section, portal banners, and caregiver-only layouts. Call `PortalPersistence.shared.clearSnapshot()` when switching between roles during development.

## Getting Started
1. **Requirements**: Xcode 15 or later plus an iOS 17 simulator or device. ActivityKit and Live Activities require iOS 16.1+ hardware for full validation.
2. **Open the project**: `cd vCare` then run `xed .` or open `vCare.xcodeproj` directly.
3. **Run the app**: Select the `vCare` scheme and build for a simulator or device. Allow notification permissions the first time the Medications tab appears.
4. **Seed data**: Use the existing UI to add medications and log check-ins. SwiftUI previews use `PersistenceController.preview` if you need mock data without running the app.
5. **Enable optional features**: Toggle values in `AppFeatures` before building. Clean stored portal data with `PortalPersistence.shared.clearSnapshot()` when switching between owner and caregiver roles.
6. **Test Live Activities**: Deploy to a physical device with ActivityKit enabled. The manager no-ops automatically on unsupported platforms.

## Development Workflow
- `vCareTests` and `vCareUITests` include the default Xcode scaffolding. Expand them with view model tests or UI flows as the feature set grows.
- Repository specific notes live in `vCare/vCare/DEVELOPMENT_NOTES.md`, which captures recent UX changes and follow up ideas.
- Notifications are triggered from `MedicationViewModel`, so call `updateStatusesOnAppear()` from the Medications tab to keep countdowns aligned with actual Core Data state during development.
