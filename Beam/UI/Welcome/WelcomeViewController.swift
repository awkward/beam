//
//  WelcomeViewController.swift
//  beam
//
//  Created by Rens Verhoeven on 02-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import SafariServices
import Snoo
import Darwin
import Trekker

class WelcomeViewController: BeamViewController {

    @IBOutlet fileprivate var appIconImageView: UIImageView!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var textLabel: UILabel!
    @IBOutlet fileprivate var connectWithRedditButton: UIButton!
    @IBOutlet fileprivate var connectWithoutRedditButton: UIButton!
    @IBOutlet fileprivate var backgroundView: StarsBackgroundView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.transitioningDelegate = self
        self.modalPresentationStyle = UIModalPresentationStyle.custom
        self.modalPresentationCapturesStatusBarAppearance = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(WelcomeViewController.userDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: AppDelegate.shared.authenticationController)
        notificationCenter.addObserver(self, selector: #selector(WelcomeViewController.applicationStateChanged(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(WelcomeViewController.applicationStateChanged(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupView() {
        //Title
        self.titleLabel.text = AWKLocalizedString("welcome-title")
        
        //Text
        self.textLabel.text = AWKLocalizedString("welcome-message")
    
        //Connect button
        self.connectWithRedditButton.backgroundColor = .white
        self.connectWithRedditButton.layer.cornerRadius = 3
        self.connectWithRedditButton.layer.masksToBounds = true
        self.connectWithRedditButton.setTitle(AWKLocalizedString("welcome-connect-with-reddit-button"), for: .normal)
        
        //Connect without account button
        self.connectWithoutRedditButton.backgroundColor = .clear
        self.connectWithoutRedditButton.setTitleColor(.white, for: .normal)
        self.connectWithoutRedditButton.setTitle(AWKLocalizedString("welcome-connect-without-reddit-button"), for: .normal)
        
        self.appIconImageView.alpha = 0
        self.titleLabel.alpha = 0
        self.textLabel.alpha = 0
        self.connectWithoutRedditButton.alpha = 0
        self.connectWithRedditButton.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var delay: TimeInterval = 0
        let animationDuration: TimeInterval = 1.4
        UIView.animate(withDuration: animationDuration, delay: delay, options: [], animations: { () -> Void in
            self.appIconImageView.alpha = 1
            self.titleLabel.alpha = 1
            self.textLabel.alpha = 0.8
            }, completion: nil)
        delay += 0.3
        UIView.animate(withDuration: animationDuration, delay: delay, options: [], animations: { () -> Void in
            self.connectWithoutRedditButton.alpha = 1
            }, completion: nil)
        delay += 0.6
        UIView.animate(withDuration: animationDuration, delay: delay, options: [], animations: { () -> Void in
            self.connectWithRedditButton.alpha = 1
            }, completion: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.presentedViewController == nil {
            Trekker.default.track(event: TrekkerEvent(event: "Use welcome view"))
        }
        
    }
    
    @objc func applicationStateChanged(_ notification: Notification) {
        self.backgroundView.paused = (UIApplication.shared.applicationState != .active)
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.view.backgroundColor = UIColor.clear
    }
    
    @IBAction func exploreWithoutAccount(_ sender: AnyObject?) {
        self.dismiss(animated: true, completion: { () -> Void in
            Trekker.default.track(event: TrekkerEvent(event: "Use Beam without account"))
            AppDelegate.shared.userNotificationsHandler.registerForUserNotifications()
        })
    }
    
    @IBAction func login(_ sender: AnyObject) {
        AppDelegate.shared.presentAuthenticationViewController()
    }
    
    @objc func userDidChange(_ notification: Notification?) {
        if AppDelegate.shared.authenticationController.isAuthenticated {
            Trekker.default.track(event: TrekkerEvent(event: "Login with reddit account"))
            //The delay is a workaround to fix an issue with SFSafariViewController dismissing
            let secondsToDelay: Double = 0.25
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(secondsToDelay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.dismiss(animated: true, completion: { () -> Void in
                    AppDelegate.shared.userNotificationsHandler.registerForUserNotifications()
                })
            }
            
        }
    }
}

extension WelcomeViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented == self {
            let animator = BasicViewControllerTransition()
            animator.animationStyle = .fade
            return animator
        }
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed == self {
            let animator = BasicViewControllerTransition()
            animator.animationStyle = .fade
            animator.isDismissal = true
            return animator
        }
        return nil
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented == self {
            if let presenting = presenting {
                return BlurredDimmingPresentationController(presentedViewController: presented, presenting: presenting)
            } else {
                return BlurredDimmingPresentationController(presentedViewController: presented, presenting: source)
            }
        }
        return nil
    }
    
}
