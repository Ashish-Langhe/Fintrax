//
//  SettingsSupport.swift
//  Fintrax
//

import SwiftUI
import UIKit

struct SettingsBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                Circle()
                    .fill(AppDesignSystem.Colors.primary.opacity(0.12))
                    .frame(width: 210, height: 210)
                    .blur(radius: 28)
                    .offset(x: -76, y: drift ? 18 : -18)

                Circle()
                    .fill(AppDesignSystem.Colors.warning.opacity(0.12))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)
                    .offset(x: size.width - 106, y: size.height * 0.58)

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 82, weight: .semibold))
                    .foregroundStyle(AppDesignSystem.Colors.primary.opacity(0.055))
                    .rotationEffect(.degrees(drift ? -8 : 5))
                    .offset(x: size.width * 0.64, y: 60)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 76, weight: .semibold))
                    .foregroundStyle(AppDesignSystem.Colors.success.opacity(0.06))
                    .rotationEffect(.degrees(drift ? 7 : -6))
                    .offset(x: size.width * 0.08, y: size.height * 0.7)
            }

            SettingsTexture()
                .opacity(0.42)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5.4).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

struct SettingsTexture: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 18
            for x in stride(from: 0, through: size.width, by: step) {
                for y in stride(from: 0, through: size.height, by: step) {
                    let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.primary.opacity(0.045)))
                }
            }
        }
    }
}

struct AppInfo {
    let version: String
    let build: String
    let bundleIdentifier: String
    let iOSVersion: String
    let deviceModel: String

    static var current: AppInfo {
        let dictionary = Bundle.main.infoDictionary
        return AppInfo(
            version: dictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            build: dictionary?["CFBundleVersion"] as? String ?? "1",
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "Unknown",
            iOSVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            deviceModel: UIDevice.current.model
        )
    }

    static func formattedBundleSize() async -> String {
        await Task.detached(priority: .utility) {
            let bytes = folderSize(at: Bundle.main.bundleURL)
            return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
        }.value
    }

    private static func folderSize(at url: URL) -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) else {
                continue
            }
            total += UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return total
    }
}

extension ThemeOption {
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }
}

extension AppLanguage {
    var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .marathi: return "मराठी"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        }
    }
}

extension View {
    func settingsPanel(accent: Color) -> some View {
        self
            .fintraxSurface(cornerRadius: AppDesignSystem.CornerRadius.xxl, accent: accent)
    }
}
