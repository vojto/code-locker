import SwiftUI

/*
 * The small ring that drains as a code runs out of time. Used by AccountRow.
 * Turns red for the last 5 seconds.
 */

struct CountdownRing: View {
    let secondsRemaining: TimeInterval
    let period: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 3)

            Circle()
                .trim(from: 0, to: secondsRemaining / period)
                .stroke(isEndingSoon ? Color.red : Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(isRefilling ? nil : .linear(duration: 1), value: secondsRemaining)
        }
        .frame(width: 20, height: 20)
        .accessibilityLabel("\(Int(secondsRemaining)) seconds left")
    }

    private var isEndingSoon: Bool {
        secondsRemaining <= 5
    }

    private var isRefilling: Bool {
        secondsRemaining > period - 1
    }
}

#Preview {
    HStack(spacing: 16) {
        CountdownRing(secondsRemaining: 25, period: 30)
        CountdownRing(secondsRemaining: 12, period: 30)
        CountdownRing(secondsRemaining: 4, period: 30)
    }
    .padding()
}
