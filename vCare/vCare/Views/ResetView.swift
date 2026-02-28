
import SwiftUI

struct CalmMomentView: View {
    var onDismiss: () -> Void
    var onComplete: (Date) -> Void

    @State private var isInhale = true
    @State private var timer: Timer?
    @State private var completedCycles = 0
    @State private var hasCompleted = false

    private let totalCycles = 6
    private let motivationMessage = "You give so much of yourself. Take this moment to keep your heart steady & hopeful."

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.82, green: 0.93, blue: 0.95),
                                        Color(red: 0.85, green: 0.95, blue: 0.88)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 8) {
                            Text("Take a Calm Moment")
                                .font(.title).bold()
                            Text("Follow the guided breathing and jot down how you feel at the end.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        BreathingCircleView()

                        VStack(spacing: 16) {
                            Text(isInhale ? "Breathe in" : "Breathe out")
                                .font(.title2).bold()
                                .animation(.easeInOut, value: isInhale)
                            Text("Hold for four counts, release gently.")
                                .foregroundColor(.secondary)

                            ProgressView(value: progress)
                                .tint(.accentColor)
                                .animation(.easeInOut, value: progress)
                            Text(String(format: "Cycle %d of %d", completedCycles, totalCycles))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Try this")
                                .font(.headline)
                            Label("Count to four on inhale, hold for two, exhale for four.", systemImage: "number.square")
                            Label("Notice one thing you’re grateful for right now.", systemImage: "heart")
                            Label(motivationMessage, systemImage: "sparkles")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        Button(action: completeSession) {
                            HStack {
                                Spacer()
                                if hasCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(hasCompleted ? "Session Logged" : "Finish Session")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding()
                            .background(hasCompleted ? Color.green.opacity(0.8) : Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .disabled(hasCompleted || completedCycles < 3)
                        .opacity(hasCompleted || completedCycles >= 3 ? 1 : 0.6)
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismissSheet)
                }
            }
        }
        .onAppear { startBreathing() }
        .onDisappear { stopBreathing() }
    }

    private var progress: Double {
        guard totalCycles > 0 else { return 0 }
        return Double(completedCycles) / Double(totalCycles)
    }

    private func startBreathing() {
        stopBreathing()
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                isInhale.toggle()
            }
            if !isInhale {
                completedCycles = min(completedCycles + 1, totalCycles)
                if completedCycles == totalCycles {
                    completeSession()
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        timer?.tolerance = 0.2
    }

    private func stopBreathing() {
        timer?.invalidate()
        timer = nil
    }

    private func completeSession() {
        guard !hasCompleted else { return }
        hasCompleted = true
        stopBreathing()
        onComplete(Date())
    }

    private func dismissSheet() {
        onDismiss()
    }
}
