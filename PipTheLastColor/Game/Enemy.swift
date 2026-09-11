//
//  Enemy.swift
//  Pip: The Last Color
//

import SpriteKit

final class Enemy: SKNode {
    
    // MARK: - Properties
    
    let radius: CGFloat
    var moveSpeed: CGFloat
    
    private let bodyNode: SKShapeNode
    private let eyeLeft: SKShapeNode
    private let eyeRight: SKShapeNode
    
    // MARK: - Initializer
    
    init(radius: CGFloat = 14, speed: CGFloat = 60) {
        self.radius = radius
        self.moveSpeed = speed
        self.bodyNode = SKShapeNode(circleOfRadius: radius)
        self.eyeLeft = SKShapeNode(circleOfRadius: radius * 0.2)
        self.eyeRight = SKShapeNode(circleOfRadius: radius * 0.2)
        super.init()
        
        setupVisuals()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupVisuals() {
        // Dark, menacing body
        bodyNode.fillColor = SKColor(red: 0.20, green: 0.12, blue: 0.25, alpha: 1.0)
        bodyNode.strokeColor = SKColor(red: 0.55, green: 0.15, blue: 0.25, alpha: 1.0)
        bodyNode.lineWidth = 2.5
        addChild(bodyNode)
        
        // Glowing red eyes
        let eyeSpacing = radius * 0.35
        let eyeY = radius * 0.15
        
        eyeLeft.fillColor = SKColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 1.0)
        eyeLeft.strokeColor = SKColor.clear
        eyeLeft.position = CGPoint(x: -eyeSpacing, y: eyeY)
        addChild(eyeLeft)
        
        eyeRight.fillColor = SKColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 1.0)
        eyeRight.strokeColor = SKColor.clear
        eyeRight.position = CGPoint(x: eyeSpacing, y: eyeY)
        addChild(eyeRight)
        
        // Subtle menacing pulse
        let grow = SKAction.scale(to: 1.06, duration: 0.4)
        let shrink = SKAction.scale(to: 0.96, duration: 0.4)
        grow.timingMode = .easeInEaseOut
        shrink.timingMode = .easeInEaseOut
        bodyNode.run(SKAction.repeatForever(SKAction.sequence([grow, shrink])))
    }
    
    // MARK: - Movement
    
    /// Move toward a target point at the enemy's speed, scaled by deltaTime.
    func moveToward(_ target: CGPoint, deltaTime: TimeInterval) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 1 else { return }
        
        let step = moveSpeed * CGFloat(deltaTime)
        let ratio = min(step / distance, 1.0)
        
        position.x += dx * ratio
        position.y += dy * ratio
    }
    
    /// Clamp enemy position within the arena bounds.
    func clamp(within rect: CGRect) {
        position.x = max(rect.minX + radius, min(rect.maxX - radius, position.x))
        position.y = max(rect.minY + radius, min(rect.maxY - radius, position.y))
    }
}
