//
//  StartTrialViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 19-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Social
import Trekker

class StartTrialViewController: BeamViewController {
    
    @IBOutlet fileprivate var iconImageView: UIImageView!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var descriptionLabel: UILabel!
    
    @IBOutlet fileprivate var shareOnFacebookButton: UIButton!
    @IBOutlet fileprivate var shareOnTwitterButton: UIButton!
    @IBOutlet fileprivate var cancelButton: UIButton!
    
    var storeProduct: StoreProduct? {
        didSet {
            self.iconImageView?.image = self.storeProduct?.icon
        }
    }
    
    
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
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareOnFacebookButton.layer.cornerRadius = 3
        self.shareOnTwitterButton.layer.cornerRadius = 3
        self.cancelButton.layer.cornerRadius = 3
        self.cancelButton.layer.borderWidth = 1
        
        self.iconImageView.alpha = 0
        self.titleLabel.alpha = 0
        self.descriptionLabel.alpha = 0
        self.shareOnFacebookButton.alpha = 0
        self.shareOnTwitterButton.alpha = 0
        self.cancelButton.alpha = 0
        
        self.titleLabel.text = AWKLocalizedString("trial-message-title")
        self.descriptionLabel.text = AWKLocalizedString("trial-message-description").replacingOccurrences(of: "[PACKNAME]", with: self.storeProduct?.heading ?? "Pack")
        
        self.shareOnFacebookButton.setTitle(AWKLocalizedString("share-facebook-button"), for: UIControlState())
        self.shareOnTwitterButton.setTitle(AWKLocalizedString("share-twitter-button"), for: UIControlState())
        self.cancelButton.setTitle(AWKLocalizedString("cancel"), for: UIControlState())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.iconImageView?.image = self.storeProduct?.icon
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var delay: TimeInterval = 0
        let animationDuration: TimeInterval = 0.8
        UIView.animate(withDuration: animationDuration, delay: delay, options: [], animations: { () -> Void in
            self.iconImageView.alpha = 1
            self.titleLabel.alpha = 1
            self.descriptionLabel.alpha = 0.8
            }, completion: nil)
        delay += 0.3
        UIView.animate(withDuration: animationDuration, delay: delay, options: [], animations: { () -> Void in
            self.shareOnFacebookButton.alpha = 1
            }, completion: nil)
        delay += 0.3
        UIView.animate(withDuration: animationDuration, delay: delay, options: [], animations: { () -> Void in
            self.shareOnTwitterButton.alpha = 1
            }, completion: nil)
        delay += 0.3
        UIView.animate(withDuration: animationDuration, delay: delay, options: [], animations: { () -> Void in
            self.cancelButton.alpha = 1
            }, completion: nil)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let buttonTintColor = UIColor.beamColor()
        
        self.shareOnTwitterButton.tintColor = buttonTintColor
        self.shareOnTwitterButton.setTitleColor(buttonTintColor, for: UIControlState())
        self.shareOnTwitterButton.backgroundColor = UIColor.white
        
        self.shareOnFacebookButton.tintColor = buttonTintColor
        self.shareOnFacebookButton.setTitleColor(buttonTintColor, for: UIControlState())
        self.shareOnFacebookButton.backgroundColor = UIColor.white
        
        self.cancelButton.backgroundColor = UIColor.clear
        self.cancelButton.layer.borderColor = UIColor.white.cgColor
        self.cancelButton.setTitleColor(UIColor.white, for: UIControlState())
    }
    
    @IBAction fileprivate func cancel(_ sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction fileprivate func shareOnFacebook(_ sender: AnyObject?) {
        self.openShareSheet(SLServiceTypeFacebook)
    }
    
    @IBAction fileprivate func shareOnTwitter(_ sender: AnyObject?) {
        self.openShareSheet(SLServiceTypeTwitter)
    }
    
    fileprivate func openShareSheet(_ service: String) {
        let composeViewController = SLComposeViewController(forServiceType: service)
        let shareURL = "http://goo.gl/IETAZ7"
        composeViewController?.setInitialText("\(AWKLocalizedString("trial-share-message")) \(shareURL)")
        composeViewController?.completionHandler = { (result) -> Void in
            if result == SLComposeViewControllerResult.done {
                let cherryToken = AppDelegate.shared.cherryController.accessToken
                let deviceToken = UIDevice.current.identifierForVendor!.uuidString
                let identifier = self.storeProduct?.identifier
                AppDelegate.shared.productStoreController.startTrial(cherryToken!, deviceToken: deviceToken, identifier: identifier!, completionHandler: { (trials, error) -> () in
                    DispatchQueue.main.async(execute: { () -> Void in
                        if error != nil {
                            let alertController = BeamAlertController(title: AWKLocalizedString("trial-error-title"), message: AWKLocalizedString("trial-error-message"), preferredStyle: UIAlertControllerStyle.alert)
                            alertController.addCloseAction()
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            Trekker.default.track(event: TrekkerEvent(event: "Start product trial", properties: ["Product type": identifier!, "Activity type": service]))
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                })
            } else {
                AWKDebugLog("User cancelled share action")
            }
        }
        self.present(composeViewController!, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.descriptionLabel.isHidden = self.view.frame.size.height < 540
    }

}

extension StartTrialViewController: UIViewControllerTransitioningDelegate {
    
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
