//
//  StartView.swift
//  Pip: The Last Color
//

import SwiftUI

struct StartView: View {
    let onPlay: () -> Void
    
    @State private var titleOpacity = 0.0
    @State private var buttonOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    Text("Pip")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.82, blue: 0.28),
                                    Color(red: 1.0, green: 0.95, blue: 0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("THE LAST COLOR")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .opacity(titleOpacity)
                
                Spacer()
                
                // Play button
                Button(action: onPlay) {
                    Text("PLAY")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(.white)
                        )
                }
                .opacity(buttonOpacity)
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                buttonOpacity = 1.0
            }
        }
    }
}

#Preview {
    StartView(onPlay: {})
}
