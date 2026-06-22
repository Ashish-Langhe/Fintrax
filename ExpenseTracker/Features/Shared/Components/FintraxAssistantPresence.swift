//
//  FintraxAssistantPresence.swift
//  Fintrax
//
//  Fintrax documentation: Provides the animated assistant presence used across insight-heavy screens.
//

import SwiftUI

struct FintraxAssistantPresenceModifier: ViewModifier {
    let entrance: FintraxAssistantEntrance
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                FintraxAssistantLauncher(entrance: entrance) {
                    isPresented = true
                }
                .padding(.trailing, 18)
                .padding(.bottom, 82)
            }
            .sheet(isPresented: $isPresented) {
                FintraxAssistantSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
    }
}

extension View {
    func fintraxAssistantPresence(entrance: FintraxAssistantEntrance = .subtle) -> some View {
        modifier(FintraxAssistantPresenceModifier(entrance: entrance))
    }
}

enum FintraxAssistantEntrance {
    case dashboardArrival
    case subtle
}

