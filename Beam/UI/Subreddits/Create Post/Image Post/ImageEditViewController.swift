//
//  ImageEditViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 04-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Photos

final class ImageEditBottomview: BeamView {
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let seperatorColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
        let topSeperatorPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: rect.width, height: 1 / UIScreen.main.scale))
        seperatorColor.setFill()
        topSeperatorPath.fill()
        
        let middleSeperatorPath = UIBezierPath(rect: CGRect(x: self.layoutMargins.left, y: 48, width: rect.width - self.layoutMargins.left, height: 1 / UIScreen.main.scale))
        seperatorColor.setFill()
        middleSeperatorPath.fill()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }
}

protocol ImageEditViewControllerDelegate: class {
    
    func editViewController(_ editViewController: ImageEditViewController, didTapRemoveOnImage image: ImageAsset)
    
}

class ImageEditViewController: BeamViewController {
    
    weak var delegate: ImageEditViewControllerDelegate?
    var allImages: [ImageAsset]?
    var currentImage: ImageAsset? {
        set {
            self.privateCurrentImage = newValue
        }
        get {
            return self.privateCurrentImage
        }
    }
    fileprivate var privateCurrentImage: ImageAsset? {
        didSet {
            self.updateTextFields()
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var descriptionTextViewPlaceholder: UILabel!
    @IBOutlet var descriptionTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var bottomViewBottomConstraint: NSLayoutConstraint!
    
    var scrolledToCurrentItem = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let removeItem = UIBarButtonItem(title: AWKLocalizedString("remove-button"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(ImageEditViewController.removeTapped(_:)))
        removeItem.tintColor = DisplayModeValue(UIColor.beamRed(), darkValue: UIColor.beamRedDarker())
        self.navigationItem.leftBarButtonItem = removeItem
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(ImageEditViewController.doneTapped(_:)))
        self.navigationItem.title = AWKLocalizedString("edit-image-title")
        
        NotificationCenter.default.addObserver(self, selector: #selector(ImageEditViewController.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)

        self.titleTextField.delegate = self
        self.descriptionTextViewPlaceholder.text = AWKLocalizedString("image-description-placeholder")
        self.descriptionTextView.delegate = self
        self.descriptionTextView.contentInset = UIEdgeInsets.zero
        self.descriptionTextView.textContainerInset = UIEdgeInsets()
        self.descriptionTextView.textContainer.lineFragmentPadding = 0
        self.descriptionTextView.isScrollEnabled = false
        self.descriptionTextView.scrollsToTop = false
        
        self.updateCollectionViewLayout()
        self.updateTextFields()
    }
    
    fileprivate func updateCollectionViewLayout() {
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = self.collectionView.frame.size
            layout.sectionInset = UIEdgeInsets.zero
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.invalidateLayout()
            NSLog("Invalidating layout")
        }
    }
    
    @objc fileprivate func removeTapped(_ sender: UIBarButtonItem) {
        self.updateTitleOfCurrentImage()
        if let currentImage = self.currentImage, let delegate = self.delegate {
            let alertController = BeamAlertController(title: AWKLocalizedString("remove-this-image"), message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            alertController.addCancelAction()
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("remove-button"), style: UIAlertActionStyle.destructive, handler: { (_) in
                delegate.editViewController(self, didTapRemoveOnImage: currentImage)
                self.dismiss(animated: true, completion: nil)
            }))
            
            alertController.popoverPresentationController?.barButtonItem = sender
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func doneTapped(_ sender: AnyObject) {
        self.updateTitleOfCurrentImage()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if (self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize != self.collectionView.frame.size {
            self.updateCollectionViewLayout()
            //Scroll to current item
            if let currentImage = self.currentImage, let index = self.allImages?.index(of: currentImage), self.scrolledToCurrentItem == false {
                self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
                self.scrolledToCurrentItem = true
            }
        }
        
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        let backgroundColor = DisplayModeValue(UIColor.beamBackground(), darkValue: UIColor.beamDarkBackgroundColor())
        self.view.backgroundColor = backgroundColor
        self.collectionView.backgroundColor = backgroundColor
        
        self.descriptionTextView.backgroundColor = UIColor.clear
        self.descriptionTextView.isOpaque = false
        
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.titleTextField.textColor = textColor
        self.descriptionTextView.textColor = textColor
        
        let keyboardAppearance = DisplayModeValue(UIKeyboardAppearance.default, darkValue: UIKeyboardAppearance.dark)
        self.titleTextField.keyboardAppearance = keyboardAppearance
        self.descriptionTextView.keyboardAppearance = keyboardAppearance
        
        let placeholderColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        self.titleTextField.attributedPlaceholder = NSAttributedString(string: AWKLocalizedString("image-title-placeholder"), attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        self.descriptionTextViewPlaceholder.textColor = placeholderColor
    }
    
    func updateTitleOfCurrentImage() {
        if let image = self.currentImage {
            image.imageTitle = self.titleTextField.text
            image.imageDescription = self.descriptionTextView.text
        }
    }
    
    func updateTextFields() {
        self.titleTextField?.text = self.currentImage?.imageTitle
        self.descriptionTextView?.text = self.currentImage?.imageDescription
        self.descriptionTextViewPlaceholder?.isHidden = self.descriptionTextView?.text.count ?? 0 > 0
        if self.descriptionTextView != nil {
            self.sizeTextView()
        }
    }
    
    func sizeTextView() {
        let minimumHeight: CGFloat = 42
        self.descriptionTextViewHeightConstraint.constant = max(self.descriptionTextView.sizeThatFits(CGSize(width: self.descriptionTextView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height, minimumHeight)
        self.view.layoutIfNeeded()
    }

    @objc fileprivate func keyboardWillChangeFrame(_ notification: Notification) {
        let frame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = ((notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as? NSNumber ?? NSNumber(value: 0 as Double)).doubleValue
        var animationCurveOption: UIViewAnimationOptions = UIViewAnimationOptions()
        if (notification as NSNotification).userInfo?[UIKeyboardAnimationCurveUserInfoKey] != nil {
            ((notification as NSNotification).userInfo![UIKeyboardAnimationCurveUserInfoKey]! as AnyObject).getValue(&animationCurveOption)
        }
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurveOption, animations: {
            //ANIMATE
            let bottomInset: CGFloat = self.view.bounds.height - frame.minY
            self.bottomViewBottomConstraint?.constant = bottomInset
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
}

extension ImageEditViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allImages?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let image = self.allImages![(indexPath as IndexPath).row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image-cell", for: indexPath) as! ImageAssetCollectionViewCell
        cell.imageAsset = image
        cell.reloadContents(self.view.bounds.size, contentMode: PHImageContentMode.aspectFit, imageManager: PHImageManager.default())
        return cell
    }
}

extension ImageEditViewController: UICollectionViewDelegateFlowLayout {
    
}

extension ImageEditViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.collectionView else {
            return
        }
        let pageWidth: CGFloat = self.collectionView.frame.width
        let index = Int(floor((self.collectionView.contentOffset.x - (pageWidth / 2)) / pageWidth)) + 1
        guard let images = self.allImages, index >= 0 && index < images.count && images.count > 0 else {
            return
        }
        let newImage = images[index]
        if self.privateCurrentImage != newImage {
            self.updateTitleOfCurrentImage()
            self.privateCurrentImage = newImage
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.descriptionTextView.resignFirstResponder()
        self.titleTextField.resignFirstResponder()
    }
}

extension ImageEditViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.titleTextField {
            self.descriptionTextView.becomeFirstResponder()
        } else if textField == self.descriptionTextView {
            self.descriptionTextView.resignFirstResponder()
        }
        return false
    }
    
}

extension ImageEditViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        self.descriptionTextViewPlaceholder.isHidden = textView.text.count > 0
        self.sizeTextView()
    }
}
