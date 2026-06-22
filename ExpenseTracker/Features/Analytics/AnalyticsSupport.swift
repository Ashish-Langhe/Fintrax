//
//  AnalyticsSupport.swift
//  Fintrax
//

import SwiftUI

struct AnalyticsBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.primary.opacity(0.10),
                    AppDesignSystem.Colors.info.opacity(0.08),
                    AppDesignSystem.Colors.warning.opacity(0.06)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()
        }
    }
}

extension View {
    func analyticsPanel(accent: Color) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.thinMaterial)

                LinearGradient(
                    colors: [accent.opacity(0.10), Color.clear, AppDesignSystem.Colors.elevatedSurface.opacity(0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: accent.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}
