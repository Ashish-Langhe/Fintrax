//
//  AssistantBlinkRhythm.swift
//  Fintrax
//

import SwiftUI

enum AssistantBlinkRhythm {
    static func nextPause() -> UInt64 {
        let seconds = Double.random(in: 3.6...7.4)
        return UInt64(seconds * 1_000_000_000)
    }

    @MainActor
    static func performBlink(_ setBlinking: @escaping (Bool) -> Void) async {
        await closeAndOpen(setBlinking, closedFor: 0.105)

        if Int.random(in: 1...7) == 1 {
            try? await Task.sleep(nanoseconds: 120_000_000)
            await closeAndOpen(setBlinking, closedFor: 0.085)
        }
    }

    @MainActor
    private static func closeAndOpen(_ setBlinking: @escaping (Bool) -> Void, closedFor seconds: Double) async {
        withAnimation(.easeInOut(duration: 0.075)) {
            setBlinking(true)
        }

        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))

        withAnimation(.easeInOut(duration: 0.11)) {
            setBlinking(false)
        }
    }
}
