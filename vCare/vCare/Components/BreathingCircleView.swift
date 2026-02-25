//
//  BreathingCircleView.swift
//  vCare
//

import SwiftUI

struct BreathingCircleView: View {
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 220, height: 220)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 6)
            )
            .scaleEffect(animate ? 1.05 : 0.95)
            .shadow(color: Color.black.opacity(0.3), radius: 30, y: 20)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animate)
            .onAppear {
                animate = true
            }
    }
}
