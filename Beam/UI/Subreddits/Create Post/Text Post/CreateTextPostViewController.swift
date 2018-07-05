//
//  CreateTextPostViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 23-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class CreateTextPostViewController: CreatePostViewController {

    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var textView: MarkdownTextView!
    @IBOutlet var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var textViewPlaceholder: UILabel!
    @IBOutlet var seperatorView: UIView!
    @IBOutlet var seperatorViewHeightConstaint: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewContentView: UIView!
    
    var actionBar: MarkdownActionBar?
    var actionBarBottomConstraint: NSLayoutConstraint?
    
    var showsActionBar: Bool {
        return UIScreen.main.bounds.height >= 568
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.post != nil {
            self.navigationItem.title = AWKLocalizedString("edit-text-post-title")
        } else {
            self.navigationItem.title = AWKLocalizedString("text-post-title")
        }
        
        self.seperatorViewHeightConstaint.constant = 1 / UIScreen.main.scale
        
        self.textViewPlaceholder.text = AWKLocalizedString("your-text-post-placeholder")
        
        self.textView.textContainerInset = UIEdgeInsets.zero
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.delegate = self
        
        self.titleTextField.delegate = self
        
        if self.showsActionBar {
            let actionBar = MarkdownActionBar.markdownActionBar(forTextView: self.textView)
            actionBar.viewController = self
            self.view.addSubview(actionBar)
            actionBar.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraint(NSLayoutConstraint(item: actionBar, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: actionBar, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0))
            self.actionBarBottomConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: actionBar, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)
            self.view.addConstraint(self.actionBarBottomConstraint!)
            self.actionBar = actionBar
            //actionBar.isHidden = true
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.post == nil {
            self.titleTextField.becomeFirstResponder()
        } else {
            self.textView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.titleTextField.resignFirstResponder()
        self.textView.resignFirstResponder()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.view.backgroundColor = backgroundColor
        self.scrollViewContentView.backgroundColor = backgroundColor
        self.scrollView.backgroundColor = backgroundColor
        
        let placeholderColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        self.titleTextField.attributedPlaceholder = NSAttributedString(string: AWKLocalizedString("post-title-placeholder"), attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        self.textViewPlaceholder.textColor = placeholderColor
        
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.titleTextField.textColor = textColor
        self.textView.textColor = textColor
        
        let keyboardAppearance = DisplayModeValue(UIKeyboardAppearance.default, darkValue: UIKeyboardAppearance.dark)
        self.titleTextField.keyboardAppearance = keyboardAppearance
        self.textView.keyboardAppearance = keyboardAppearance
        
        self.seperatorView.backgroundColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
    }
    
    func sizeTextView() {
        guard let navigationController = self.navigationController else {
            return
        }
        var minimumHeight = self.scrollView.frame.height
        minimumHeight -= navigationController.navigationBar.frame.height
        minimumHeight -= self.scrollViewContentView.layoutMargins.top
        minimumHeight -= self.scrollViewContentView.layoutMargins.bottom
        minimumHeight -= self.titleTextField.intrinsicContentSize.height
        minimumHeight -= self.scrollView.contentInset.bottom
        minimumHeight -= 40 //Action bar
        self.textViewHeightConstraint.constant = max(self.textView.sizeThatFits(CGSize(width: self.textView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height, minimumHeight)
        self.scrollView.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.sizeTextView()
    }
    
    // MARK: Notifications
    
    override func keyboardDidChangeFrame(_ frame: CGRect, animationDuration: TimeInterval, animationCurveOption: UIViewAnimationOptions) {
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurveOption, animations: {
            //ANIMATE
            let bottomInset: CGFloat = max(self.view.bounds.height - frame.minY, 0)
            var contentInset = self.scrollView.contentInset
            contentInset.bottom = bottomInset + 40
            self.scrollView.contentInset = contentInset
            self.scrollView.scrollIndicatorInsets = contentInset
            self.actionBarBottomConstraint?.constant = bottomInset
            UIView.performWithoutAnimation({
                self.sizeTextView()
                self.view.layoutIfNeeded()
            })
            
        }, completion: nil)
    }

    override func textfieldDidChange(_ textField: UITextField) {
        
    }
    
    // MARK: CreatePostViewController properties and functions
    
    override var canSubmit: Bool {
        guard isViewLoaded else {
            return false
        }
        guard let title = self.titleTextField.text else {
            return false
        }
        return self.subreddit != nil && title.count > 0
    }
    
    override var hasContent: Bool {
        let title = self.titleTextField.text ?? ""
        let text = self.textView.text ?? ""
        return title.count > 0 || text.count > 0
    }
    
    override internal var postKind: RedditSubmitKind {
        return RedditSubmitKind.text(self.textView.text)
    }
    
    override internal var postTitle: String {
        return self.titleTextField.text!
    }
    
    override func didStartSubmit() {
        self.lockView(true)
    }
    
    override func updatePrefilled() {
        self.textView?.text = self.post?.content
        self.titleTextField?.text = self.post?.title
        let hasPost = self.post != nil
        self.titleTextField?.isEnabled = !hasPost
        self.titleTextField?.alpha = !hasPost ? 1: 0.5
        
        if let text = self.textView?.text {
            self.textViewPlaceholder?.isHidden = !text.isEmpty
        } else {
            self.textViewPlaceholder?.isHidden = false
        }
        
        self.updateSubmitStatus()
    }
    
    override func lockView(_ locked: Bool) {
        super.lockView(locked)
        let alpha: CGFloat = locked ? 0.5: 1.0
        self.titleTextField.isEnabled = !locked && self.post == nil
        self.titleTextField.alpha = self.post != nil ? 0.5: alpha
        self.textView.isEditable = !locked
        self.textView.alpha = alpha
        if locked {
            self.titleTextField.resignFirstResponder()
            self.textView.resignFirstResponder()
        }
    }
    
    func reloadActionBarState() {
        self.actionBar?.isHidden = !(self.textView.isFirstResponder || self.actionBar?.linkTextField.isFirstResponder == true)
    }
}

extension CreateTextPostViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        self.updateSubmitStatus()
        self.textViewPlaceholder.isHidden = self.textView.text.count > 0
        
        self.sizeTextView()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.reloadActionBarState()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView.text.count + (text.count - range.length) <= 15000
    }
}

extension CreateTextPostViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.titleTextField {
            let currentCharacterCount = textField.text?.count ?? 0
            if range.length + range.location > currentCharacterCount {
                return false
            }
            let newLength = currentCharacterCount + string.count - range.length
            return newLength <= 300
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.reloadActionBarState()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.reloadActionBarState()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.titleTextField {
            self.textView.becomeFirstResponder()
        }
        return false
    }
    
}
