//
//  DonateThankYouViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 12-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class DonateThankYouViewController: BeamViewController {
    
    @IBOutlet fileprivate var appIconImageView: UIImageView!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var textLabel: UILabel!
    @IBOutlet fileprivate var closeButton: UIButton!
    @IBOutlet fileprivate var backgroundView: StarsBackgroundView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.transitioningDelegate = self
        self.modalPresentationStyle = UIModalPresentationStyle.custom
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.transitioningDelegate = self
        self.modalPresentationStyle = UIModalPresentationStyle.custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(DonateThankYouViewController.applicationStateChanged(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(DonateThankYouViewController.applicationStateChanged(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupView() {
        let tintColor = UIColor.beamColor()
        let cornerRadius: CGFloat = 3
        
        //Title
        self.titleLabel.text = AWKLocalizedString("donate-thankyou-title")
        
        //Text
        self.textLabel.text = AWKLocalizedString("donate-thankyou-message")
        
        //Connect button
        self.closeButton.setTitle(AWKLocalizedString("close-button"), for: UIControlState())
        self.closeButton.backgroundColor = UIColor.white
        self.closeButton.setTitleColor(tintColor, for: UIControlState())
        self.closeButton.layer.cornerRadius = cornerRadius
        self.closeButton.layer.masksToBounds = true
        
        self.appIconImageView.alpha = 0
        self.titleLabel.alpha = 0
        self.textLabel.alpha = 0
        self.closeButton.alpha = 0
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
            self.closeButton.alpha = 1
            }, completion: nil)
    }
    
    @objc func applicationStateChanged(_ notification: Notification) {
        self.backgroundView.paused = (UIApplication.shared.applicationState != .active)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.view.backgroundColor = UIColor.clear
    }
    
    @IBAction func close(_ sender: UIButton?) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension DonateThankYouViewController: UIViewControllerTransitioningDelegate {
    
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
            if let presenting: UIViewController = presenting {
                return BlurredDimmingPresentationController(presentedViewController: presented, presenting: presenting)
            } else {
                return BlurredDimmingPresentationController(presentedViewController: presented, presenting: source)
            }
            
        }
        return nil
    }
    
}
