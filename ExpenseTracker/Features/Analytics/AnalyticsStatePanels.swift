//
//  AnalyticsStatePanels.swift
//  Fintrax
//

import SwiftUI

struct AnalyticsLoadingPanel: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading analytics...")
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .analyticsPanel(accent: AppDesignSystem.Colors.info)
    }
}

struct AnalyticsErrorPanel: View {
    let error: Error

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(AppDesignSystem.Colors.error)
            Text("Could not load analytics")
                .font(AppDesignSystem.Typography.headline)
            Text(error.localizedDescription)
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .analyticsPanel(accent: AppDesignSystem.Colors.error)
    }
}

struct AnalyticsEmptyPanel: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
            Text("No analytics yet")
                .font(AppDesignSystem.Typography.headline)
            Text("Add expenses to unlock category breakdowns and monthly trends.")
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .analyticsPanel(accent: AppDesignSystem.Colors.primary)
    }
}
