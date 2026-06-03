//
//  AppAnimations.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

// MARK: - App Animations

struct AppAnimations {
    // MARK: - Durations
    
    struct Durations {
        static let instant = 0.0
        static let fast = 0.15
        static let normal = 0.25
        static let slow = 0.35
        static let slower = 0.5
        static let verySlow = 0.8
    }
    
    // MARK: - Animation Curves
    
    struct Curves {
        static let easeOut = Animation.easeOut(duration: Durations.normal)
        static let easeIn = Animation.easeIn(duration: Durations.normal)
        static let easeInOut = Animation.easeInOut(duration: Durations.normal)
        
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let springBouncy = Animation.spring(response: 0.6, dampingFraction: 0.6)
        static let springGentle = Animation.spring(response: 0.5, dampingFraction: 0.9)
        
        static let quickPop = Animation.easeOut(duration: Durations.fast).delay(0.05)
        static let slideIn = Animation.easeOut(duration: Durations.slow).delay(0.1)
        static let fadeIn = Animation.easeOut(duration: Durations.normal).delay(0.2)
        
        static let chartAnimation = Animation.easeInOut(duration: Durations.slower)
        static let buttonPress = Animation.easeInOut(duration: Durations.fast)
        static let cardHover = Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Animation Presets
    
    struct Presets {
        // Button Animations
        static let buttonPress = Animation.easeInOut(duration: Durations.fast)
        static let buttonHover = Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let buttonRelease = Animation.easeOut(duration: Durations.fast).delay(0.1)
        
        // Card Animations
        static let cardEntry = Animation.easeOut(duration: Durations.slow).delay(0.1)
        static let cardExit = Animation.easeIn(duration: Durations.normal)
        static let cardHover = Animation.spring(response: 0.4, dampingFraction: 0.7)
        
        // List Animations
        static let listEntry = Animation.easeOut(duration: Durations.normal).delay(0.05)
        static let listRefresh = Animation.easeInOut(duration: Durations.slower)
        
        // Modal Animations
        static let modalPresent = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let modalDismiss = Animation.easeOut(duration: Durations.normal)
        
        // Chart Animations
        static let chartUpdate = Animation.easeInOut(duration: Durations.slower)
        static let chartEntry = Animation.easeOut(duration: Durations.slower).delay(0.2)
        
        // Tab Animations
        static let tabSwitch = Animation.easeInOut(duration: Durations.normal)
        static let tabIndicator = Animation.spring(response: 0.4, dampingFraction: 0.9)
        
        // Navigation Animations
        static let navigationPush = Animation.easeInOut(duration: Durations.slow)
        static let navigationPop = Animation.easeInOut(duration: Durations.normal)
        
        // Status Animations
        static let successPulse = Animation.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)
        static let errorShake = Animation.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)
        static let loadingPulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    }
}

// MARK: - Interactive Animation Modifiers

struct InteractiveButton: ViewModifier {
    @State private var isPressed = false
    @State private var isHovered = false
    
    let scaleEffect: CGFloat
    let animation: Animation
    
    init(scaleEffect: CGFloat = 0.95, animation: Animation = AppAnimations.Presets.buttonPress) {
        self.scaleEffect = scaleEffect
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleEffect : (isHovered ? 1.05 : 1.0))
            .animation(animation, value: isPressed)
            .animation(animation, value: isHovered)
            .onTapGesture {
                withAnimation(animation) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(animation) {
                        isPressed = false
                    }
                }
            }
            .onHover { hovering in
                withAnimation(animation) {
                    isHovered = hovering
                }
            }
    }
}

struct CardHoverEffect: ViewModifier {
    @State private var isHovered = false
    
    let shadowRadius: CGFloat
    let liftAmount: CGFloat
    
    init(shadowRadius: CGFloat = 12, liftAmount: CGFloat = 4) {
        self.shadowRadius = shadowRadius
        self.liftAmount = liftAmount
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.08),
                radius: isHovered ? shadowRadius : 8,
                x: 0,
                y: isHovered ? liftAmount : 4
            )
            .animation(AppAnimations.Curves.cardHover, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct StaggeredEntry<Content: View>: View {
    let content: Content
    let delayStep: Double
    
    @State private var isVisible = false
    
    init(delayStep: Double = 0.1, @ViewBuilder content: () -> Content) {
        self.delayStep = delayStep
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                .easeOut(duration: AppAnimations.Durations.normal)
                .delay(delayStep),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

struct LoadingPulse: ViewModifier {
    @State private var isPulsing = false
    
    let minScale: CGFloat
    let maxScale: CGFloat
    
    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.0) {
        self.minScale = minScale
        self.maxScale = maxScale
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(
                AppAnimations.Presets.loadingPulse,
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
            .onDisappear {
                isPulsing = false
            }
    }
}

// MARK: - View Extensions

extension View {
    func interactiveButton(scaleEffect: CGFloat = 0.95) -> some View {
        self.modifier(InteractiveButton(scaleEffect: scaleEffect))
    }
    
    func cardHover(shadowRadius: CGFloat = 12, liftAmount: CGFloat = 4) -> some View {
        self.modifier(CardHoverEffect(shadowRadius: shadowRadius, liftAmount: liftAmount))
    }
    
    func staggeredEntry(delay: Double = 0.1) -> some View {
        StaggeredEntry(delayStep: delay) { self }
    }
    
    func loadingPulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.0) -> some View {
        self.modifier(LoadingPulse(minScale: minScale, maxScale: maxScale))
    }
    
    func animate(if condition: Bool, animation: Animation = AppAnimations.Curves.easeOut) -> some View {
        self.animation(animation, value: condition)
    }
    
    func smoothTransition(_ transition: AnyTransition = .opacity) -> some View {
        self.transition(transition.combined(with: .scale(scale: 0.9)))
    }
}
