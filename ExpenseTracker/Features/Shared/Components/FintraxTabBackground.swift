//
//  FintraxTabBackground.swift
//  Fintrax
//
//  Fintrax documentation: Provides the shared animated background used by tab screens.
//

import SwiftUI

struct FintraxTabBackground: View {
    enum Style {
        case dashboard
        case expenses
        case analytics
        case budget
        case settings

        fileprivate var symbols: [BackgroundSymbol] {
            switch self {
            case .dashboard:
                return [
                    BackgroundSymbol(name: "rectangle.grid.2x2.fill", size: 78, tint: AppDesignSystem.Colors.primary, opacity: 0.08, x: 0.62, y: 0.08),
                    BackgroundSymbol(name: "chart.line.uptrend.xyaxis", size: 72, tint: AppDesignSystem.Colors.success, opacity: 0.12, x: 0.06, y: 0.58),
                    BackgroundSymbol(name: "indianrupeesign.circle.fill", size: 94, tint: AppDesignSystem.Colors.warning, opacity: 0.12, x: 0.66, y: 0.74),
                    BackgroundSymbol(name: "wallet.pass.fill", size: 64, tint: AppDesignSystem.Colors.info, opacity: 0.10, x: 0.08, y: 0.22)
                ]
            case .expenses:
                return [
                    BackgroundSymbol(name: "creditcard.fill", size: 78, tint: AppDesignSystem.Colors.primary, opacity: 0.09, x: 0.62, y: 0.08),
                    BackgroundSymbol(name: "list.bullet.rectangle.fill", size: 70, tint: AppDesignSystem.Colors.info, opacity: 0.10, x: 0.07, y: 0.58),
                    BackgroundSymbol(name: "indianrupeesign.circle.fill", size: 94, tint: AppDesignSystem.Colors.warning, opacity: 0.12, x: 0.66, y: 0.74),
                    BackgroundSymbol(name: "tag.fill", size: 62, tint: AppDesignSystem.Colors.success, opacity: 0.10, x: 0.08, y: 0.22)
                ]
            case .analytics:
                return [
                    BackgroundSymbol(name: "chart.pie.fill", size: 82, tint: AppDesignSystem.Colors.primary, opacity: 0.09, x: 0.62, y: 0.08),
                    BackgroundSymbol(name: "chart.line.uptrend.xyaxis", size: 74, tint: AppDesignSystem.Colors.success, opacity: 0.12, x: 0.06, y: 0.58),
                    BackgroundSymbol(name: "waveform.path.ecg.rectangle.fill", size: 70, tint: AppDesignSystem.Colors.info, opacity: 0.10, x: 0.66, y: 0.74),
                    BackgroundSymbol(name: "percent", size: 64, tint: AppDesignSystem.Colors.warning, opacity: 0.11, x: 0.08, y: 0.22)
                ]
            case .budget:
                return [
                    BackgroundSymbol(name: "target", size: 82, tint: AppDesignSystem.Colors.primary, opacity: 0.09, x: 0.62, y: 0.08),
                    BackgroundSymbol(name: "gauge.with.dots.needle.67percent", size: 72, tint: AppDesignSystem.Colors.warning, opacity: 0.12, x: 0.06, y: 0.58),
                    BackgroundSymbol(name: "wallet.pass.fill", size: 92, tint: AppDesignSystem.Colors.success, opacity: 0.11, x: 0.66, y: 0.74),
                    BackgroundSymbol(name: "checkmark.shield.fill", size: 64, tint: AppDesignSystem.Colors.info, opacity: 0.10, x: 0.08, y: 0.22)
                ]
            case .settings:
                return [
                    BackgroundSymbol(name: "slider.horizontal.3", size: 78, tint: AppDesignSystem.Colors.primary, opacity: 0.09, x: 0.62, y: 0.08),
                    BackgroundSymbol(name: "lock.shield.fill", size: 76, tint: AppDesignSystem.Colors.success, opacity: 0.10, x: 0.06, y: 0.58),
                    BackgroundSymbol(name: "gearshape.2.fill", size: 90, tint: AppDesignSystem.Colors.warning, opacity: 0.10, x: 0.66, y: 0.74),
                    BackgroundSymbol(name: "paintpalette.fill", size: 62, tint: AppDesignSystem.Colors.info, opacity: 0.10, x: 0.08, y: 0.22)
                ]
            }
        }
    }

    let style: Style
    @State private var drift = false

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                ForEach(Array(style.symbols.enumerated()), id: \.offset) { index, symbol in
                    Image(systemName: symbol.name)
                        .font(.system(size: symbol.size, weight: .medium))
                        .foregroundStyle(symbol.tint.opacity(symbol.opacity))
                        .rotationEffect(.degrees(rotation(for: index)))
                        .offset(
                            x: size.width * symbol.x,
                            y: symbol.offsetY(in: size, drift: drift, index: index)
                        )
                        .accessibilityHidden(true)
                }

                Circle()
                    .stroke(AppDesignSystem.Colors.info.opacity(0.14), lineWidth: 18)
                    .frame(width: 210, height: 210)
                    .offset(x: drift ? -62 : -84, y: 86)

                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(AppDesignSystem.Colors.primary.opacity(0.08), lineWidth: 14)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(drift ? 18 : 9))
                    .offset(x: size.width - 96, y: size.height * 0.18)

                Circle()
                    .stroke(AppDesignSystem.Colors.success.opacity(0.10), lineWidth: 12)
                    .frame(width: 154, height: 154)
                    .offset(x: size.width - 52, y: size.height * 0.52)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
        }
    }

    private func rotation(for index: Int) -> Double {
        let base: [Double] = [-9, 9, 6, -8]
        let alternate: [Double] = [7, -7, -4, 5]
        return drift ? base[index % base.count] : alternate[index % alternate.count]
    }
}

private struct BackgroundSymbol {
    let name: String
    let size: CGFloat
    let tint: Color
    let opacity: Double
    let x: CGFloat
    let y: CGFloat

    func offsetY(in size: CGSize, drift: Bool, index: Int) -> CGFloat {
        let driftAmount: CGFloat = index.isMultiple(of: 2) ? 28 : -18
        return size.height * y + (drift ? driftAmount : 0)
    }
}
