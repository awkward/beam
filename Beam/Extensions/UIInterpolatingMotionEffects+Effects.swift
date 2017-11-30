//
//  UIView+MotionEffects.swift
//  beam
//
//  Created by Robin Speijer on 02-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Foundation

extension UIInterpolatingMotionEffect {
    
    class func centerEffectWithEdgeOffsets(_ edgeOffsets: UIEdgeInsets) -> UIMotionEffect {
        let xMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.tiltAlongHorizontalAxis)
        xMotionEffect.minimumRelativeValue = NSNumber(value: Double(edgeOffsets.left) as Double)
        xMotionEffect.maximumRelativeValue = NSNumber(value: Double(edgeOffsets.right) as Double)
        
        let yMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.tiltAlongVerticalAxis)
        yMotionEffect.minimumRelativeValue = NSNumber(value: Double(edgeOffsets.top) as Double)
        yMotionEffect.maximumRelativeValue = NSNumber(value: Double(edgeOffsets.right) as Double)

        let groupedEffect = UIMotionEffectGroup()
        groupedEffect.motionEffects = [xMotionEffect, yMotionEffect]
        return groupedEffect
    }
    
}
