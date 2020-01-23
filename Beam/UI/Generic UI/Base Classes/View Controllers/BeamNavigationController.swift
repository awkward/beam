//
//  BeamNavigationController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamNavigationController: UINavigationController, BeamAppearance, UIViewControllerTransitioningDelegate {
    
    var useInteractiveDismissal = true {
        didSet {
            if self.useInteractiveDismissal != oldValue {
                self.refreshInteractiveDismissalState()
            }
        }
    }
    
    lazy var dismissalGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let gr = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(BeamNavigationController.panScreenEdgeDismissal(_:)))
        gr.edges = .left
        gr.maximumNumberOfTouches = 1
        return gr
    }()
    
    // MARK: - Transition
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        view.backgroundColor = AppearanceValue(light: .systemGroupedBackground, dark: .beamDarkBackground)
        navigationBar.standardAppearance.configureBeamAppearance()
        appearanceDidChange()
    }
    
    func refreshInteractiveDismissalState() {
        if useInteractiveDismissal && viewControllers.count <= 1 {
            view.addGestureRecognizer(dismissalGestureRecognizer)
        } else {
            removeDismissalGestureRecognizers()
        }
    }
    
    func removeDismissalGestureRecognizers() {
        view.removeGestureRecognizer(dismissalGestureRecognizer)
    }
    
    @objc private func panScreenEdgeDismissal(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard presentingViewController != nil && gestureRecognizer.state == .recognized else { return }
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate var previousViewFrame: CGRect = CGRect()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //We want to remove the gestures when the x or y coordinates of the frame are higher than zeo. Add them if they are zero
        if self.previousViewFrame != self.view.frame {
            self.previousViewFrame = self.view.frame
            self.refreshInteractiveDismissalState()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            appearanceDidChange()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let supported = self.topViewController?.supportedInterfaceOrientations {
            return supported
        } else {
            guard UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad else {
                return.all
            }
            return .portrait
        }
    }
    
    override var shouldAutorotate: Bool {
        return self.topViewController?.shouldAutorotate ?? true
    }
    
}

extension BeamNavigationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.refreshInteractiveDismissalState()
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.topViewController?.transitionCoordinator?.notifyWhenInteractionChanges({ (_) in
            self.refreshInteractiveDismissalState()
        })
    }
    
}
