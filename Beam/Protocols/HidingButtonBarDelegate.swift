//
//  HidingButtonBar.swift
//  beam
//
//  Created by Robin Speijer on 31-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

protocol HidingButtonBarDelegate: class {
    // Implement in your code:
    var topButtonBarConstraint: NSLayoutConstraint! { get }
    var lastButtonBarScrollViewOffset: CGPoint? { get set }
    var lastScrollViewOffset: CGPoint? { get set }
    var lastScrollViewOffsetCapture: TimeInterval? { get set }
    
    // Implemented in extension:
    func buttonBarScrollViewDidScroll(_ scrollView: UIScrollView)
    func buttonBarScrollViewDidScrollToTop(_ scrollView: UIScrollView)
    
    var buttonBarVerticalOffset: CGFloat { get }
    func updateButtonBarVerticalOffset(_ offset: CGFloat)
    
    var topButtonBarOffset: CGFloat { get }
    
}

extension HidingButtonBarDelegate where Self: UIViewController {
    
    func buttonBarScrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollSpeedTreshold: CGFloat = 0.8
        
        let scrollSpeed: CGFloat = self.calculateSpeed(scrollView)
        
        let positiveTopContentInset: CGFloat = -1.0 * scrollView.contentInset.top
        let verticalContentOffsetWithTopInset: CGFloat = scrollView.contentOffset.y + scrollView.contentInset.top
        if scrollView.contentOffset.y >= positiveTopContentInset && scrollView.contentSize.height > scrollView.frame.height {
                
            var shouldHideOrShow: Bool = scrollSpeed > scrollSpeedTreshold && self.lastButtonBarScrollViewOffset == nil
            if !scrollView.isDragging && self.lastButtonBarScrollViewOffset == nil {
                shouldHideOrShow = false
            }
            if verticalContentOffsetWithTopInset - 44.0 <= 0.0 {
                shouldHideOrShow = true
            }
            if self.lastButtonBarScrollViewOffset != nil {
                shouldHideOrShow = true
            }
            if shouldHideOrShow {
                if self.lastButtonBarScrollViewOffset == nil {
                    self.lastButtonBarScrollViewOffset = self.lastScrollViewOffset
                }
                let offset: CGFloat!
                if let lastButtonBarScrollViewOffset: CGPoint = self.lastButtonBarScrollViewOffset {
                    offset = scrollView.contentOffset.y - lastButtonBarScrollViewOffset.y
                } else {
                    offset = scrollView.contentOffset.y - positiveTopContentInset
                }
                
                let oldConstant: CGFloat = self.buttonBarVerticalOffset
                let newConstant: CGFloat = min(max(oldConstant - offset, -44.0), 0.0)
                let minConstant: CGFloat = -1.0 * verticalContentOffsetWithTopInset
                let verticalOffset: CGFloat = max(newConstant, minConstant)
                
                self.updateButtonBarVerticalOffset(verticalOffset)
                
                if verticalOffset >= 0.0 || verticalOffset <= -44.0 {
                    self.updateButtonBarVerticalOffset(verticalOffset)
                    if self.lastButtonBarScrollViewOffset != nil {
                        self.lastButtonBarScrollViewOffset = nil
                    }
                }
            }
            
            self.lastScrollViewOffset = scrollView.contentOffset
            self.lastScrollViewOffsetCapture = Date.timeIntervalSinceReferenceDate
        }
        
    }
    
    /**
     This method calculates the speed by getting the offset between to scrolls. For the first time this will return 0.
     All requests after will return the speed as a positive number in pixels per milisecond.
     `self.lastScrollViewOffset` and `self.lastScrollViewOffsetCapture` are required to be set everytime `buttonBarScrollViewDidScroll:` is called.
     Otherwise the speed calculations won't work.
     */
    fileprivate func calculateSpeed(_ scrollView: UIScrollView) -> CGFloat {
        let currentOffset = scrollView.contentOffset
        let currentTime = Date.timeIntervalSinceReferenceDate
        if let lastOffset = self.lastScrollViewOffset, let lastOffsetCapture = self.lastScrollViewOffsetCapture {
            let timeDifference = currentTime - lastOffsetCapture
            if timeDifference > 0.01 {
                let distance = lastOffset.y - currentOffset.y
                let scrollSpeed = fabs((distance / CGFloat(timeDifference)) / 1000) //Scrollspeed in pixels per milisecond
                return scrollSpeed
            }
        }
        return 0
    }
    
    func buttonBarScrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            self.updateButtonBarVerticalOffset(0)
            (self.topButtonBarConstraint.firstItem as? UIView)?.layoutIfNeeded()
            }, completion: nil)
    }
    
    var buttonBarVerticalOffset: CGFloat {
        return self.topButtonBarConstraint.constant - self.topButtonBarOffset
    }
    
    func updateButtonBarVerticalOffset(_ offset: CGFloat) {
        self.topButtonBarConstraint.constant = offset + self.topButtonBarOffset
    }
    
    var topButtonBarOffset: CGFloat {
        return 0.0
    }
    
}
