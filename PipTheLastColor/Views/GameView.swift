//
//  GameView.swift
//  Pip: The Last Color
//

import SwiftUI
import SpriteKit

struct GameView: View {
    
    enum Screen {
        case start
        case playing
        case gameOver
    }
    
    @State private var currentScreen: Screen = .start
    @State private var finalScore = 0
    @State private var bestScore: Int = UserDefaults.standard.integer(forKey: "bestScore")
    
    @State private var scene: GameScene?
    
    var body: some View {
        ZStack {
            // Dark base background (visible during transitions)
            Color(red: 0.07, green: 0.07, blue: 0.08)
                .ignoresSafeArea()
            
            switch currentScreen {
            case .start:
                StartView(onPlay: startGame)
                
            case .playing:
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                
            case .gameOver:
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }
                
                GameOverView(
                    score: finalScore,
                    bestScore: bestScore,
                    onTryAgain: restartGame
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentScreen)
    }
    
    // MARK: - Flow
    
    private func startGame() {
        let gameScene = GameScene()
        gameScene.scaleMode = .resizeFill
        gameScene.onGameOver = handleGameOver
        scene = gameScene
        currentScreen = .playing
    }
    
    private func handleGameOver(_ score: Int) {
        finalScore = score
        
        // Update best score
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(score, forKey: "bestScore")
        }
        
        withAnimation(.easeIn(duration: 0.3)) {
            currentScreen = .gameOver
        }
    }
    
    private func restartGame() {
        scene?.restartGame()
        scene?.onGameOver = handleGameOver
        
        withAnimation(.easeOut(duration: 0.2)) {
            currentScreen = .playing
        }
    }
}

// Make Screen conform to Equatable for animation
extension GameView.Screen: Equatable {}

#Preview {
    GameView()
}
