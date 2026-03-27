import SwiftUI

struct OnboardingWelcomeStep: View {
    @State private var visibleFeature = 0

    private let features: [(icon: String, title: String, body: String, color: Color)] = [
        ("timer",            "INTERVAL TIMER",   "HIIT, strength, yoga, runs — fully customizable sets, rests, and exercises.", .outrunYellow),
        ("lock.iphone",      "LIVE ACTIVITY",    "Your countdown lives on the lock screen and Dynamic Island so your phone stays in your pocket.", .outrunCyan),
        ("applewatch",       "APPLE WATCH",      "Play, pause, and skip from your wrist while your phone tracks the session.", .outrunGreen),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // App name
            VStack(spacing: 6) {
                Text("LAZER DRAGON")
                    .font(.outrunFuture(36))
                    .foregroundColor(.outrunYellow)
                Text("WORKOUT EXPERIENCE")
                    .font(.outrunFuture(14))
                    .foregroundColor(.outrunCyan)
                    .kerning(4)
            }

            Spacer().frame(height: 40)

            // Feature cards
            TabView(selection: $visibleFeature) {
                ForEach(features.indices, id: \.self) { i in
                    featureCard(features[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 220)
        }
    }

    private func featureCard(_ feature: (icon: String, title: String, body: String, color: Color)) -> some View {
        VStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 36))
                .foregroundColor(feature.color)

            Text(feature.title)
                .font(.outrunFuture(18))
                .foregroundColor(.white)

            Text(feature.body)
                .font(.outrunFuture(13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color.outrunSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(feature.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 32)
    }
}
