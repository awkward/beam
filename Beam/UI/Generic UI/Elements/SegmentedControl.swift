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
        
        updateAppearance()
    }
    
    private func textColor(for state: UIControl.State) -> UIColor {
        switch state {
        case .selected:
            return .beam
        case .highlighted:
            return textColor(for: .normal).withAlphaComponent(0.25)
        default:
            return .secondaryLabel
        }
    }
    
    private var dividerColor: UIColor {
        AppearanceValue(light: .beamSeparator, dark: .beamDarkTableViewSeperator)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        for state in [UIControl.State.normal, .highlighted, .selected] {
            let font = UIFont.systemFont(ofSize: 14, weight: .medium)
            let color = textColor(for: state)
            setTitleTextAttributes([.foregroundColor: color,
                                    .font: font], for: state)
        }
        
        backgroundColor = .clear
        setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
        
        let size = CGSize(width: 1, height: bounds.height)
        let renderer = UIGraphicsImageRenderer(size: size, format: UIGraphicsImageRendererFormat())
        let divider = renderer.image { context in
            let bounds = CGRect(origin: .zero, size: context.currentImage.size)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 0.5 * bounds.midY))
            path.addLine(to: CGPoint(x: 0, y: 1.5 * bounds.midY))
            dividerColor.setStroke()
            path.stroke()
        }
        setDividerImage(divider, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    }
    
}
