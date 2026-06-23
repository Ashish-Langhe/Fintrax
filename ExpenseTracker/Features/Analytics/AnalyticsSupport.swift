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
        fintraxSurface(cornerRadius: 22, accent: accent)
    }
}
