//
//  BiometricAuthService.swift
//  Fintrax
//
//  Fintrax documentation: Wraps LocalAuthentication for Face ID and Touch ID app unlock.
//

import Foundation
import LocalAuthentication

struct BiometricAuthService {
    enum BiometricKind {
        case none
        case touchID
        case faceID
        case opticID

        var titleKey: String {
            switch self {
            case .none:
                "biometric.kind.none"
            case .touchID:
                "biometric.kind.touchID"
            case .faceID:
                "biometric.kind.faceID"
            case .opticID:
                "biometric.kind.opticID"
            }
        }

        var iconName: String {
            switch self {
            case .none:
                "lock.slash.fill"
            case .touchID:
                "touchid"
            case .faceID:
                "faceid"
            case .opticID:
                "opticid"
            }
        }
    }

    struct Availability {
        let isAvailable: Bool
        let kind: BiometricKind
        let error: Error?
    }

    func availability() -> Availability {
        let context = LAContext()
        var error: NSError?
        let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        return Availability(
            isAvailable: isAvailable,
            kind: kind(for: context.biometryType),
            error: error
        )
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = L10n.string("Cancel")

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }

    private func kind(for type: LABiometryType) -> BiometricKind {
        switch type {
        case .none:
            .none
        case .touchID:
            .touchID
        case .faceID:
            .faceID
        case .opticID:
            .opticID
        @unknown default:
            .none
        }
    }
}
