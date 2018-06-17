//
//  MarkdownActionBar.swift
//  Beam
//
//  Created by Rens Verhoeven on 24-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class MarkdownActionBar: BeamView {
    
    weak var textView: MarkdownTextView?
    weak var viewController: UIViewController?
    
    var selectedLinkTextRange: UITextRange?
    var selectedLinkRange: NSRange?
    
    @IBOutlet var linkButton: UIButton!
    @IBOutlet var boldButton: UIButton!
    @IBOutlet var italicButton: UIButton!
    
    @IBOutlet var linkTextField: UITextField!
    @IBOutlet var addLinkButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addLinkButton.isHidden = true
        self.linkTextField.isHidden = true
        self.addLinkButton.setTitle(AWKLocalizedString("add-button"), for: UIControlState())
    }
    
    class func markdownActionBar(forTextView textView: MarkdownTextView) -> MarkdownActionBar {
        let view = UINib(nibName: "MarkdownActionBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! MarkdownActionBar
        view.textView = textView
        return view
    }

    @IBAction func linkTapped(_ sender: AnyObject) {
        if self.linkTextField.isHidden {
            self.expandLinkField()
        } else {
            self.collapseLinkField()
            
        }
    }
    
    func expandLinkField() {
        self.selectedLinkTextRange = self.textView?.selectedTextRange
        self.selectedLinkRange = self.textView?.selectedRange
        if self.linkTextField.text?.count == 0 {
            self.linkTextField.text = "http://"
        }
        UIView.animate(withDuration: 0.1, animations: {
            self.boldButton.alpha = 0
            self.italicButton.alpha = 0
            }, completion: { (_) in
                self.boldButton.isHidden = true
                self.italicButton.isHidden = true
                
                self.linkTextField.alpha = 0
                self.addLinkButton.alpha = 0
                self.linkTextField.isHidden = false
                self.addLinkButton.isHidden = false
                UIView.animate(withDuration: 0.1, animations: {
                    self.linkTextField.alpha = 1
                    self.addLinkButton.alpha = 1
                    }, completion: { (_) in
                        self.linkTextField.isEnabled = true
                        self.linkTextField.becomeFirstResponder()
                })
        })
    }
    
    func collapseLinkField() {
        self.linkTextField.isEnabled = false
        self.textView?.becomeFirstResponder()
        UIView.animate(withDuration: 0.1, animations: {
            self.linkTextField.alpha = 0
            self.addLinkButton.alpha = 0
            
            }, completion: { (_) in
                self.linkTextField.isHidden = true
                self.addLinkButton.isHidden = true
                
                self.boldButton.alpha = 0
                self.italicButton.alpha = 0
                self.boldButton.isHidden = false
                self.italicButton.isHidden = false
                self.bringSubview(toFront: self.boldButton)
                UIView.animate(withDuration: 0.30, animations: {
                    self.boldButton.alpha = 1
                    self.italicButton.alpha = 1
                })
        })
    }
    
    @IBAction func boldTapped(_ sender: AnyObject) {
        self.textView?.applyBoldStylingToText()
    }
    
    @IBAction func italicTapped(_ sender: AnyObject) {
        self.textView?.applyItalicStylingToText()
    }
    
    @IBAction func addLinkTapped(_ sender: AnyObject) {
        self.textView?.insertLink(self.linkTextField.text!, selectedTextRange: self.selectedLinkTextRange, selectedRange: self.selectedLinkRange)
        self.linkTextField.text = nil
        self.collapseLinkField()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 40)
    }
    
    override func draw(_ rect: CGRect) {
        let height = 1 / UIScreen.main.scale
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: rect.width, height: height))
        let borderColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
        borderColor.setFill()
        path.fill()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let placeholderColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        self.linkTextField.attributedPlaceholder = NSAttributedString(string: AWKLocalizedString("link-field-placeholder"), attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        
        self.linkTextField.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        let tintColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        if self.tintColor != tintColor {
            self.tintColor = tintColor
        }
        
        self.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.black)
    }

}

extension MarkdownActionBar: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.linkTextField && textField.text == "http://" {
            textField.text = nil
        }
        //self.collapseLinkField()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.addLinkTapped(textField)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.linkTextField && textField.text == "http://" && (string == UIPasteboard.general.string || string == UIPasteboard.general.url?.absoluteString) {
            textField.text = nil
        }
        if textField == self.linkTextField && string == UIPasteboard.general.string && !string.contains("http") {
            textField.text = "http://\(string)"
            return false
        }
        return true
    }
    
}
