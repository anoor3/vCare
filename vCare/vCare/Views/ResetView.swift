//
//  ResetView.swift
//  vCare
//

import SwiftUI

struct ResetView: View {
    @State private var isInhale = true
    @State private var timer: Timer?

    private let motivationMessage = "You give so much of yourself. Take this moment to keep your heart steady & hopeful."

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.85), Color.green.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Calm Mode")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)

                BreathingCircleView()

                VStack(spacing: 12) {
                    Text(isInhale ? "Breathe in" : "Breathe out")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .animation(.easeInOut, value: isInhale)
                    Text("Hold for four, release gently.")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.85))
                    Text(motivationMessage)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
            }
            .padding(32)
        }
        .onAppear {
            startBreathing()
        }
        .onDisappear {
            stopBreathing()
        }
    }

    private func startBreathing() {
        stopBreathing()
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                isInhale.toggle()
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        timer?.tolerance = 0.2
    }

    private func stopBreathing() {
        timer?.invalidate()
        timer = nil
    }
}
