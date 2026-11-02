import SwiftUI

/// Black capsule that drops out of the Dynamic Island with a spring, stays a few seconds and tucks back in.
/// Used for live moments ("3 friends answered"), never for errors.
struct IslandToast: View {
    let users: [AppUser]
    let title: String
    var subtitle: String? = nil
    var onTap: () -> Void = {}

    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                if !users.isEmpty {
                    AvatarStack(users: Array(users.prefix(3)), size: 28, ring: .black)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.ui(15, .semibold))
                        .foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.ui(13))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .lineLimit(1)
                .opacity(expanded ? 1 : 0)
                Spacer(minLength: 0)
                Circle().fill(Color.qLime).frame(width: 8, height: 8)
                    .opacity(expanded ? 1 : 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: expanded ? .infinity : 126)
            .frame(height: expanded ? 60 : 37)
            .background(Capsule(style: .continuous).fill(.black))
            .padding(.horizontal, expanded ? 12 : 0)
        }
        .buttonStyle(.pressable)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([title, subtitle].compactMap { $0 }.joined(separator: ", "))
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.72)) {
                expanded = true
            }
        }
    }
}

extension View {
    /// Shows an `IslandToast` at the top while `isPresented` is true, then hides it after `seconds`.
    func islandToast(isPresented: Binding<Bool>, seconds: Double = 3.5,
                     content: @escaping () -> IslandToast) -> some View {
        overlay(alignment: .top) {
            if isPresented.wrappedValue {
                content()
                    .padding(.top, 11)
                    .ignoresSafeArea(edges: .top)
                    .transition(.asymmetric(insertion: .opacity,
                                            removal: .scale(scale: 0.4, anchor: .top).combined(with: .opacity)))
                    .task {
                        try? await Task.sleep(for: .seconds(seconds))
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { isPresented.wrappedValue = false }
                    }
                    .zIndex(10)
            }
        }
    }
}
