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
            print("Stars background will not work, causing issues on the simulator")
        #else
        self.spriteView.allowsTransparency = true
        self.spriteView.backgroundColor = UIColor.clear
        self.spriteScene.backgroundColor = UIColor.clear
        
        self.spriteView.presentScene(self.spriteScene, transition: SKTransition())
        self.addSubview(self.spriteView)
        
        let starsLevel0Path: String = Bundle.main.path(forResource: "stars_level_0", ofType: "sks")!
            if let stars = NSKeyedUnarchiver.unarchiveObject(withFile: starsLevel0Path) as? SKEmitterNode {
            stars.position = CGPoint(x: 0, y: -150)
            self.spriteScene.addChild(stars)
            stars.advanceSimulationTime(400)
        }
        
        let starsLevel1Path: String = Bundle.main.path(forResource: "stars_level_1", ofType: "sks")!
        if let stars = NSKeyedUnarchiver.unarchiveObject(withFile: starsLevel1Path) as? SKEmitterNode {
            stars.position = CGPoint(x: 0, y: -150)
            self.spriteScene.addChild(stars)
            stars.advanceSimulationTime(400)
        }
        #endif
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
