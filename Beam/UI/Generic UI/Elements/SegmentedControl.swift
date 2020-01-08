//
//  SegmentedControl.swift
//  beam
//
//  Created by Robin Speijer on 08/01/2020.
//  Copyright © 2020 Awkward. All rights reserved.
//

import UIKit

/// A beam styled segmented control
class SegmentedControl: UISegmentedControl {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setTitleTextAttributes([.foregroundColor: UIColor.beamColor(),
                                .font: UIFont.systemFont(ofSize: 14, weight: .medium)], for: .selected)
        setTitleTextAttributes([.foregroundColor: UIColor.beamGrey().withAlphaComponent(0.3),
                                .font: UIFont.systemFont(ofSize: 14, weight: .medium)], for: .highlighted)
        setTitleTextAttributes([.foregroundColor: UIColor.beamGrey(),
                                .font: UIFont.systemFont(ofSize: 14, weight: .medium)], for: .normal)
        setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
        let size = CGSize(width: 1, height: bounds.height)
        let renderer = UIGraphicsImageRenderer(size: size, format: UIGraphicsImageRendererFormat())
        let divider = renderer.image { context in
            let bounds = CGRect(origin: .zero, size: context.currentImage.size)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 0.5 * bounds.midY))
            path.addLine(to: CGPoint(x: 0, y: 1.5 * bounds.midY))
            UIColor.beamSeparator().setStroke()
            path.stroke()
        }
        
        setDividerImage(divider, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    }
    
}
