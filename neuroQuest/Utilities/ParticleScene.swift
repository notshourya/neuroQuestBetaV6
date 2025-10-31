//
//  ParticleScene.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//


import SpriteKit
import SwiftUI

class ParticleScene: SKScene {
    private var particleColors: [SKColor]
    
    init(colors: [Color]) {
        self.particleColors = colors.map { SKColor($0) }
        super.init(size: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        size = view.bounds.size
        scaleMode = .resizeFill
        
        createFloatingParticles()
    }
    
    private func createFloatingParticles() {
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = particleColors.randomElement() ?? .white
            particle.strokeColor = .clear
            
            particle.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            particle.zPosition = 0
            particle.glowWidth = 1.5
            
            addChild(particle)
            animateFloatingParticle(particle)
        }
    }
    
    private func animateFloatingParticle(_ particle: SKShapeNode) {
        let randomDuration = TimeInterval.random(in: 4...7)
        let randomX = CGFloat.random(in: -80...80)
        let randomY = CGFloat.random(in: -80...80)
        
        let move = SKAction.moveBy(x: randomX, y: randomY, duration: randomDuration)
        let fade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: randomDuration / 2),
            SKAction.fadeAlpha(to: 0.6, duration: randomDuration / 2)
        ])
        
        let group = SKAction.group([move, fade])
        let repeatAction = SKAction.repeatForever(SKAction.sequence([
            group,
            group.reversed()
        ]))
        
        particle.run(repeatAction)
    }
}
