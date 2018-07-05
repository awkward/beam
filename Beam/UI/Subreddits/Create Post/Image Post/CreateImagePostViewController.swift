//
//  CreateImagePostViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import Photos
import AssetsPickerController
import ImgurKit

class ImageAsset: NSObject {
    let asset: PHAsset
    var imageTitle: String?
    var imageDescription: String?
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherAsset = object as? ImageAsset else {
            return false
        }
        return otherAsset.asset.localIdentifier == self.asset.localIdentifier
    }
}
func == (lhs: ImageAsset, rhs: ImageAsset) -> Bool {
    return lhs.asset.localIdentifier == rhs.asset.localIdentifier
}

enum CreateImagePostViewControllerState {
    case uploadingImages
    case creatingAlbum
    case submitting
    
    var viewTitle: String {
        switch self {
        case .uploadingImages:
            return AWKLocalizedString("image-post-state-uploading")
        case .creatingAlbum:
            return AWKLocalizedString("image-post-state-creating-album")
        case .submitting:
            return AWKLocalizedString("image-post-state-submitting")
        }
    }
}

class CreateImagePostViewController: CreatePostViewController {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var collectionViewHeader: UICollectionReusableView!
    
    var titleTextField: UITextField?
    var descriptionTextField: UITextField?
    
    @IBOutlet var imagesNoticeView: UIView!
    @IBOutlet var imagesNoticeLabel: UILabel!
    @IBOutlet var imagesNoticeViewBottomConstraint: NSLayoutConstraint!
    
    var keyboardHeight: CGFloat = 0
    
    fileprivate var state: CreateImagePostViewControllerState? {
        didSet {
            DispatchQueue.main.async {
                if self.state == nil && oldValue != nil {
                    self.updateProgressBar(0)
                }
                self.lockView(self.state != nil)
                self.updateSubmitStatus()
                self.updateTitle()
            }
        }
    }
    
    fileprivate var images = [ImageAsset]() {
        didSet {
            self.updatePlaceholders()
            self.updateTitle()
        }
    }
    
    fileprivate var imageManager = PHImageManager.default()
    
    fileprivate var thumbnailImageSize = CGSize(width: 100, height: 100)
    
    fileprivate var longPressGestureRecognier: UILongPressGestureRecognizer!
    
    fileprivate var link: URL!
    
    fileprivate var uploadedImages = [String: ImgurImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.collectionViewLayout = ImagesCollectionViewFlowLayout()
        
        self.createTextFields()
        
        self.longPressGestureRecognier = UILongPressGestureRecognizer(target: self, action: #selector(CreateImagePostViewController.handleLongPressGestureRecognizer(_:)))
        self.collectionView.addGestureRecognizer(longPressGestureRecognier)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.updateCollectionViewInsets()
        
        self.updateTitle()
        
        self.imagesNoticeLabel.text = AWKLocalizedString("images-uploaded-notice")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.titleTextField?.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.titleTextField?.resignFirstResponder()
        self.descriptionTextField?.resignFirstResponder()
    }
    
    fileprivate func updateTitle(_ requestNumber: Int = 0, totalRequests: Int = 0) {
        if let state = self.state {
            if requestNumber > 0 && totalRequests > 0 {
                self.navigationItem.title = AWKLocalizedString("image-post-state-uploading-count").replacingOccurrences(of: "[NUMBER]", with: "\(requestNumber)").replacingOccurrences(of: "[TOTAL]", with: "\(totalRequests)")
            } else {
                self.navigationItem.title = state.viewTitle
            }
        } else {
            if self.images.count > 1 {
                self.navigationItem.title = AWKLocalizedString("album-post-title")
            } else {
                self.navigationItem.title = AWKLocalizedString("image-post-title")
            }
            
        }
    }
    
    fileprivate func createTextFields() {
        self.titleTextField = UITextField()
        self.titleTextField?.font = UIFont.systemFont(ofSize: 17)
        self.titleTextField?.autocapitalizationType = UITextAutocapitalizationType.sentences
        self.titleTextField?.delegate = self
        
        self.descriptionTextField = UITextField()
        self.descriptionTextField?.font = UIFont.systemFont(ofSize: 17)
        self.descriptionTextField?.autocapitalizationType = UITextAutocapitalizationType.sentences
    }
    
    fileprivate func showAssetsPickerController() {
        self.titleTextField?.resignFirstResponder()
        self.descriptionTextField?.resignFirstResponder()
        
        let colorPalette = AssetsPickerColorPalette()
        colorPalette.statusBarStyle = DisplayModeValue(UIStatusBarStyle.default, darkValue: UIStatusBarStyle.lightContent)
        colorPalette.tintColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        colorPalette.titleColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        colorPalette.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkBackgroundColor())
        colorPalette.albumTitleColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        colorPalette.albumCountColor = colorPalette.albumTitleColor
        colorPalette.albumLinesColor = colorPalette.albumTitleColor
        colorPalette.cameraIconColor = DisplayModeValue(UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00), darkValue: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1))
        colorPalette.albumCellBackgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        colorPalette.albumCellSelectedBackgroundColor = DisplayModeValue(UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.00), darkValue: UIColor.white)
        
        let pickerController = AssetsPickerController()
        pickerController.mediaTypes = [PHAssetMediaType.image]
        pickerController.defaultAlbum = AssetsPickerControllerAlbumType.allPhotos
        pickerController.delegate = self
        pickerController.multipleSelection = true
        pickerController.showCameraOption = true
        pickerController.colorPalette = colorPalette
        let navigationController = pickerController.createNavigationController(BeamNavigationBar.self, toolbarClass: nil)
        self.showDetailViewController(navigationController, sender: self)
    }

    fileprivate func imageForIndexPath(_ indexPath: IndexPath) -> ImageAsset? {
        guard self.images.count != 0 else {
            return nil
        }
        guard (indexPath as IndexPath).item < self.images.count else {
            return nil
        }
        return self.images[(indexPath as IndexPath).item]
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.collectionView.backgroundColor = backgroundColor
        
        self.imagesNoticeView.backgroundColor = backgroundColor
        self.imagesNoticeLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.titleTextField?.textColor = textColor
        self.descriptionTextField?.textColor = textColor
        
        let keyboardAppearance = DisplayModeValue(UIKeyboardAppearance.default, darkValue: UIKeyboardAppearance.dark)
        self.titleTextField?.keyboardAppearance = keyboardAppearance
        self.descriptionTextField?.keyboardAppearance = keyboardAppearance
        
        self.updatePlaceholders()
    }
    
    func updatePlaceholders() {
        let placeholderColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        self.titleTextField?.attributedPlaceholder = NSAttributedString(string: self.images.count > 1 ? AWKLocalizedString("album-title-placeholder") : AWKLocalizedString("post-title-placeholder"), attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        self.descriptionTextField?.attributedPlaceholder = NSAttributedString(string: AWKLocalizedString("album-description-placeholder"), attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateCollectionViewLayout()
    }
    
    fileprivate func updateCollectionViewLayout() {
        var numberOfColumns: CGFloat = 3
        if self.view.frame.width >= 480 {
            numberOfColumns = 7
        }
        let spacing: CGFloat = 1
        var totalSpacing: CGFloat = numberOfColumns * spacing
        totalSpacing -= spacing
        let viewWidthWithoutSpacing: CGFloat = self.view.frame.width - totalSpacing
        var cellWidth = viewWidthWithoutSpacing / numberOfColumns
        cellWidth = floor(cellWidth)
        if let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            self.thumbnailImageSize = CGSize(width: cellWidth, height: cellWidth)
            flowLayout.itemSize = self.thumbnailImageSize
            flowLayout.minimumInteritemSpacing = spacing
            flowLayout.minimumLineSpacing = spacing
            flowLayout.sectionInset = UIEdgeInsets.zero
        }
        self.updateCollectionViewInsets()
    }
    
    fileprivate func updateCollectionViewInsets() {
        let bottomInset: CGFloat = self.keyboardHeight + 35
        let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        self.collectionView.contentInset = insets
        self.collectionView.scrollIndicatorInsets = insets
    }
    
    // MARK: - Long press gesture recognizer
    
    @objc fileprivate func handleLongPressGestureRecognizer(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.began:
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gestureRecognizer.location(in: self.collectionView)) else {
                break
            }
            if self.collectionView.beginInteractiveMovementForItem(at: selectedIndexPath) {
                UIView.animate(withDuration: 0.20, delay: 0, usingSpringWithDamping: 0.70, initialSpringVelocity: 0.05, options: [], animations: {
                    self.collectionView.updateInteractiveMovementTargetPosition(gestureRecognizer.location(in: gestureRecognizer.view!))
                    }, completion: nil)
            }
        case UIGestureRecognizerState.changed:
            self.collectionView.updateInteractiveMovementTargetPosition(gestureRecognizer.location(in: gestureRecognizer.view!))
        case UIGestureRecognizerState.ended:
            self.collectionView.endInteractiveMovement()
        default:
            self.collectionView.cancelInteractiveMovement()
        }
    }
    
    // MARK: - Actions
    
    override func submitTapped(_ sender: AnyObject) {
        guard self.images.count > 0 else {
            return
        }
        //Don't call super, we first need to uplaod the album!
        if self.uploadedImages.count < self.images.count {
            self.state = CreateImagePostViewControllerState.uploadingImages
            self.uploadImages { (imgurImages, errors) in
                if let imgurImages = imgurImages {
                    if self.uploadedImages.count == 0 {
                        self.uploadedImages = imgurImages
                    } else {
                        imgurImages.forEach({ (info) in
                            guard self.uploadedImages[info.key] == nil else {
                                return
                            }
                            self.uploadedImages[info.key] = info.value
                        })
                    }
                }
                let allUploadedImages = Array(self.uploadedImages.values)
                self.saveUploadedImgurObjects(allUploadedImages)
                if let firstError = errors?.first {
                    DispatchQueue.main.async(execute: {
                        self.handleError(firstError)
                    })
                    self.state = nil
                } else {
                    if self.images.count == 1 {
                        DispatchQueue.main.async(execute: {
                            //Get the first image
                            self.submitImage(imgurImages!.first!.1)
                        })
                    } else {
                        self.createAlbum()
                    }
                    NSLog("Completed image uploads \(String(describing: imgurImages))")
                }
            }
        } else {
            if self.images.count == 1 {
                DispatchQueue.main.async(execute: {
                    //Get the first image
                    self.submitImage(self.uploadedImages.first!.1)
                })
            } else {
                self.createAlbum()
            }
        }
        
    }
    
    // MARK: - Image uploading
    
    fileprivate func uploadImages(_ completionHandler: @escaping ((_ imgurImages: [String: ImgurImage]?, _ errors: [NSError]?) -> Void)) {
        guard self.images.count > 0 else {
            completionHandler(nil, [NSError.beamError(400, localizedDescription: "No images specified")])
            return
        }
        self.updateProgressBar(0)
        let requests = self.requestsForImageUploads(widthImages: self.images)
        AppDelegate.shared.imgurController.executeRequests(requests, uploadProgressHandler: { (requestNumber, totalProgress) in
            DispatchQueue.main.async(execute: {
                self.updateTitle(requestNumber, totalRequests: requests.count)
                self.updateProgressBar(totalProgress)
            })
        }, completionHandler: { (error) in
            let imageRequests = requests.filter({ $0 is ImgurImageUploadRequest }) as! [ImgurImageUploadRequest]
            //Asset Identifier: ImgurIdentifier
            var imageUploadErrors = [NSError]()
            var imgurImages = [String: ImgurImage]()
            for request in imageRequests {
                if let image = request.resultObject as? ImgurImage {
                    //Set the image identifiers per asset localidentifier so we can easily sort them
                    imgurImages[request.asset!.localIdentifier] = image
                    NSLog("Completed imgur upload result \(image.URL)")
                } else {
                    //If no image is available, an error will be available
                    imageUploadErrors.append(request.error!)
                }
            }
            completionHandler(imgurImages, imageUploadErrors)
        })
    }
    
    fileprivate func requestsForImageUploads(widthImages images: [ImageAsset]) -> [ImgurRequest] {
        var requests = [ImgurRequest]()
        
        for image in images {
            let imageRequest = ImgurImageUploadRequest(asset: image.asset)
            if images.count == 1 {
                imageRequest.imageTitle = self.titleTextField?.text
                imageRequest.imageDescription = self.descriptionTextField?.text
            }
            if let title = image.imageTitle {
                imageRequest.imageTitle = title
            }
            if let description = image.imageDescription {
                imageRequest.imageDescription = description
            }
            requests.append(imageRequest)
        }
        
        return requests
    }
    
    fileprivate func updateProgressBar(_ progress: CGFloat) {
        if let navigationController = self.navigationController as? BeamNavigationController, let navigationBar = navigationController.navigationBar as? BeamNavigationBar {
            navigationBar.showProgressView = true
            navigationBar.updateProgress(progress, animated: false)
        }
    }
    
    // MARK: - Uploaded images
    
    fileprivate func saveUploadedImgurObjects(_ objects: [ImgurObject]) {
        var savedImgurObjects = [ImgurObject]()
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = documentsPath + "/imgur-uploads.plist"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)), let objects = NSKeyedUnarchiver.unarchiveObject(with: data) as? Set<ImgurObject> {
            savedImgurObjects.append(contentsOf: objects)
        } else if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)), let objects = NSKeyedUnarchiver.unarchiveObject(with: data) as? [ImgurObject] {
            savedImgurObjects.append(contentsOf: objects)
        }
        for uploadedObject in objects {
            if !savedImgurObjects.contains(uploadedObject) {
                savedImgurObjects.append(uploadedObject)
            }
        }
        
        if NSKeyedArchiver.archiveRootObject(savedImgurObjects, toFile: filePath) {
            print("Saved uploads")
        } else {
            print("Failed to save uploads")
        }
    }
    
    // MARK: - Album creation
    
    fileprivate func createAlbum() {
        guard self.uploadedImages.count > 0 else {
            self.state = nil
            return
        }
        self.state = CreateImagePostViewControllerState.creatingAlbum
        //Loop through the original images because the have the correct order
        var imageDeleteHashes = [String]()
        var albumImages = [ImgurImage]()
        for image in self.images {
            if let imgurImage = self.uploadedImages[image.asset.localIdentifier], let imageDeleteHash = imgurImage.deleteHash {
                imageDeleteHashes.append(imageDeleteHash)
                albumImages.append(imgurImage)
            }
        }
        
        NSLog("Creating album with image identifiers \(imageDeleteHashes)")
        
        let request = ImgurAlbumRequest(createRequestWithTitle: self.titleTextField?.text, description: self.descriptionTextField?.text)
        request.imageDeleteHashes = imageDeleteHashes
        AppDelegate.shared.imgurController.executeRequests([request], uploadProgressHandler: nil, completionHandler: { (error) in
            DispatchQueue.main.async(execute: {
                if let album = request.resultObject as? ImgurAlbum {
                    album.images = albumImages
                    self.saveUploadedImgurObjects([album])
                    self.submitAlbum(album)
                } else {
                    if let error = error {
                        self.handleError(error)
                    }
                }
            })
        })
    }
    
    // MARK: - Submitting
    
    fileprivate func submitImage(_ image: ImgurImage) {
        self.state = CreateImagePostViewControllerState.submitting
        //Get the first imgur image
        self.link = image.URL
        super.submitTapped(image)
    }
    
    fileprivate func submitAlbum(_ album: ImgurAlbum) {
        self.state = CreateImagePostViewControllerState.submitting
        //Get the first imgur image
        self.link = album.URL
        super.submitTapped(album)
    }
    
    // MARK: Notifications
    
    override func keyboardDidChangeFrame(_ frame: CGRect, animationDuration: TimeInterval, animationCurveOption: UIViewAnimationOptions) {
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurveOption, animations: {
            //ANIMATE
            
            let bottomInset: CGFloat = max(self.view.bounds.height - frame.minY, 0)
            self.keyboardHeight = bottomInset
            self.updateCollectionViewInsets()
            self.imagesNoticeViewBottomConstraint.constant = self.keyboardHeight
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: CreatePostViewController properties and functions
    
    override var canSubmit: Bool {
        guard isViewLoaded else {
            return false
        }
        guard let title = self.titleTextField?.text else {
            return false
        }
        return self.subreddit != nil && title.count > 0 && self.images.count > 0 && self.state == nil
    }
    
    override var hasContent: Bool {
        let title = self.titleTextField?.text ?? ""
        let description = self.descriptionTextField?.text ?? ""
        return title.count > 0 || description.count > 0 || self.images.count > 0
    }
    
    override internal var postKind: RedditSubmitKind {
        return RedditSubmitKind.link(self.link)
    }
    
    override internal var postTitle: String {
        return self.titleTextField?.text ?? ""
    }
    
    override func didStartSubmit() {
        self.lockView(true)
    }
    
    override func didFinishSubmit(_ error: Error?, cancelled: Bool) {
        if error != nil || cancelled {
            self.state = nil
        }
        super.didFinishSubmit(error, cancelled: cancelled)
    }
    
    override func lockView(_ locked: Bool) {
        super.lockView(locked)
        let alpha: CGFloat = locked ? 0.5: 1.0
        self.collectionView.isUserInteractionEnabled = !locked
        self.collectionView.alpha = alpha
        self.titleTextField?.isEnabled = !locked
        self.titleTextField?.alpha = alpha
        self.descriptionTextField?.isEnabled = !locked
        self.descriptionTextField?.alpha = alpha
        if locked {
            self.titleTextField?.resignFirstResponder()
            self.descriptionTextField?.resignFirstResponder()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? BeamNavigationController,
            let editViewController = navigationController.topViewController as? ImageEditViewController,
        let cell = sender as? UICollectionViewCell,
        let indexPath = self.collectionView.indexPath(for: cell) {
            editViewController.delegate = self
            editViewController.allImages = self.images
            editViewController.currentImage = self.imageForIndexPath(indexPath)
        }
    }
    
}

extension CreateImagePostViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.imageForIndexPath(indexPath) == nil {
           self.showAssetsPickerController()
        }
    }
    
    @objc(collectionView: canFocusItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return self.imageForIndexPath(indexPath) != nil
    }
    
    @objc(collectionView: moveItemAtIndexPath:toIndexPath:) func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let image = self.imageForIndexPath(sourceIndexPath), let sourceIndex = self.images.index(of: image) {
            let destinationIndex = (destinationIndexPath as IndexPath).item
            self.images.remove(at: sourceIndex)
            self.images.insert(image, at: destinationIndex)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        return self.targetIndexPath(proposedIndexPath)
    }

    func targetIndexPath(_ proposedIndexPath: IndexPath) -> IndexPath {
        if self.imageForIndexPath(proposedIndexPath) != nil {
            return proposedIndexPath
        } else {
            return self.targetIndexPath(IndexPath(item: (proposedIndexPath as IndexPath).item - 1, section: 0))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.bounds.width, height: 90)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let headerView = view as? ImagePostCollectionHeaderView {
            headerView.titleTextField = self.titleTextField
            headerView.descriptionTextField = self.descriptionTextField
        }
    }
    
}

extension CreateImagePostViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let image = self.imageForIndexPath(indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image-cell", for: indexPath) as! ImageAssetCollectionViewCell
            cell.imageAsset = image
            cell.delegate = self
            cell.reloadContents(self.thumbnailImageSize, contentMode: PHImageContentMode.aspectFill, imageManager: self.imageManager)
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "add-cell", for: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header-view", for: indexPath) as! ImagePostCollectionHeaderView
        return headerView
    }
}

extension CreateImagePostViewController: ImageAssetCollectionViewCellDelegate {
    
    func imageAssetCell(didTapRemoveOnCell cell: ImageAssetCollectionViewCell, image: ImageAsset) {
        if let index = self.images.index(of: image) {
            self.images.remove(at: index)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                }, completion: nil)
        }
    }
}

extension CreateImagePostViewController: AssetsPickerControllerDelegate {
    
    func assetsPickerController(_ assetsPickerController: AssetsPickerController, navigationController: UINavigationController, didSelectAssets assets: [PHAsset]) {
        navigationController.dismiss(animated: true, completion: nil)
        
        var newImages = [ImageAsset]()
        for asset in assets {
            let imageAsset = ImageAsset(asset: asset)
            if !self.images.contains(imageAsset) {
                newImages.append(imageAsset)
            }
        }
        self.images.append(contentsOf: newImages)
        
        var newIndexes = [IndexPath]()
        for image in newImages {
            if let index = self.images.index(of: image) {
                newIndexes.append(IndexPath(item: index, section: 0))
            }
        }
        
        if newIndexes.count == newImages.count && newIndexes.count > 0 {
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: newIndexes)
                }, completion: nil)
        } else {
            self.collectionView.reloadData()
        }
        
        self.updateSubmitStatus()
    }
    
    func assetsPickerControllerDidCancel(_ assetsPickerController: AssetsPickerController, navigationController: UINavigationController) {
        navigationController.dismiss(animated: true, completion: nil)
    }

    func assetsPickerController(_ assetsPickerController: AssetsPickerController, viewForAuthorizationStatus: PHAuthorizationStatus) -> UIView? {
        if viewForAuthorizationStatus == .notDetermined {
            return nil
        } else {
            return UINib(nibName: "AssetsPickerControllerAuthorizationEmptyView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView
        }
    }
    
    func assetsPickerController(_ assetsPickerController: AssetsPickerController, emptyViewForAlbum: String) -> UIView? {
        return UINib(nibName: "AssetsPickerControllerAlbumEmptyView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView
    }
    
}

extension CreateImagePostViewController: ImageEditViewControllerDelegate {
    
    func editViewController(_ editViewController: ImageEditViewController, didTapRemoveOnImage image: ImageAsset) {
        if let index = self.images.index(of: image) {
            self.images.remove(at: index)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                }, completion: nil)
        }
    }
}

extension CreateImagePostViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 300
    }
    
}
