//
//  StarsBackgroundView.swift
//  Beam
//
//  Created by Rens Verhoeven on 12-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import SpriteKit

class StarsBackgroundView: UIView {
    
    var paused = false {
        didSet {
            self.spriteScene.isPaused = paused
        }
    }
    
    fileprivate var spriteView: SKView = SKView()
    fileprivate var spriteScene: SKScene = SKScene()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupGradient()
        self.setupSpriteKitAnimations()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupGradient()
        self.setupSpriteKitAnimations()
    }
    
    fileprivate func setupSpriteKitAnimations() {
        //Disable the stars on the simulator
        #if (arch(i386) || arch(x86_64))
            print("Stars background disabled as it causes issues on the simulator.")
        #else
        spriteView.allowsTransparency = true
        spriteView.backgroundColor = .clear
        spriteScene.backgroundColor = .clear
        
        spriteView.presentScene(spriteScene, transition: SKTransition())
        addSubview(spriteView)
        
        do {
            try addStars(level: 0)
            try addStars(level: 1)
        } catch {
            print("Error loading stars background: \(error)")
        }
        #endif
    }
    
    private func addStars(level: Int) throws {
        let resourceName = "stars_level_\(level)"
        guard let emitter = SKEmitterNode(fileNamed: resourceName) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCoderReadCorruptError, userInfo: nil)
        }
        emitter.position = CGPoint(x: 0, y: -150)
        spriteScene.addChild(emitter)
        emitter.advanceSimulationTime(400)
    }
    
    fileprivate func setupGradient() {
        let gradientColor = UIColor(red: 0.49, green: 0.36, blue: 0.9, alpha: 0.8)
        self.backgroundColor = gradientColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.spriteScene.size = self.bounds.size
        self.spriteView.frame = self.bounds
    }

}
