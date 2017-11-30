//
//  BeamNavigationController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamNavigationController: UINavigationController, DynamicDisplayModeView, UIViewControllerTransitioningDelegate, BeamViewControllerTransitionDelegate {
    
    lazy fileprivate var animationController: BeamViewControllerTransition = {
        return BeamViewControllerTransition()
    }()
    
    var customAnimationController: BeamViewControllerTransition? {
        set {
            //Only set a new animation controller if it's different
            guard newValue != self.animationController else {
                return
            }
            self.removeDismissalGestureRecognizers()
            if newValue == nil {
                self.animationController = BeamViewControllerTransition()
            } else {
                self.animationController = newValue!
            }
            self.refreshInteractiveDismissalState()
        }
        get {
            return self.animationController
        }
    }
    
    var useInteractiveDismissal = true {
        didSet {
            if self.useInteractiveDismissal != oldValue {
                self.refreshInteractiveDismissalState()
            }
        }
    }
    
    var useScalingTransition: Bool = true
    
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
    
    fileprivate func configureDefaultTransitionStyle() {
        if self.transitioningDelegate == nil {
            self.transitioningDelegate = self
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
        
        self.animationController.delegate = self
        
        self.navigationBar.backIndicatorImage = UIImage(named: "navigationbar_arrow_back")
        self.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "navigationbar_arrow_back_mask")
    }
    
    func refreshInteractiveDismissalState() {
        let modalPresentationStyle = (self.topViewController as? BeamModalPresentation)?.preferredModalPresentationStyle ?? BeamModalPresentationStyle.custom
        //The ViewController's traitCollection size class is "unspecified" during transition. Also in this case we want to know the traitCollection of the whole screen, because that predicts if it's using a formsheet or fullscreen display
        let traitCollection = AppDelegate.shared.window?.traitCollection ?? self.traitCollection
        
        if self.useInteractiveDismissal && (modalPresentationStyle == .custom || traitCollection.horizontalSizeClass == .compact) {
            //Adding a gesture recognizer more than once, can cause undocumented behavior
            if !(self.navigationBar.gestureRecognizers?.contains(self.animationController.topPanDismissalGestureRecognizer) ?? false) {
                self.navigationBar.addGestureRecognizer(self.animationController.topPanDismissalGestureRecognizer)
            }
            
            if self.viewControllers.count <= 1 {
                if !(self.view.gestureRecognizers?.contains(self.animationController.sidePanDismissalGestureRecognizer) ?? false) {
                    self.view.addGestureRecognizer(self.animationController.sidePanDismissalGestureRecognizer)
                }
            } else if self.viewControllers.count > 1 {
                if (self.view.gestureRecognizers?.contains(self.animationController.sidePanDismissalGestureRecognizer) ?? false) {
                    self.view.removeGestureRecognizer(self.animationController.sidePanDismissalGestureRecognizer)
                }
            }
        } else {
            self.removeDismissalGestureRecognizers()
        }
    }
    
    func removeDismissalGestureRecognizers() {
        //Removing a gesture recognizer more than once, can cause undocumented behavior
        if (self.navigationBar.gestureRecognizers?.contains(self.animationController.topPanDismissalGestureRecognizer) ?? false) {
            self.navigationBar.removeGestureRecognizer(self.animationController.topPanDismissalGestureRecognizer)
        }
        if (self.view.gestureRecognizers?.contains(self.animationController.sidePanDismissalGestureRecognizer) ?? false) {
            self.view.removeGestureRecognizer(self.animationController.sidePanDismissalGestureRecognizer)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerForDisplayModeChangeNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterForDisplayModeChangeNotifications()
    }
    
    fileprivate var isFirstLayout = true
    fileprivate var previousViewFrame: CGRect = CGRect()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.isFirstLayout {
            self.isFirstLayout = false
            self.configureContentLayout()
        }
        
        //We want to remove the gestures when the x or y coordinates of the frame are higher than zeo. Add them if they are zero
        if self.previousViewFrame != self.view.frame {
            self.previousViewFrame = self.view.frame
            self.refreshInteractiveDismissalState()
        }
    }
    
    func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        
        var titleAttributes = navigationBar.titleTextAttributes ?? [String: AnyObject]()
        
        switch displayMode {
        case .default:
            view.backgroundColor = UIColor.groupTableViewBackground
            
            titleAttributes[NSForegroundColorAttributeName] = UIColor.black
            
        case .dark:
            view.backgroundColor = UIColor.beamDarkBackgroundColor()
            
            titleAttributes[NSForegroundColorAttributeName] = UIColor(red: 245/255.0, green: 245/255.0, blue: 247/255.0, alpha: 1)
        }
        
        self.navigationBar.barTintColor = DisplayModeValue(UIColor.beamBarColor(), darkValue: UIColor.beamDarkContentBackgroundColor())
        self.navigationBar.titleTextAttributes = titleAttributes
        
        let newTintColor = (displayMode == .dark) ? UIColor.beamPurpleLight() : UIColor.beamColor()
        self.navigationBar.tintColor = newTintColor
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return displayMode == .dark ? UIStatusBarStyle.lightContent : UIStatusBarStyle.default
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if let supported = self.topViewController?.supportedInterfaceOrientations {
            return supported
        } else {
            guard UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad else{
                return.all
            }
            return .portrait
        }
    }
    
    override var shouldAutorotate : Bool {
        return self.topViewController?.shouldAutorotate ?? true
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard self.shouldUseAnimationController(for: presented) else {
            return nil
        }
        self.animationController.isDimissal = false
        self.animationController.adjustAlphaDuringTransition = self.useScalingTransition
        self.animationController.includesScaling = self.useScalingTransition
        return self.animationController
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard self.shouldUseAnimationController(for: dismissed) else {
            return nil
        }
        self.animationController.isDimissal = true
        self.animationController.adjustAlphaDuringTransition = self.useScalingTransition
        self.animationController.includesScaling = self.useScalingTransition
        return self.animationController
        
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.animationController.shouldStartInteractiveTransition {
            self.animationController.isDimissal = true
            self.animationController.adjustAlphaDuringTransition = self.useScalingTransition
            self.animationController.includesScaling = self.useScalingTransition
            return self.animationController
        } else {
            return nil
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return BeamPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    // MARK: - BeamViewControllerTransitionDelegate
    
    func modalViewControllerTransition(_ transition: BeamViewControllerTransition, didCompleteTransition: Bool) {
        
    }
    
    func modalViewControllerTransition(_ transition: BeamViewControllerTransition, shouldInteractivelyDismissInDirection: BeamViewControllerTransitionDirection) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func modalViewControllerTransitionShouldStartInteractiveSidePanTransition(_ transition: BeamViewControllerTransition) -> Bool {
        return self.viewControllers.count <= 1
    }
    
    private func shouldUseAnimationController(for viewController: UIViewController) -> Bool {
        let traitCollection = AppDelegate.shared.window?.traitCollection ?? self.traitCollection
        if let navigationController = viewController as? UINavigationController, let presentation = navigationController.viewControllers.first as? BeamModalPresentation {
            return presentation.preferredModalPresentationStyle == .custom || traitCollection.horizontalSizeClass == .compact
        } else if let presentation = viewController as? BeamModalPresentation {
            return presentation.preferredModalPresentationStyle == .custom || traitCollection.horizontalSizeClass == .compact
        }
        return true
    }
    
}

extension BeamNavigationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.refreshInteractiveDismissalState()
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.topViewController?.transitionCoordinator?.notifyWhenInteractionEnds({ (context) in
            self.refreshInteractiveDismissalState()
        })
    }
    
}

extension BeamNavigationController: EmbeddingLayoutSupport {
    
    func embeddedLayout() -> UIEdgeInsets {
        let contentInset = self.contentInset
        return UIEdgeInsets(top: contentInset.top + self.navigationBar.bounds.height, left: 0, bottom: contentInset.bottom, right: 0)
    }
    
}
