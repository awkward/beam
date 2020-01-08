//
//  SegmentedControl.swift
//  beam
//
//  Created by Robin Speijer on 08/01/2020.
//  Copyright © 2020 Awkward. All rights reserved.
//

import UIKit

/// A beam styled segmented control
class SegmentedControl: UISegmentedControl, DynamicDisplayModeView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        registerForDisplayModeChangeNotifications()
        updateAppearance()
    }
    
    deinit {
        unregisterForDisplayModeChangeNotifications()
    }
    
    private func textColor(for state: UIControl.State) -> UIColor {
        switch state {
        case .selected:
            return DisplayModeValue(.beamPurple(), darkValue: .beamPurpleLight())
        case .highlighted:
            return textColor(for: .normal).withAlphaComponent(0.25)
        default:
            return DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        }
    }
    
    private var dividerColor: UIColor {
        DisplayModeValue(.beamSeparator(), darkValue: .beamDarkTableViewSeperatorColor())
    }
    
    private func updateAppearance() {
        for state in [UIControl.State.normal, .highlighted, .selected] {
            let font = UIFont.systemFont(ofSize: 14, weight: .medium)
            let color = textColor(for: state)
            setTitleTextAttributes([.foregroundColor: color,
                                    .font: font], for: state)
        }
        
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

    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        displayModeDidChange()
    }
    
    func displayModeDidChange() {
        updateAppearance()
    }
    
}
