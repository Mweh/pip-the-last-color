//
//  GameOverView.swift
//  Pip: The Last Color
//

import SwiftUI

struct GameOverView: View {
    let score: Int
    let bestScore: Int
    let onTryAgain: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Text("THE COLOR FADES")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                
                // Current score
                VStack(spacing: 6) {
                    Text("COLOR RESTORED")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.4))
                    
                    Text("\(score)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                // Best score
                VStack(spacing: 4) {
                    Text("BEST")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.35))
                    
                    Text("\(bestScore)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.82, blue: 0.28),
                                    Color(red: 1.0, green: 0.95, blue: 0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Button(action: onTryAgain) {
                    Text("TRY AGAIN")
                        .font(.system(size: 15, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(.white)
                        )
                }
                .padding(.top, 4)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    GameOverView(score: 42, bestScore: 128, onTryAgain: {})
}
