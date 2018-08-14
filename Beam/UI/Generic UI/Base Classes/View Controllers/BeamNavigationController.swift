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
    
    var useScalingTransition: Bool = true {
        didSet {
            self.transitionHandler.scaleBackground = self.useScalingTransition
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configureDefaultTransitionStyle()
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        
        self.configureDefaultTransitionStyle()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.configureDefaultTransitionStyle()
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    // MARK: - Transition
    
    lazy fileprivate var transitionHandler: NewBeamViewControllerTransitionHandler = {
        return NewBeamViewControllerTransitionHandler(delegate: self)
    }()
    
    fileprivate func configureDefaultTransitionStyle() {
        if self.transitioningDelegate == nil {
            self.transitioningDelegate = self.transitionHandler
            self.modalPresentationStyle = UIModalPresentationStyle.custom
            self.modalPresentationCapturesStatusBarAppearance = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.parent is UISplitViewController {
            self.useInteractiveDismissal = false
            self.transitioningDelegate = nil
        }
        
        //Assign ourselves to be the delegate
        self.delegate = self
        
        self.navigationBar.backIndicatorImage = UIImage(named: "navigationbar_arrow_back")
        self.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "navigationbar_arrow_back_mask")
    }
    
    func refreshInteractiveDismissalState() {
        let modalPresentationStyle = (self.topViewController as? BeamModalPresentation)?.preferredModalPresentationStyle ?? BeamModalPresentationStyle.custom
        //The ViewController's traitCollection size class is "unspecified" during transition. Also in this case we want to know the traitCollection of the whole screen, because that predicts if it's using a formsheet or fullscreen display
        let traitCollection = AppDelegate.shared.window?.traitCollection ?? self.traitCollection
        
        if self.useInteractiveDismissal && (modalPresentationStyle == .custom || traitCollection.horizontalSizeClass == .compact) && !(self.parent is UITabBarController) {
            self.navigationBar.addGestureRecognizer(self.transitionHandler.topPanGestureRecognizer)
            
            if self.viewControllers.count <= 1 {
                self.view.addGestureRecognizer(self.transitionHandler.screenEdgePanGestureRecognizer)
            } else if self.viewControllers.count > 1 {
                self.view.removeGestureRecognizer(self.transitionHandler.screenEdgePanGestureRecognizer)
            }
        } else {
            self.removeDismissalGestureRecognizers()
        }
    }
    
    func removeDismissalGestureRecognizers() {
        self.navigationBar.removeGestureRecognizer(self.transitionHandler.topPanGestureRecognizer)
        self.view.removeGestureRecognizer(self.transitionHandler.screenEdgePanGestureRecognizer)
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
        
        var titleAttributes = navigationBar.titleTextAttributes ?? [NSAttributedStringKey: Any]()
        
        switch displayMode {
        case .default:
            view.backgroundColor = UIColor.groupTableViewBackground
            
            titleAttributes[NSAttributedStringKey.foregroundColor] = UIColor.black
            
        case .dark:
            view.backgroundColor = UIColor.beamDarkBackgroundColor()
            
            titleAttributes[NSAttributedStringKey.foregroundColor] = UIColor(red: 245 / 255.0, green: 245 / 255.0, blue: 247 / 255.0, alpha: 1)
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

extension BeamNavigationController: NewBeamViewControllerTransitionHandlerDelegate {
    
    func transitionHandlerShouldStartInteractiveTransition(_ handler: NewBeamViewControllerTransitionHandler) -> Bool {
        return self.presentingViewController != nil && self.viewControllers.count <= 1
    }
    
    func transitionHandlerDidStartInteractiveTransition(_ handler: NewBeamViewControllerTransitionHandler) {
        guard self.presentingViewController != nil else {
            return
        }
        self.dismiss(animated: true, completion: nil)
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
