import SwiftUI

struct GaugeRing: View {
    let value: Double // 0.0 - 1.0
    let label: String
    let color: Color
    var lineWidth: CGFloat = 5
    var size: CGFloat = 64
    var showLabel: Bool = true
    var fontSize: CGFloat = 13
    var animateOnTap: Bool = false
    @Environment(ThemeManager.self) private var theme

    @State private var animatedValue: Double = 0
    @State private var spinAngle: Double = -90

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(theme.border, lineWidth: lineWidth)

            // Value ring
            Circle()
                .trim(from: 0, to: CGFloat(min(max(animatedValue, 0), 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(spinAngle))

            // Label
            if showLabel {
                Text(label)
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedValue = newValue
            }
        }
        .onTapGesture {
            guard animateOnTap else { return }
            // Spin the ring 360° and reset value
            let currentVal = animatedValue
            withAnimation(.easeIn(duration: 0.3)) {
                animatedValue = 0
            }
            withAnimation(.easeInOut(duration: 0.6)) {
                spinAngle += 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedValue = currentVal
                }
            }
        }
    }
}

struct GaugeRingSmall: View {
    let value: Double
    let color: Color

    var body: some View {
        GaugeRing(
            value: value,
            label: "\(Int(value * 100))%",
            color: color,
            lineWidth: 3,
            size: 36,
            fontSize: 9
        )
    }
}
