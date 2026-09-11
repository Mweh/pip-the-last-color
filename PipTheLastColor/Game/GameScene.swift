//
//  GameScene.swift
//  Pip: The Last Color
//

import SpriteKit
import UIKit

final class GameScene: SKScene {
    
    // MARK: - Configuration
    
    private let gridColumns = 7
    private let gridRows = 11
    
    // MARK: - Difficulty
    
    /// Each entry is the game-time (in seconds) at which a new enemy spawns.
    private let enemySpawnTimes: [TimeInterval] = [2, 40, 70, 105]
    private var nextSpawnIndex = 0
    
    /// Base speed for enemies. Increases over time.
    private let baseEnemySpeed: CGFloat = 60
    /// How much speed increases per second of survival.
    private let speedIncreasePerSecond: CGFloat = 8
    
    // MARK: - Game State
    
    private(set) var gameState: GameState = .playing
    var onGameOver: ((Int) -> Void)?
    
    // MARK: - Nodes
    
    private let gridContainer = SKNode()
    private var tileNodes: [[SKShapeNode]] = []
    private var player: Player?
    private var enemies: [Enemy] = []
    
    // MARK: - Tile State
    
    private var tileStates: [[TileState]] = []
    
    // MARK: - Score
    
    private(set) var score: Int = 0
    
    // MARK: - Arena Layout
    
    private(set) var tileSize: CGFloat = 0
    private(set) var arenaRect: CGRect = .zero
    
    // MARK: - Timing
    
    private var lastUpdateTime: TimeInterval = 0
    private var gameTime: TimeInterval = 0
    
    // MARK: - Touch Tracking
    
    private var previousTouchLocation: CGPoint?
    
    // MARK: - Restoration Colors
    
    private let restorationColors: [SKColor] = [
        SKColor(red: 0.36, green: 0.83, blue: 0.63, alpha: 1.0), // Mint green
        SKColor(red: 0.40, green: 0.73, blue: 0.95, alpha: 1.0), // Sky blue
        SKColor(red: 0.95, green: 0.55, blue: 0.38, alpha: 1.0), // Warm coral
        SKColor(red: 0.76, green: 0.55, blue: 0.95, alpha: 1.0), // Soft purple
        SKColor(red: 0.95, green: 0.82, blue: 0.35, alpha: 1.0), // Sunny yellow
        SKColor(red: 0.95, green: 0.45, blue: 0.62, alpha: 1.0), // Rose pink
        SKColor(red: 0.45, green: 0.88, blue: 0.82, alpha: 1.0), // Teal
    ]
    
    // MARK: - HUD Nodes
    
    private let scoreLabelNode = SKLabelNode()
    private let scoreTitleNode = SKLabelNode()
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        
        if gridContainer.parent == nil {
            addChild(gridContainer)
        }
        
        if size.width > 100 && size.height > 100 {
            configureArena(for: size)
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 100 && size.height > 100 else { return }
        configureArena(for: size)
    }
    
    // MARK: - Update Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else { return }
        
        // Calculate delta time
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Don't process huge time jumps (e.g. after backgrounding)
        guard dt < 1.0 else { return }
        
        gameTime += dt
        
        // Spawn enemies based on difficulty schedule
        while nextSpawnIndex < enemySpawnTimes.count,
              gameTime >= enemySpawnTimes[nextSpawnIndex] {
            spawnEnemy()
            nextSpawnIndex += 1
        }
        
        // Scale all enemy speeds based on survival time
        let currentSpeed = baseEnemySpeed + speedIncreasePerSecond * CGFloat(gameTime)
        for enemy in enemies {
            enemy.moveSpeed = currentSpeed
        }
        
        // Move enemies toward Pip
        guard let pip = player else { return }
        for enemy in enemies {
            enemy.moveToward(pip.position, deltaTime: dt)
            enemy.clamp(within: arenaRect)
            consumeTileUnderEnemy(enemy)
        }
        
        // Check collision
        checkCollisions()
    }
    
    // MARK: - Arena Setup
    
    private func configureArena(for newSize: CGSize) {
        let horizontalMargin: CGFloat = 24
        let topMargin: CGFloat = 120
        let bottomMargin: CGFloat = 60
        
        let availableWidth = newSize.width - (horizontalMargin * 2)
        let availableHeight = newSize.height - topMargin - bottomMargin
        
        let tileWidth = availableWidth / CGFloat(gridColumns)
        let tileHeight = availableHeight / CGFloat(gridRows)
        tileSize = floor(min(tileWidth, tileHeight))
        
        let gridTotalWidth = tileSize * CGFloat(gridColumns)
        let gridTotalHeight = tileSize * CGFloat(gridRows)
        
        let originX = (newSize.width - gridTotalWidth) / 2
        let originY = bottomMargin + (availableHeight - gridTotalHeight) / 2
        arenaRect = CGRect(x: originX, y: originY, width: gridTotalWidth, height: gridTotalHeight)
        
        buildGrid()
        setupScoreHUD(for: newSize)
        setupPlayer()
    }
    
    private func buildGrid() {
        gridContainer.removeAllChildren()
        tileNodes.removeAll()
        
        let needsStateInit = tileStates.isEmpty
        if needsStateInit {
            tileStates = Array(
                repeating: Array(repeating: TileState.faded, count: gridRows),
                count: gridColumns
            )
        }
        
        let arenaBorder = SKShapeNode(rect: arenaRect, cornerRadius: 8)
        arenaBorder.fillColor = SKColor(white: 0.09, alpha: 1.0)
        arenaBorder.strokeColor = SKColor(white: 0.20, alpha: 1.0)
        arenaBorder.lineWidth = 2.0
        arenaBorder.zPosition = 0
        gridContainer.addChild(arenaBorder)
        
        let tilePadding: CGFloat = 2.0
        let innerTileSize = tileSize - (tilePadding * 2)
        
        for col in 0..<gridColumns {
            var colTiles: [SKShapeNode] = []
            for row in 0..<gridRows {
                let tileX = arenaRect.origin.x + (CGFloat(col) * tileSize) + tilePadding
                let tileY = arenaRect.origin.y + (CGFloat(row) * tileSize) + tilePadding
                
                let tileRect = CGRect(x: tileX, y: tileY, width: innerTileSize, height: innerTileSize)
                let tile = SKShapeNode(rect: tileRect, cornerRadius: 4)
                tile.lineWidth = 1.0
                tile.zPosition = 1
                
                if tileStates[col][row] == .restored {
                    applyRestoredAppearance(to: tile, col: col, row: row)
                } else {
                    applyFadedAppearance(to: tile)
                }
                
                gridContainer.addChild(tile)
                colTiles.append(tile)
            }
            tileNodes.append(colTiles)
        }
    }
    
    private func setupScoreHUD(for sceneSize: CGSize) {
        scoreTitleNode.removeFromParent()
        scoreLabelNode.removeFromParent()
        
        let hudY = arenaRect.maxY + 24
        
        scoreTitleNode.text = "COLOR RESTORED"
        scoreTitleNode.fontName = "AvenirNext-DemiBold"
        scoreTitleNode.fontSize = 13
        scoreTitleNode.fontColor = SKColor(white: 0.45, alpha: 1.0)
        scoreTitleNode.position = CGPoint(x: sceneSize.width / 2, y: hudY + 20)
        scoreTitleNode.zPosition = 20
        addChild(scoreTitleNode)
        
        scoreLabelNode.text = "\(score)"
        scoreLabelNode.fontName = "AvenirNext-Bold"
        scoreLabelNode.fontSize = 32
        scoreLabelNode.fontColor = SKColor.white
        scoreLabelNode.position = CGPoint(x: sceneSize.width / 2, y: hudY - 12)
        scoreLabelNode.zPosition = 20
        addChild(scoreLabelNode)
    }
    
    private func setupPlayer() {
        if player == nil {
            let pip = Player(radius: tileSize * 0.32)
            pip.zPosition = 10
            pip.position = CGPoint(x: arenaRect.midX, y: arenaRect.midY)
            addChild(pip)
            player = pip
            
            restoreTileUnderPlayer()
        } else {
            player?.clamp(within: arenaRect)
        }
    }
    
    // MARK: - Enemy Spawning
    
    private func spawnEnemy() {
        let enemyRadius = tileSize * 0.28
        let enemy = Enemy(radius: enemyRadius, speed: 60)
        enemy.zPosition = 9
        
        // Spawn at a random corner of the arena, away from Pip
        let spawnPosition = randomCornerPosition()
        enemy.position = spawnPosition
        
        addChild(enemy)
        enemies.append(enemy)
    }
    
    /// Pick a random corner of the arena for enemy spawning.
    private func randomCornerPosition() -> CGPoint {
        let inset: CGFloat = tileSize
        let corners = [
            CGPoint(x: arenaRect.minX + inset, y: arenaRect.minY + inset),
            CGPoint(x: arenaRect.maxX - inset, y: arenaRect.minY + inset),
            CGPoint(x: arenaRect.minX + inset, y: arenaRect.maxY - inset),
            CGPoint(x: arenaRect.maxX - inset, y: arenaRect.maxY - inset),
        ]
        
        // Prefer corners far from player
        guard let pip = player else { return corners[0] }
        
        let sorted = corners.sorted { a, b in
            let distA = hypot(a.x - pip.position.x, a.y - pip.position.y)
            let distB = hypot(b.x - pip.position.x, b.y - pip.position.y)
            return distA > distB
        }
        
        // Pick from the two farthest corners randomly
        let index = Int.random(in: 0...min(1, sorted.count - 1))
        return sorted[index]
    }
    
    // MARK: - Collision Detection
    
    private func checkCollisions() {
        guard let pip = player else { return }
        
        for enemy in enemies {
            let dx = pip.position.x - enemy.position.x
            let dy = pip.position.y - enemy.position.y
            let distance = sqrt(dx * dx + dy * dy)
            let collisionDistance = pip.radius + enemy.radius
            
            if distance < collisionDistance {
                triggerGameOver()
                return
            }
        }
    }
    
    // MARK: - Game Over
    
    private func triggerGameOver() {
        gameState = .gameOver
        previousTouchLocation = nil
        
        // Heavy haptic feedback for game over
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        // Freeze enemies and player visually
        isPaused = false // Keep scene responsive for restart
        
        onGameOver?(score)
    }
    
    // MARK: - Restart
    
    func restartGame() {
        // Remove enemies
        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()
        
        // Reset tile states
        tileStates = Array(
            repeating: Array(repeating: TileState.faded, count: gridRows),
            count: gridColumns
        )
        
        // Reset score, timing, and difficulty
        score = 0
        scoreLabelNode.text = "0"
        gameTime = 0
        lastUpdateTime = 0
        nextSpawnIndex = 0
        
        // Reset player position
        player?.position = CGPoint(x: arenaRect.midX, y: arenaRect.midY)
        
        // Rebuild grid visually
        buildGrid()
        
        // Restore starting tile
        restoreTileUnderPlayer()
        
        // Resume play
        gameState = .playing
    }
    
    // MARK: - Tile Appearance
    
    private func applyFadedAppearance(to tile: SKShapeNode) {
        tile.fillColor = SKColor(white: 0.13, alpha: 1.0)
        tile.strokeColor = SKColor(white: 0.17, alpha: 1.0)
    }
    
    private func applyRestoredAppearance(to tile: SKShapeNode, col: Int, row: Int) {
        let colorIndex = (col + row) % restorationColors.count
        let color = restorationColors[colorIndex]
        tile.fillColor = color
        tile.strokeColor = color.withAlphaComponent(0.7)
    }
    
    // MARK: - Color Restoration
    
    private func tilePosition(for point: CGPoint) -> TilePosition? {
        let localX = point.x - arenaRect.origin.x
        let localY = point.y - arenaRect.origin.y
        
        let col = Int(localX / tileSize)
        let row = Int(localY / tileSize)
        
        guard col >= 0, col < gridColumns, row >= 0, row < gridRows else { return nil }
        return TilePosition(col: col, row: row)
    }
    
    private func restoreTileUnderPlayer() {
        guard let pip = player,
              let pos = tilePosition(for: pip.position) else { return }
        
        guard tileStates[pos.col][pos.row] == .faded else { return }
        
        tileStates[pos.col][pos.row] = .restored
        score += 1
        
        let tile = tileNodes[pos.col][pos.row]
        let colorIndex = (pos.col + pos.row) % restorationColors.count
        let targetColor = restorationColors[colorIndex]
        
        let scaleUp = SKAction.scale(to: 1.12, duration: 0.08)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.10)
        scaleUp.timingMode = .easeOut
        scaleDown.timingMode = .easeIn
        
        let colorize = SKAction.run { [weak tile] in
            tile?.fillColor = targetColor
            tile?.strokeColor = targetColor.withAlphaComponent(0.7)
        }
        
        tile.run(SKAction.sequence([colorize, scaleUp, scaleDown]))
        
        scoreLabelNode.text = "\(score)"
        
        // Score label pop
        let scoreScaleUp = SKAction.scale(to: 1.2, duration: 0.05)
        let scoreScaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        scoreLabelNode.run(SKAction.sequence([scoreScaleUp, scoreScaleDown]))
        
        // Light haptic tap for satisfying color restore
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func consumeTileUnderEnemy(_ enemy: Enemy) {
        guard let pos = tilePosition(for: enemy.position) else { return }
        guard tileStates[pos.col][pos.row] == .restored else { return }
        
        tileStates[pos.col][pos.row] = .faded
        
        let tile = tileNodes[pos.col][pos.row]
        
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.05)
        let fadeAction = SKAction.run { [weak self, weak tile] in
            guard let self = self, let t = tile else { return }
            self.applyFadedAppearance(to: t)
        }
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.08)
        
        tile.run(SKAction.sequence([scaleDown, fadeAction, scaleUp]))
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        guard let touch = touches.first else { return }
        previousTouchLocation = touch.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        guard let touch = touches.first,
              let prevLocation = previousTouchLocation,
              let pip = player else { return }
        
        let currentLocation = touch.location(in: self)
        let deltaX = currentLocation.x - prevLocation.x
        let deltaY = currentLocation.y - prevLocation.y
        
        pip.position.x += deltaX
        pip.position.y += deltaY
        pip.clamp(within: arenaRect)
        
        previousTouchLocation = currentLocation
        
        restoreTileUnderPlayer()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousTouchLocation = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousTouchLocation = nil
    }
}
