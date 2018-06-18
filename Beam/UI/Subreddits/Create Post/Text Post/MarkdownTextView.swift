//
//  MarkdownTextView.swift
//  Beam
//
//  Created by Rens Verhoeven on 25-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

enum MarkdownTextViewStyling {
    case bold
    case italic
    
    var beginString: String {
        switch self {
        case .bold:
            return "**"
        case .italic:
            return "*"
        }
    }
    
    var endString: String {
        switch self {
        case .bold:
            return "**"
        case .italic:
            return "*"
        }
    }
}

class MarkdownTextView: UITextView {
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        let keyCommands = super.keyCommands ?? [UIKeyCommand]()
        return keyCommands + [
            UIKeyCommand(input: "b", modifierFlags: [UIKeyModifierFlags.command, UIKeyModifierFlags.alternate], action: #selector(MarkdownTextView.keyCommandUsed(_:)), discoverabilityTitle: "Make text bold"),
            UIKeyCommand(input: "l", modifierFlags: [UIKeyModifierFlags.command, UIKeyModifierFlags.alternate], action: #selector(MarkdownTextView.keyCommandUsed(_:)), discoverabilityTitle: "Add a link"),
            UIKeyCommand(input: "i", modifierFlags: [UIKeyModifierFlags.command, UIKeyModifierFlags.alternate], action: #selector(MarkdownTextView.keyCommandUsed(_:)), discoverabilityTitle: "Make text italic")
        ]
    }
    
    fileprivate var selectedText: String? {
        guard self.selectedTextRange != nil && self.selectedTextRange?.isEmpty == false else {
            return nil
        }
        return self.text(in: self.selectedTextRange!)
    }
    
    @objc internal func keyCommandUsed(_ sender: UIKeyCommand) {
        if sender.modifierFlags == [UIKeyModifierFlags.command, UIKeyModifierFlags.alternate] {
            if sender.input == "b" {
                self.applyBoldStylingToText()
            } else if sender.input == "i" {
                self.applyItalicStylingToText()
            } else if sender.input == "l" {
                self.startAddingLink()
            }
        }
    }
    
    func startAddingLink(_ viewController: UIViewController? = nil) {
        if let selectedText = self.selectedText {
            NSLog("Add link to selected text \(selectedText)")
            if selectedText.lowercased().contains("http://") || selectedText.lowercased().contains("www.") || selectedText.lowercased().contains("mailto:") {
                self.showLinkAlert(viewController, title: nil, link: selectedText, selectedTextRange: self.selectedTextRange)
            } else {
                self.showLinkAlert(viewController, title: selectedText, link: nil, selectedTextRange: self.selectedTextRange)
            }
        } else {
            self.showLinkAlert(viewController, title: nil, link: nil, selectedTextRange: self.selectedTextRange)
        }
    }
    
    func applyBoldStylingToText() {
        self.applyStyling(self.selectedText, styling: MarkdownTextViewStyling.bold, selectedRange: self.selectedTextRange)
    }
    
    func applyItalicStylingToText() {
        self.applyStyling(self.selectedText, styling: MarkdownTextViewStyling.italic, selectedRange: self.selectedTextRange)
    }

    func applyLink(_ title: String?, link: String?, selectedTextRange: UITextRange?, selectedRange: NSRange? = nil) {
        guard title != nil || link != nil else {
            return
        }
        var newText: String!
        if let title = title, let link = link {
            newText = "[\(title)](\(link))"
        } else if let link = link {
            newText = "[\(link)](\(link))"
        } else {
            newText = title
        }
        if let selectedTextRange = selectedTextRange {
            self.replace(selectedTextRange, withText: newText)
        } else {
            //Add to the end
            var string: String!
            if let text = self.text {
                string = text + newText
            } else {
                string = newText
            }
            
            self.text = string
        }
    }
    
    func insertLink(_ link: String, selectedTextRange: UITextRange?, selectedRange: NSRange?, selectTitle: Bool = true) {
        self.applyLink(link, link: link, selectedTextRange: selectedTextRange)
        if let selectedRange = selectedRange, selectTitle == true {
            if self.isFirstResponder == false {
                self.becomeFirstResponder()
            }
            self.selectedRange = NSRange(location: selectedRange.location + 1, length: link.count)
        }
    }
    
    func applyStyling(_ selectedText: String?, styling: MarkdownTextViewStyling, selectedRange: UITextRange?) {
        if let selectedText = selectedText {
            let newString = styling.beginString + selectedText + styling.endString
            self.replace(selectedRange!, withText: newString)
        } else {
            if let selectedTextRange = selectedRange, self.isFirstResponder == true {
                //Append to the text and set the cursor
                let selectedRange = self.selectedRange
                self.replace(selectedTextRange, withText: styling.beginString + styling.endString)
                self.selectedRange = NSRange(location: selectedRange.location + styling.beginString.count, length: 0)
            } else {
                //Append to the end, make the textview first responder and set the cursor
                var newText = self.text ?? ""
                newText += styling.beginString + styling.endString
                self.text = newText
                if self.isFirstResponder != true {
                    self.becomeFirstResponder()
                }
                self.selectedRange = NSRange(location: self.text.count - styling.endString.count, length: 0)
            }
        }
    }
    
    fileprivate func showLinkAlert(_ viewController: UIViewController?, title: String?, link: String?, selectedTextRange: UITextRange?) {
        let alertController = BeamAlertController(title: AWKLocalizedString("add-link"), message: AWKLocalizedString("add-link-message"), preferredStyle: UIAlertControllerStyle.alert)
        alertController.addTextField { (textField) in
            textField.text = title
            textField.placeholder = AWKLocalizedString("link-title-placeholder")
        }
        alertController.addTextField { (textField) in
            textField.text = link
            textField.placeholder = AWKLocalizedString("link-url-placeholder")
            textField.keyboardType = UIKeyboardType.URL
        }
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("add-link"), style: UIAlertActionStyle.default, handler: { (_) in
            self.applyLink(alertController.textFields![0].text, link: alertController.textFields![1].text, selectedTextRange: selectedTextRange)
        }))
        alertController.addCancelAction()
        (viewController ?? AppDelegate.topViewController())?.present(alertController, animated: true, completion: nil)
    }

}
