# Development Notes

## 2024-04-05

### What I Did
- Reviewed the current SwiftUI architecture, view models, and UI screens (Home, Medications, Insights, Reset, Settings) to understand the overall experience.
- Evaluated the Calm/Reset experience and the family portal feature flag status to identify UX and product inconsistencies.

### Mistakes / Issues Found
- The Calm screen uses a drastically different neon gradient and typography treatment than the rest of the app, which breaks the brand language and feels like a different product.
- Calm mode is isolated in its own tab with no contextual entry points (e.g., no supportive copy that links it to check-ins or medication stress), so it feels like filler instead of a purposeful tool.
- Family portal UI is still surfaced throughout the app even though QR code sharing is disabled, which confuses users and wastes layout space.

### Improvements & Next Steps
- Align Calm mode visuals with the core palette (soft pastels used on Home) and embed it as a sheet/section triggered from stressful states instead of a permanent tab.
- Introduce multi-step calming guidance (timer, breathing, journaling) and track completion stats to tie the feature back into care insights.
- Hide portal-specific banners, share/join CTAs, and caregiver-only copy while QR sharing is paused; add a single settings notice instead.
- Consider richer onboarding or explainer copy on Home/Medications to help new users understand streaks, adherence, and insights.

## 2024-04-06

### What I Did
- Removed the standalone Calm/Reset tab and rerouted the “Calm Moment” action through the Home dashboard so it feels like part of the daily flow.
- Built a new `CalmMomentView` sheet with pastel gradients, guided breathing cycles, actionable suggestions, and completion handling that logs sessions locally.
- Added persistent session tracking via `@AppStorage`, surfaced a Stress Reset card on Home, and refreshed Quick Actions copy.

### Mistakes / Issues Found
- The previous breathing screen kept running timers even when dismissed and never tracked completion metrics.
- Quick Actions still referenced the removed Reset tab; without a rewrite the button would have become a no-op.

### Improvements & Next Steps
- Hook calm session completions into Insights so users can see if stress resets correlate with mood/energy trends.
- Consider letting users jot a short reflection at the end of a calm session to reinforce the habit and provide richer data.
- Expand onboarding to highlight the new Stress Reset card and explain how session counts feed into care insights.

## 2024-04-07

### What I Did
- Added a dedicated “Manage” sheet to the Medications tab so users can review, edit, or delete schedules without cluttering the main adherence dashboard.
- Redesigned `ManageSchedulesView` into a gradient-backed layout with elevated cards, summary tags, reminder/status rows, and primary/secondary buttons so it matches the Home aesthetic.
- Wired toolbar controls and modal sequencing so selecting Edit from the manager opens `AddMedicationView` pre-filled for that schedule via a dedicated `scheduleToEdit` sheet, and introduced a confirmation alert before deletion.

### Mistakes / Issues Found
- Editing support was already partially wired (`editingSchedule`) but unused, meaning there was no way to correct or remove a schedule once added.
- Without dismissing the manager before presenting the editor, sheets would stack awkwardly; resolved by sequencing the closures.
- Immediate deletions felt risky without confirmation and the old list styling felt out of place compared to the rest of the app.
- The previous implementation reused a boolean sheet with a nullable schedule, causing the first edit session to open blank because the initial `@State` values never reinitialized—fixed by separating “add new” and “edit existing” sheets.

## 2024-04-08

### What I Did
- Overhauled the Medications tab UI: added a hero overview header summarizing taken/missed/upcoming doses with adherence %, plus an inline next-dose highlight card tied to the existing countdown logic.
- Replaced the disclosure list with pastel section cards per time block (Morning/Afternoon/Evening) and built a richer `MedicationRowView` featuring icons, countdowns, and inline action buttons for taking or skipping doses.
- Added a thoughtful empty state prompting users to add their first schedule and kept caregiver portal layouts untouched for clarity.

### Mistakes / Issues Found
- The prior layout buried key info inside a DisclosureGroup and small rows, making it hard to scan; the new structure surfaces the most important numbers immediately.
- Row actions previously relied on swipe gestures only; now they have visible buttons and better feedback.

### Improvements & Next Steps
- Consider animating section completion (confetti or check animation) when the last dose in a block is taken.
- Feed calm session insights into this screen (e.g., highlight stress resets before evening meds) to encourage adherence.
- Continue iterating on contrast/density by offering a compact mode for caregivers who prefer even simpler lists.
- Skipping a dose now immediately recolors the row and shows a pause icon so the state change is obvious.
- Added an "Undo" path for skipped doses so accidental taps are recoverable without digging into Manage.
- Unified medication row backgrounds to a neutral card, using badges/icons for status so the list stays professional while still conveying state.

### Improvements & Next Steps
- Consider surfacing a subtle “Manage” card below the adherence summary for quicker access, gated behind the same sheet to avoid clutter.
- Add confirmation prompts or undo for deletions, especially once sharing or syncing is enabled.
- Eventually fold schedule metadata (color tags, notes) into the manager row for richer context.
