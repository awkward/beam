//
//  ScrollableButtonBar.swift
//  Beam
//
//  Created by Rens Verhoeven on 13-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class ScrollableButtonBar: BeamControl {
    
    var items: [String]? {
        didSet {
            self.configureContents()
        }
    }
    
    var selectedItemIndex: Int? {
        didSet {
            self.updateButtonColors()
        }
    }
    
    func updateSelectedItemIndex(_ index: Int?) {
        self.selectedItemIndex = index
        self.sendActions(for: [UIControlEvents.valueChanged])
    }
    
    fileprivate let firstLastSpacing: CGFloat = 15
    
    fileprivate var buttons = [UIButton]()
    fileprivate var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollsToTop = false
        return scrollView
    }()
    
    lazy fileprivate var maskLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear, UIColor.clear, UIColor.black, UIColor.black, UIColor.clear, UIColor.clear].map({ $0.cgColor })
        layer.locations = [0, 0.1, 0.2, 0.7, 0.8, 1]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.addSubview(self.scrollView)
        self.layer.mask = self.maskLayer
        
        //Add horizontal constraints to make the view center with a max width
        self.scrollView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(greaterThanOrEqualTo: self.scrollView.trailingAnchor).isActive = true
        self.scrollView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.scrollView.widthAnchor.constraint(lessThanOrEqualToConstant: UIView.MaximumViewportWidth).isActive = true
        
        //Limit the actual width, but give it a lower priority (750) so that it can be smaller if it needs to be (on iPhone for example)
        let widthConstraint = self.scrollView.widthAnchor.constraint(equalToConstant: UIView.MaximumViewportWidth)
        widthConstraint.priority = UILayoutPriority.defaultHigh
        widthConstraint.isActive = true
        
        //Add the vertical constraints to fill the view
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: ["scrollView": self.scrollView]))
        
        self.setNeedsLayout()
    }
    
    fileprivate func configureContents() {
        for button in self.buttons {
            button.removeFromSuperview()
            button.removeTarget(nil, action: nil, for: UIControlEvents.allEvents)
        }
        self.buttons.removeAll()
        if let items = self.items {
            for item in items {
                let button = UIButton(type: UIButtonType.system)
                button.setTitle(item, for: UIControlState())
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
                button.addTarget(self, action: #selector(ScrollableButtonBar.buttonTapped(_:)), for: UIControlEvents.touchUpInside)
                self.scrollView.addSubview(button)
    
                self.buttons.append(button)
            }
        }
        
        self.updateButtonColors()
        self.layoutButtons()
        
    }
    
    fileprivate func updateButtonColors() {
        var index = 0
        for button in self.buttons {
            if index == self.selectedItemIndex {
                button.setTitleColor(self.tintColor, for: UIControlState())
            } else {
                let titleColor = DisplayModeValue(UIColor(red: 125 / 255, green: 125 / 255, blue: 125 / 255, alpha: 1), darkValue: UIColor(red: 151 / 255, green: 151 / 255, blue: 151 / 255, alpha: 1))
                button.setTitleColor(titleColor, for: UIControlState())
            }
            index += 1
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.updateButtonColors()
    }
    
    fileprivate func layoutButtons(_ sideSpacing: CGFloat = 20, secondLayoutRound: Bool = false) {
        var index = 0
        
        //The first button has to have special spacing to the begining of the text
        var xPosition: CGFloat = self.firstLastSpacing - sideSpacing
        
        for button in self.buttons {
            var buttonSize = button.intrinsicContentSize
            //We use the size of the titleLabel when available, because sometimes the button adds extra on the sides
            if let titleLabel = button.titleLabel {
                buttonSize = titleLabel.intrinsicContentSize
                buttonSize.width += sideSpacing * 2
                
            }
            //Make all buttons full height
            buttonSize.height = self.bounds.height
            
            button.frame = CGRect(origin: CGPoint(x: xPosition, y: 0), size: buttonSize)
            
            xPosition += buttonSize.width
            
            index += 1
        }
        
        //The last button also has only 12 point of spacing from the side to the title
        xPosition -= sideSpacing - self.firstLastSpacing
        
        if xPosition <= self.scrollView.frame.width && !secondLayoutRound {
            //The scrollview won't have to scroll, so realign all buttons so they are centered.
            var totalButtonWidth: CGFloat = 0
            for button in self.buttons {
                var buttonSize = button.intrinsicContentSize
                //We use the size of the titleLabel when available, because sometimes the button adds extra on the sides
                if let titleLabel = button.titleLabel {
                    buttonSize = titleLabel.intrinsicContentSize
                }
                
                totalButtonWidth += buttonSize.width
            }
            let emptySpace = (self.scrollView.frame.width - totalButtonWidth)
            let sideSpace: CGFloat = round((emptySpace / CGFloat(self.buttons.count)) / 2)
            self.layoutButtons(sideSpace, secondLayoutRound: true)
        }
        
        self.scrollView.contentSize = CGSize(width: xPosition, height: self.bounds.height)
    }
    
    @objc fileprivate func buttonTapped(_ sender: UIButton) {
        let index = self.buttons.index(of: sender)
        self.updateSelectedItemIndex(index)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var spacing: CGFloat = 22
        if self.traitCollection.horizontalSizeClass == .regular {
            spacing = 22
        } else if self.frame.width > 375 {
            spacing = 18
        } else if self.frame.width > 320 {
            spacing = 20
        }
        self.layoutButtons(spacing)
        
        let gradientLength: CGFloat = 16
        let gradientEnd = self.firstLastSpacing + 4
        var locations = [NSNumber]()
        locations.append(NSNumber(value: 0))
        locations.append(NSNumber(value: Float((gradientEnd - gradientLength) / self.bounds.width)))
        locations.append(NSNumber(value: Float(gradientEnd / self.bounds.width)))
        locations.append(NSNumber(value: Float((self.bounds.width - gradientEnd) / self.bounds.width)))
        locations.append(NSNumber(value: Float((self.bounds.width - (gradientEnd - gradientLength)) / self.bounds.width)))
        locations.append(NSNumber(value: 1))
        
        self.maskLayer.frame = self.bounds
        self.maskLayer.setNeedsDisplay()
        self.maskLayer.locations = locations
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 30)
    }
    
    func buttonFrameForSelectedItemIndex() -> CGRect? {
        guard let index = self.selectedItemIndex, index < buttons.count && index > 0 else {
            return nil
        }
        let button = self.buttons[index]
        return self.scrollView.convert(button.frame, to: self)
    }
    
}
