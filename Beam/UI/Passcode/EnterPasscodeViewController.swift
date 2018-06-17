//
//  EnterPasscodeViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 08-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import LocalAuthentication

enum PasscodeAction {
    case check
    case create
    case change
}

protocol EnterPasscodeViewControllerDelegate: class {
    
    func passcodeViewController(_ viewController: EnterPasscodeViewController, didCreateNewPasscode passcode: String)
    func passcodeViewController(_ viewController: EnterPasscodeViewController, didEnterPasscode passcode: String) -> Bool
    func passcodeViewControllerDidAuthenticateWithTouchID(_ viewController: EnterPasscodeViewController)
    func passcodeViewControllerDidCancel(_ viewController: EnterPasscodeViewController)
    
}

private enum EnterPasscodeViewControllerStep {
    case enter
    case reEnter
    case new
}

class EnterPasscodeViewController: BeamViewController {
    
    //The length of the passcode
    var passcodeLength: Int = 4
    
    //Delegate
    weak var delegate: EnterPasscodeViewControllerDelegate!
    
    //Function and steps
    var action = PasscodeAction.check
    fileprivate var step = EnterPasscodeViewControllerStep.enter {
        didSet {
            self.updateTitle()
        }
    }
    
    internal var appName: String {
        if let displayName = Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String {
            return displayName
        }
        return Bundle.main.infoDictionary!["CFBundleName"] as! String
    }
    
    //Strings for checking
    internal var enteredString: String?
    fileprivate var stringToCompare: String?
    
    //IBOutlets
    @IBOutlet var passcodeIndicators: [PasscodeIndicatorView]?
    @IBOutlet var keyboard: PasscodeKeyboard?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var indicatorsView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = AWKLocalizedString("enter-passcode-title")
        self.keyboard?.delegate = self
        
        self.updateIndicators()
        self.updateTitle()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(EnterPasscodeViewController.cancelTapped(_:)))
    }
    
    // MARK: - UI Updates
    
    fileprivate func updateIndicatorsTintColor(_ color: UIColor?) {
        guard self.passcodeIndicators != nil else {
            return
        }
        for indicator in self.passcodeIndicators! {
            indicator.tintColor = color
        }
    }
    
    fileprivate func updateTitle() {
        var title = AWKLocalizedString("enter-your-passcode")
        if self.action == PasscodeAction.create {
            title = AWKLocalizedString("enter-a-passcode")
        }
        if self.step == EnterPasscodeViewControllerStep.reEnter {
            title = AWKLocalizedString("re-enter-your-passcode")
        } else if self.step == EnterPasscodeViewControllerStep.new {
            title = AWKLocalizedString("enter-your-new-passcode")
            if self.action == PasscodeAction.create {
                title = AWKLocalizedString("enter-a-new-passcode")
            }
        }
        self.titleLabel?.text = title.replacingOccurrences(of: "[APPNAME]", with: self.appName)
    }
    
    internal func updateIndicators() {
        guard self.passcodeIndicators != nil else {
            return
        }
        let length = self.enteredString?.count ?? 0
        var index = 0
        for indicator in self.passcodeIndicators!.sorted( by: { $0.tag < $1.tag }) {
            indicator.filled = index < length ? true: false
            index += 1
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        //Reset most of the variable to there defaults here
        self.enteredString = nil
        self.stringToCompare = nil
        self.step = EnterPasscodeViewControllerStep.enter
        self.action = PasscodeAction.check
        self.updateIndicatorsTintColor(nil)
        self.updateIndicators()
        self.updateTitle()
    }
    
    // MARK: - Interface builder actions
    
    @IBAction func numberTapped(_ button: PasscodeButton) {
        self.addNumberToEnteredString(button.number)
    }
    
    @IBAction func deleteTapped(_ button: UIButton) {
        self.removeLastCharacterFromEnteredString()
    }
    
    @IBAction func cancelTapped(_ sender: AnyObject) {
        self.delegate.passcodeViewControllerDidCancel(self)
    }
    
    // MARK: - Entered string manipulation
    
    fileprivate func addNumberToEnteredString(_ number: Int) {
        self.enteredString = "\(self.enteredString ?? "")\(number)"
        self.updateIndicators()
        self.checkString()
    }
    
    fileprivate func removeLastCharacterFromEnteredString() {
        if self.enteredString != nil {
            if self.enteredString!.count <= 1 {
                self.enteredString = nil
            } else {
                self.enteredString?.removeLast()
            }
        }
        self.updateIndicators()
    }
    
    // MARK: - Passcode checks
    
    fileprivate func checkString() {
        if self.action == PasscodeAction.check {
            if self.enteredString != nil && self.enteredString?.count == self.passcodeLength {
                if !self.delegate.passcodeViewController(self, didEnterPasscode: self.enteredString!) {
                    //Show try again error
                    self.showPasscodeIncorrectError()
                }
            }
        } else if self.action == PasscodeAction.create {
            if self.enteredString != nil && self.enteredString?.count == self.passcodeLength && self.step == EnterPasscodeViewControllerStep.enter {
                //Prepare the view for re-enter
                self.stringToCompare = self.enteredString
                self.enteredString = nil
                self.step = EnterPasscodeViewControllerStep.reEnter
                self.updateIndicators()
            } else if self.enteredString != nil && self.enteredString?.count == self.passcodeLength && self.step == EnterPasscodeViewControllerStep.reEnter {
                if self.enteredString == self.stringToCompare {
                    self.delegate.passcodeViewController(self, didCreateNewPasscode: self.enteredString!)
                } else {
                    //Show try again error
                    self.showPasscodeIncorrectError()
                }
            }
        } else if self.action == PasscodeAction.change {
            if self.enteredString != nil && self.enteredString?.count == self.passcodeLength && self.step == EnterPasscodeViewControllerStep.enter {
                if !self.delegate.passcodeViewController(self, didEnterPasscode: self.enteredString!) {
                    //Show try again error
                    self.showPasscodeIncorrectError()
                } else {
                    //Prepare the view for new
                    self.step = EnterPasscodeViewControllerStep.new
                }
                
                self.enteredString = nil
                self.updateIndicators()
            } else if self.enteredString != nil && self.enteredString?.count == self.passcodeLength && self.step == EnterPasscodeViewControllerStep.new {
                self.stringToCompare = self.enteredString
                self.step = EnterPasscodeViewControllerStep.reEnter
                self.enteredString = nil
                self.updateIndicators()
            } else if self.enteredString != nil && self.enteredString?.count == self.passcodeLength && self.step == EnterPasscodeViewControllerStep.reEnter {
                if self.enteredString == self.stringToCompare {
                    self.delegate.passcodeViewController(self, didCreateNewPasscode: self.enteredString!)
                } else {
                    //Show try again error
                   self.showPasscodeIncorrectError()
                }
            }
        }
        
    }
    
    fileprivate func showPasscodeIncorrectError() {
        self.titleLabel?.text = AWKLocalizedString("passcode-try-again")
        
        if let indicatorsView = self.indicatorsView {
            let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            animation.duration = 0.6
            animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
            indicatorsView.layer.add(animation, forKey: "shake")
        }
        
        self.enteredString = nil
        self.updateIndicators()
    }
    
    // MARK: - Display Mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let tintColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        
        self.titleLabel?.textColor = tintColor
        self.view.tintColor = tintColor
        self.keyboard?.appearance = DisplayModeValue(UIKeyboardAppearance.default, darkValue: UIKeyboardAppearance.dark)
    }
}

extension EnterPasscodeViewController: BeamModalPresentation {

    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return (self is StartEnterPasscodeViewController) ? BeamModalPresentationStyle.custom: BeamModalPresentationStyle.formsheet
    }
}

// MARK: - PasscodeKeyboardDelegat
extension EnterPasscodeViewController: PasscodeKeyboardDelegate {
    
    func keyboard(_ keyboard: PasscodeKeyboard, didPressNumber number: Int) {
        self.addNumberToEnteredString(number)
    }
    
    func keyboard(_ keyboard: PasscodeKeyboard, didPressDelete deleteButton: DeleteButton) {
        self.removeLastCharacterFromEnteredString()
    }
}
