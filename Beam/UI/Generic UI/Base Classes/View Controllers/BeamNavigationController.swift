//
//  BeamNavigationController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamNavigationController: UINavigationController, DynamicDisplayModeView, UIViewControllerTransitioningDelegate {
    
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
        
        self.presentationController?.delegate = self
        self.delegate = self
        
        self.navigationBar.backIndicatorImage = UIImage(named: "navigationbar_arrow_back")
        self.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "navigationbar_arrow_back_mask")
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerForDisplayModeChangeNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterForDisplayModeChangeNotifications()
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
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        
        var titleAttributes = navigationBar.titleTextAttributes ?? [NSAttributedString.Key: Any]()
        
        switch displayMode {
        case .default:
            view.backgroundColor = .systemGroupedBackground
            
            titleAttributes[NSAttributedString.Key.foregroundColor] = UIColor.black
            
        case .dark:
            view.backgroundColor = UIColor.beamDarkBackgroundColor()
            
            titleAttributes[NSAttributedString.Key.foregroundColor] = UIColor(red: 245 / 255.0, green: 245 / 255.0, blue: 247 / 255.0, alpha: 1)
        }
        
        self.navigationBar.barTintColor = DisplayModeValue(UIColor.beamBarColor(), darkValue: UIColor.beamDarkContentBackgroundColor())
        self.navigationBar.titleTextAttributes = titleAttributes
        
        let newTintColor = (displayMode == .dark) ? UIColor.beamPurpleLight() : UIColor.beamColor()
        self.navigationBar.tintColor = newTintColor
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return displayMode == .dark ? UIStatusBarStyle.lightContent: UIStatusBarStyle.default
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

extension BeamNavigationController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            return .fullScreen
        default:
            return .formSheet
        }
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
