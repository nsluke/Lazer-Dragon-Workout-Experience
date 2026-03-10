import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var visibleFeature = 0

    private let features: [(icon: String, title: String, body: String, color: Color)] = [
        ("timer",            "INTERVAL TIMER",   "HIIT, strength, yoga, runs — fully customizable sets, rests, and exercises.", .outrunYellow),
        ("lock.iphone",      "LIVE ACTIVITY",    "Your countdown lives on the lock screen and Dynamic Island so your phone stays in your pocket.", .outrunCyan),
        ("applewatch",       "APPLE WATCH",      "Play, pause, and skip from your wrist while your phone tracks the session.", .outrunGreen),
    ]

    var body: some View {
        ZStack {
            Color.outrunBlack.ignoresSafeArea()

            // Grid lines — outrun road effect
            gridLines

            VStack(spacing: 0) {
                Spacer()

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

                Spacer()

                // Feature cards
                TabView(selection: $visibleFeature) {
                    ForEach(features.indices, id: \.self) { i in
                        featureCard(features[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 220)

                Spacer()

                // Get started
                Button(action: onComplete) {
                    Text("GET STARTED")
                        .font(.outrunFuture(22))
                        .foregroundColor(.outrunBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.outrunCyan)
                        .cornerRadius(12)
                        .shadow(color: .outrunCyan.opacity(0.4), radius: 16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Feature Card

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

    // MARK: - Grid Lines

    private var gridLines: some View {
        GeometryReader { geo in
            let count = 8
            let spacing = geo.size.width / CGFloat(count)
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    Rectangle()
                        .fill(Color.outrunPurple.opacity(0.15))
                        .frame(width: 1)
                        .offset(x: spacing * CGFloat(i) - geo.size.width / 2)
                }
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(Color.outrunPurple.opacity(0.1))
                        .frame(height: 1)
                        .offset(y: (geo.size.height / 11) * CGFloat(i) - geo.size.height / 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
}
