//
//  StreamAlbumView.swift
//  Beam
//
//  Created by Rens Verhoeven on 09-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SDWebImage

protocol StreamAlbumViewDelegate: class {
    
    func albumView(_ collectionView: StreamAlbumView, didTapItemView itemView: StreamAlbumItemView, atIndex index: Int)
}

final class StreamAlbumView: UIView {
    
    /// MARK: - Public Properties
    var mediaObjects: [MediaObject]? {
        didSet {
            self.updateContents()
        }
    }
    
    var shouldShowNSFWOverlay: Bool = true {
        didSet {
            if self.shouldShowNSFWOverlay != oldValue {
                let itemViews = self.allItemViews
                for itemView in itemViews {
                    itemView.shouldShowNSFWOverlay = self.shouldShowNSFWOverlay
                }
            }
        }
    }
    var shouldShowSpoilerOverlay: Bool = true {
        didSet {
            if self.shouldShowSpoilerOverlay != oldValue {
                let itemViews = self.allItemViews
                for itemView in itemViews {
                    itemView.shouldShowSpoilerOverlay = self.shouldShowNSFWOverlay
                }
            }
        }
    }
    
    weak var delegate: StreamAlbumViewDelegate?
    
    // MARK: Internal properties
    
    fileprivate var itemViewsPerRow = [[StreamAlbumItemView]]()
    fileprivate var reusableItemViews = Set<StreamAlbumItemView>()
    fileprivate var allItemViews: [StreamAlbumItemView] {
        var itemViews = [StreamAlbumItemView]()
        for existingItemViews in self.itemViewsPerRow {
            for existingItemView in existingItemViews {
                itemViews.append(existingItemView)
            }
        }
        return itemViews
    }
    lazy fileprivate var tapGestureRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(StreamAlbumView.handleTapGestureRecognizer(_:)))
    }()
    
    static fileprivate let maxRowImageCount = 3
    static fileprivate let numberOfRows = 2 //Warning: Changing this number might break the layout
    static fileprivate var maxNumberOfImages: Int {
        return self.maxRowImageCount * self.numberOfRows
    }
    
    init() {
        super.init(frame: CGRect())
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    // MARK: - View contents
    
    fileprivate func setupView() {
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    fileprivate func heightForRow(_ row: Int) -> CGFloat {
        let itemViews = self.itemViewsPerRow[row]
        let imageWidth = self.bounds.size.width / CGFloat(itemViews.count)
        //All images are square, so return the imageWidth
        return imageWidth
    }
    
    fileprivate func updateContents() {
        for itemViewsInRow in self.itemViewsPerRow {
            for itemView in itemViewsInRow {
                self.reusableItemViews.insert(itemView)
                itemView.removeFromSuperview()
            }
        }
        self.itemViewsPerRow.removeAll()
        
        if let mediaObjects = self.mediaObjects {
            let numberOfImages = min(mediaObjects.count, StreamAlbumView.maxNumberOfImages)
            
            //If we have 3 or less images, we have just one row
            if numberOfImages <= StreamAlbumView.maxRowImageCount {
                var mediaObjectIndex = 0
                self.itemViewsPerRow.insert([StreamAlbumItemView](), at: 0)
                for imageIndex in 0..<numberOfImages {
                    let itemView = self.albumItemViewForMediaObject(mediaObjects[mediaObjectIndex])
                    self.itemViewsPerRow[0].insert(itemView, at: imageIndex)
                    mediaObjectIndex += 1
                }
            } else if numberOfImages % StreamAlbumView.numberOfRows == 0 {
                //We have an even number so we can evenly distribute the images over 2 rows
                let numberOfImagesPerRow = numberOfImages / StreamAlbumView.numberOfRows
                var mediaObjectIndex = 0
                for rowIndex in 0 ..< StreamAlbumView.numberOfRows {
                    self.itemViewsPerRow.insert([StreamAlbumItemView](), at: rowIndex)
                    for imageIndex in 0 ..< numberOfImagesPerRow {
                        let itemView = self.albumItemViewForMediaObject(mediaObjects[mediaObjectIndex])
                        self.itemViewsPerRow[rowIndex].insert(itemView, at: imageIndex)
                        mediaObjectIndex += 1
                    }
                }
            } else {
                //We have an uneven number, handle it!
                var numberOfImagesPerRow = [Int]()
                numberOfImagesPerRow.append(Int(ceil(Float(numberOfImages) / 2.0)))
                numberOfImagesPerRow.append(Int(floor(Float(numberOfImages) / 2.0)))
    
                var mediaObjectIndex = 0
                for rowIndex in 0 ..< numberOfImagesPerRow.count {
                    self.itemViewsPerRow.insert([StreamAlbumItemView](), at: rowIndex)
                    for imageIndex in 0 ..< numberOfImagesPerRow[rowIndex] {
                        let itemView = self.albumItemViewForMediaObject(mediaObjects[mediaObjectIndex])
                        self.itemViewsPerRow[rowIndex].insert(itemView, at: imageIndex)
                        mediaObjectIndex += 1
                    }
                }
            }
            
            if mediaObjects.count > numberOfImages {
                if let itemView = self.itemViewsPerRow.last?.last {
                    //Remove the last image that contains the label from the number of images
                    itemView.moreCount = mediaObjects.count - (numberOfImages - 1)
                }
            }
        }
        
        self.setNeedsLayout()
    }
    
    func albumItemViewForMediaObject(_ media: MediaObject) -> StreamAlbumItemView {
        var itemView: StreamAlbumItemView! = self.reusableItemViews.first
        if itemView != nil {
            self.reusableItemViews.remove(itemView)
            itemView.prepareForReuse()
        } else {
            itemView = StreamAlbumItemView()
        }
        itemView.mediaObject = media
        itemView.shouldShowNSFWOverlay = self.shouldShowNSFWOverlay
        itemView.shouldShowSpoilerOverlay = self.shouldShowSpoilerOverlay
        itemView.prepareForShow()
        return itemView
    }
    
    // MARK: - Interaction
    
    @objc func handleTapGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        if tapGestureRecognizer.state == UIGestureRecognizerState.ended {
            let location = tapGestureRecognizer.location(in: self)
            if let itemView = self.albumItemViewForLocation(location) {
                self.delegate?.albumView(self, didTapItemView: itemView, atIndex: self.indexOfItemView(itemView))
            }
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var yPosition: CGFloat = 0
        for rowIndex in 0 ..< self.itemViewsPerRow.count {
            self.layoutImagesInRow(rowIndex, yPosition: yPosition)
            yPosition += self.heightForRow(rowIndex)
        }
    }
    
    func layoutImagesInRow(_ row: Int, yPosition: CGFloat) {
        let itemViews = self.itemViewsPerRow[row]
        let rowHeight = self.heightForRow(row)
        let imageSize = CGSize(width: self.bounds.width / CGFloat(itemViews.count), height: rowHeight)
        var imagePosition = CGPoint(x: 0, y: yPosition)
        for itemView in itemViews {
            if itemView.superview == nil {
                self.addSubview(itemView)
            }
            itemView.frame = CGRect(origin: imagePosition, size: imageSize)
            imagePosition.x += imageSize.width
        }
    }
    
    // MARK: - Getting imageview and location
    
    func albumItemViewForLocation(_ point: CGPoint) -> StreamAlbumItemView? {
        for subview in self.subviews {
            if let itemView = subview as? StreamAlbumItemView, itemView.frame.contains(point) {
                return itemView
            }
        }
        return nil
    }
    
    func imageViewForLocation(_ point: CGPoint) -> UIImageView? {
        return self.albumItemViewForLocation(point)?.mediaImageView
    }
    
    func mediaObjectForLocation(_ point: CGPoint) -> MediaObject? {
        return self.albumItemViewForLocation(point)?.mediaObject
    }
    
    func indexOfItemView(_ itemView: StreamAlbumItemView) -> Int {
        var index = 0
        let itemViews = self.allItemViews
        for existingItemView in itemViews {
            if itemView == existingItemView {
                return index
            }
            index += 1
        }
        return 0
    }
    
    func albumItemViewAtIndex(_ index: Int) -> StreamAlbumItemView? {
        var inrecementIndex = 0
        let itemViews = self.allItemViews
        for existingItemView in itemViews {
            if inrecementIndex == index {
                return existingItemView
            }
            inrecementIndex += 1
        }
        return nil
    }
    
    // MARK: - Sizing
    
    class func sizeWithNumberOfMediaObjects(_ numberOfMediaObjects: Int, maxWidth width: CGFloat) -> CGSize {
        let numberOfImages = min(numberOfMediaObjects, StreamAlbumView.maxNumberOfImages)
        if numberOfMediaObjects == 0 {
            return CGSize()
        }
        
        if numberOfImages <= self.maxRowImageCount {
            return CGSize(width: width, height: width / CGFloat(numberOfMediaObjects))
        } else if numberOfImages % StreamAlbumView.numberOfRows == 0 {
            //We have an even number so we can evenly distribute the images over 2 rows
            let numberOfImagesPerRow = numberOfImages / StreamAlbumView.numberOfRows
            let imageWidth = width / CGFloat(numberOfImagesPerRow)
            return CGSize(width: width, height: imageWidth * CGFloat(StreamAlbumView.numberOfRows))
        } else {
            //We have an uneven number, handle it!
            var height: CGFloat = 0
            for rowIndex in 0 ..< StreamAlbumView.numberOfRows {
                var numberOfImagesInRow: Int = 0
                if rowIndex + 1 == StreamAlbumView.numberOfRows {
                    //It is the last row, use floor instead of ceil
                    numberOfImagesInRow = Int(floor(Float(numberOfImages) / Float(StreamAlbumView.numberOfRows)))
                } else {
                    //Use ceil for rounding the number of rows
                    numberOfImagesInRow = Int(ceil(Float(numberOfImages) / Float(StreamAlbumView.numberOfRows)))
                }
                let imageWidth = width / CGFloat(numberOfImagesInRow)
                //Add the imageWidth to the height
                height += imageWidth
            }
            return CGSize(width: width, height: height)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return StreamAlbumView.sizeWithNumberOfMediaObjects(self.mediaObjects?.count ?? 0, maxWidth: UIScreen.main.bounds.size.width)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return StreamAlbumView.sizeWithNumberOfMediaObjects(self.mediaObjects?.count ?? 0, maxWidth: size.width)
    }
    
}
