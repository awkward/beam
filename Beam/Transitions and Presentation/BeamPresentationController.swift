//
//  BeamPresentationController.swift
//  beam
//
//  Created by Robin Speijer on 20-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamPresentationController: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let containerBounds = self.containerView?.bounds ?? UIScreen.main.bounds
        return CGRect(x: 0, y: 0, width: containerBounds.width, height: containerBounds.height)
    }
    
    override var shouldRemovePresentersView: Bool {
        return true
    }
    
    override var shouldPresentInFullscreen: Bool {
        return true
    }
    
    var shouldUseFormSheetIfPossible: Bool {
        if let navigationController = self.presentedViewController as? UINavigationController, let presentation = navigationController.viewControllers.first as? BeamModalPresentation {
            return presentation.preferredModalPresentationStyle == .formsheet
        } else if let presentation = self.presentedViewController as? BeamModalPresentation {
            return presentation.preferredModalPresentationStyle == .formsheet
        }
        return false
    }

    override func adaptivePresentationStyle(for traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.horizontalSizeClass != .compact && traitCollection.verticalSizeClass != .compact && self.shouldUseFormSheetIfPossible {
            return .formSheet
        }
        return .custom
    }
}
