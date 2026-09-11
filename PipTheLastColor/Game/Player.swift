//
//  Player.swift
//  Pip: The Last Color
//

import SpriteKit

final class Player: SKNode {
    
    // MARK: - Properties
    
    let radius: CGFloat
    private let bodyNode: SKShapeNode
    private let coreNode: SKShapeNode
    
    // MARK: - Initializer
    
    init(radius: CGFloat = 16) {
        self.radius = radius
        self.bodyNode = SKShapeNode(circleOfRadius: radius)
        self.coreNode = SKShapeNode(circleOfRadius: radius * 0.45)
        super.init()
        
        setupVisuals()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupVisuals() {
        // Outer glowing body representing the spark of color
        bodyNode.fillColor = SKColor(red: 1.0, green: 0.82, blue: 0.28, alpha: 0.9) // Bright warm amber/spark
        bodyNode.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
        bodyNode.lineWidth = 2.0
        addChild(bodyNode)
        
        // Inner luminous core
        coreNode.fillColor = SKColor.white
        coreNode.strokeColor = SKColor.clear
        addChild(coreNode)
        
        // Subtle breathing/sparkle animation to feel alive
        let scaleUp = SKAction.scale(to: 1.08, duration: 0.6)
        let scaleDown = SKAction.scale(to: 0.94, duration: 0.6)
        scaleUp.timingMode = .easeInEaseOut
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        bodyNode.run(SKAction.repeatForever(pulse))
    }
    
    // MARK: - Movement & Boundaries
    
    func clamp(within rect: CGRect) {
        position.x = max(rect.minX + radius, min(rect.maxX - radius, position.x))
        position.y = max(rect.minY + radius, min(rect.maxY - radius, position.y))
    }
}
