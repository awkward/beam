//
//  ReplyBarView.swift
//  Beam
//
//  Created by Rens Verhoeven on 19-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

protocol ReplyBarViewDelegate: class {
    
    func replyBar(_ replyBarView: ReplyBarView, didTapSendMessage content: String)
}

class ReplyBarView: BeamView {
    
    fileprivate weak var delegate: ReplyBarViewDelegate?
    
    @IBOutlet var textView: UITextView! {
        didSet {
            self.textView.delegate = self
        }
    }
    @IBOutlet var placeholderLabel: UILabel!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var activitiyIndicatorView: UIActivityIndicatorView!
    
    var isEnabled = true {
        didSet {
            self.textView.isEditable = self.isEnabled
            self.textView.isSelectable = self.isEnabled
            self.textView.isUserInteractionEnabled = self.isEnabled
            self.sendButton.isEnabled = self.isEnabled
            if self.textView.isFirstResponder {
                self.textView.resignFirstResponder()
            }
        }
    }
    
    var sending = false {
        didSet {
            self.isEnabled = !self.sending
            self.sendButton.isHidden = self.sending
            self.activitiyIndicatorView.isHidden = !self.sending
        }
    }
    
    var replyToItemString: String? {
        didSet {
            self.reloadPlaceholderText()
        }
    }
    
    var text: String? {
        set {
            self.textView.text = newValue
            self.reloadEditingState()
        }
        get {
            return self.textView.text
        }
    }

    var bottomConstraint: NSLayoutConstraint?
    
    class func loadFromNib(_ replyToItemString: String?, delegate: ReplyBarViewDelegate) -> ReplyBarView {
        let barView = UINib(nibName: "ReplyBarView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! ReplyBarView
        barView.delegate = delegate
        barView.replyToItemString = replyToItemString
        barView.reloadEditingState()
        return barView
    }
    
    func addToViewController(_ viewController: UIViewController) {
        guard let view = viewController.view else {
            return
        }
        view.addSubview(self)
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0))
        self.bottomConstraint = NSLayoutConstraint(item: viewController.bottomLayoutGuide, attribute: .top, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        view.addConstraint(self.bottomConstraint!)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.sendButton.setTitle(AWKLocalizedString("send-button"), for: UIControlState())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func setupView() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(ReplyBarView.keyboardFrameWillChange(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ReplyBarView.keyboardFrameWillChange(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ReplyBarView.keyboardFrameWillChange(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc fileprivate func keyboardFrameWillChange(_ notification: Notification) {
        self.updatePosition(notification)
    }
    
    fileprivate func reloadPlaceholderText() {
        if let replyToItemString = self.replyToItemString {
            self.placeholderLabel.text = "\(NSLocalizedString("reply-to-comments", comment: "Reply to post or Reply to thread in the comments view")) \(replyToItemString)"
        } else {
            self.placeholderLabel.text = nil
        }
    }
    
    fileprivate func updatePosition(_ notification: Notification) {
        if let bottomConstraint = self.bottomConstraint {
            let userInfo = (notification as NSNotification).userInfo!
            
            let frameEnd = (userInfo[UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
            let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
            
            var constant: CGFloat = frameEnd?.height ?? 0
            if notification.name == NSNotification.Name.UIKeyboardDidHide || notification.name == NSNotification.Name.UIKeyboardWillHide {
                constant = 0
            }
            if let layoutGuide = bottomConstraint.firstItem as? UILayoutSupport {
                if constant > 0 {
                    constant -= layoutGuide.length
                }
            }
            
            UIView.animate(withDuration: duration.doubleValue, delay: 0.0, options: UIViewAnimationOptions(rawValue: UInt(curve.intValue)), animations: { () -> Void in
                
                bottomConstraint.constant = constant
                if let superview = self.superview {
                    superview.layoutIfNeeded()
                } else {
                    self.layoutIfNeeded()
                }
                
                }, completion: nil)
        } else {
            AWKDebugLog("ReplyBarView: No bottom constraint set, so the view is not moving")
        }

    }
    
    override func draw(_ rect: CGRect) {
        let seperatorColor = DisplayModeValue(UIColor.beamSeperatorColor(), darkValue: UIColor.beamDarkTableViewSeperatorColor())
        let seperatorPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: rect.width, height: 0.5))
        seperatorColor.setFill()
        seperatorPath.fill()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.isOpaque = true
        self.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1))
        self.textView.backgroundColor = self.backgroundColor
        self.placeholderLabel.backgroundColor = UIColor.clear

        self.textView.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.sendButton.tintColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        self.textView.tintColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        self.placeholderLabel.textColor = DisplayModeValue(UIColor(red: 110 / 255, green: 106 / 255, blue: 122 / 255, alpha: 1.0), darkValue: UIColor.white).withAlphaComponent(0.7)
        
        self.textView.keyboardAppearance = DisplayModeValue(UIKeyboardAppearance.light, darkValue: UIKeyboardAppearance.dark)
        if self.textView.isFirstResponder {
            self.textView.resignFirstResponder()
            self.textView.becomeFirstResponder()
        }
        
        self.reloadPlaceholderText()
        
        self.setNeedsDisplay()
    }
    
    func clear() {
        self.text = nil
    }
    
    // MARK: - First Responder
    
    override func becomeFirstResponder() -> Bool {
        return self.textView.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return self.textView.resignFirstResponder()
    }
    
    @objc @IBAction func sendText(_ sender: AnyObject) {
        if let delegate = self.delegate {
            delegate.replyBar(self, didTapSendMessage: self.textView.text)
        }
    }
    
    func reloadEditingState() {
        self.placeholderLabel.isHidden = self.textView.text.count > 0
        self.sendButton.isEnabled = self.textView.text.count > 0
    }
}

extension ReplyBarView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        self.reloadEditingState()
    }
}
