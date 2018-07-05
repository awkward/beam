//
//  UIImageView+URLDownscale.swift
//  beam
//
//  Created by Robin Speijer on 20-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

private let bytesPerMB: CGFloat = 1048576.0
private let bytesPerPixel: CGFloat = 4.0
private let sourceImageTileSizeMB: CGFloat = 40
private let pixelsPerMB = bytesPerMB / bytesPerPixel
private let tileTotalPixels = sourceImageTileSizeMB * pixelsPerMB
private let destSeemOverlap: CGFloat = 2.0

struct DownscaledImageOptions {
    var constrainingSize = UIScreen.main.bounds.size
    var contentMode = UIViewContentMode.scaleAspectFill
}

extension UIImage {

    fileprivate class func destinationImageSizeWithOriginalSize(_ size: CGSize, options: DownscaledImageOptions) -> CGSize {
        let sourceRatio: CGFloat = size.width / size.height
        let boundsRatio: CGFloat = options.constrainingSize.width / options.constrainingSize.height
        
        let widthConstrainedSize = CGSize(width: options.constrainingSize.width, height: options.constrainingSize.width / sourceRatio)
        let heightConstrainedSize = CGSize(width: options.constrainingSize.height * sourceRatio, height: options.constrainingSize.height)
        
        switch options.contentMode {
        case .scaleAspectFit:
            return sourceRatio < boundsRatio ? heightConstrainedSize: widthConstrainedSize
        case .scaleAspectFill:
            return sourceRatio < boundsRatio ? widthConstrainedSize: heightConstrainedSize
        case .scaleToFill:
            return options.constrainingSize
        default:
            return size
        }
    }
    
    class func downscaledImageWithFileURL(_ fileURL: URL, options: DownscaledImageOptions) -> UIImage? {
        
        let path = fileURL.path
        
        var resultingImage: UIImage?
        
        autoreleasepool { () in
            // create an image from the image path. Note this
            // doesn't actually read any pixel information from disk, as that
            // is actually done at draw time.
            guard let sourceImage = UIImage(contentsOfFile: path) else {
                NSLog("input image to downscale not found")
                resultingImage = nil
                return
            }
            
            guard let sourceCGImage: CGImage = sourceImage.cgImage else {
                NSLog("No CGImage for source image")
                resultingImage = nil
                return
            }
            
            // get the width and height of the input image using
            // core graphics image helper functions.
            let sourceImageWidth = sourceCGImage.width
            let sourceImageHeight = sourceCGImage.height
            let sourceResolution = CGSize(width: sourceImageWidth, height: sourceImageHeight)
            // calculate the number of MB that would be required to store
            // this image uncompressed in memory.
            let destSize = self.destinationImageSizeWithOriginalSize(sourceResolution, options: options)
            
            let scale: CGFloat = min(2.0, UIScreen.main.scale)
            
            let destWidth = floor(destSize.width * scale)
            let destHeight = floor(destSize.height * scale)
            let destResolution = CGSize(width: destWidth, height: destHeight)
            let imageScale = CGSize(width: destResolution.width / sourceResolution.width, height: destResolution.height / sourceResolution.height)
            
            guard CGFloat(sourceImageWidth) > destWidth && CGFloat(sourceImageHeight) > destHeight else {
                resultingImage = sourceImage
                return
            }
            
            // create an offscreen bitmap context that will hold the output image
            // pixel data, as it becomes available by the downscaling routine.
            // use the RGB colorspace as this is the colorspace iOS GPU is optimized for.
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bytesPerRow = bytesPerPixel * destResolution.width
            let destBitmapData = malloc(Int(bytesPerRow * destResolution.height))
            
            guard destBitmapData != nil else {
                NSLog("could not allocate memory for downscaling image")
                resultingImage = nil
                return
            }
            
            guard let destContext: CGContext = CGContext(data: destBitmapData, width: Int(destResolution.width), height: Int(destResolution.height), bitsPerComponent: 8, bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                NSLog("could not create downscaled image context")
                resultingImage = nil
                return
            }
            
            // flip the output graphics context so that it aligns with the
            // cocoa style orientation of the input document. this is needed
            // because we used cocoa's UIImage -imageNamed to open the input file.
            //            CGContextTranslateCTM(destContext, 0.0, destResolution.height)
            //            CGContextScaleCTM(destContext, 1.0, -1.0)
            
            // now define the size of the rectangle to be used for the
            // incremental blits from the input image to the output image.
            // we use a source tile width equal to the width of the source
            // image due to the way that iOS retrieves image data from disk.
            // iOS must decode an image from disk in full width 'bands', even
            // if current graphics context is clipped to a subrect within that
            // band. Therefore we fully utilize all of the pixel data that results
            // from a decoding opertion by achnoring our tile size to the full
            // width of the input image.
            var sourceTile = CGRect()
            sourceTile.size.width = sourceResolution.width
            // the source tile height is dynamic. Since we specified the size
            // of the source tile in MB, see how many rows of pixels high it
            // can be given the input image width.
            sourceTile.size.height = CGFloat(floorf(Float(tileTotalPixels / sourceTile.size.width)))
            sourceTile.origin.x = 0
            
            // the output tile is the same proportions as the input tile, but
            // scaled to image scale.
            var destTile = CGRect()
            destTile.size.width = destResolution.width
            destTile.size.height = sourceTile.size.height * imageScale.height
            destTile.origin.x = 0.0
            // the source seem overlap is proportionate to the destination seem overlap.
            // this is the amount of pixels to overlap each tile as we assemble the ouput image.
            let sourceSeemOverlap = Int((destSeemOverlap / destResolution.height) * sourceResolution.height)
            
            // calculate the number of read/write opertions required to assemble the
            // output image.
            var iterations = Int(sourceResolution.height / sourceTile.size.height)
            // if tile height doesn't divide the image height evenly, add another iteration
            // to account for the remaining pixels.
            let remainder = Int(sourceResolution.height) % Int(sourceTile.size.height)
            if remainder > 0 {
                iterations += 1
            }
            // add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
            let sourceTileHeightMinusOverlap = sourceTile.size.height
            sourceTile.size.height += CGFloat(sourceSeemOverlap)
            destTile.size.height += CGFloat(destSeemOverlap)
            
            if iterations == 1 {
                sourceTile = CGRect(origin: CGPoint(), size: sourceResolution)
                guard let sourceTileImageRef = sourceCGImage.cropping(to: sourceTile) else {
                    NSLog("Invalid source time image ref found")
                    resultingImage = nil
                    return
                }
                destTile = CGRect(origin: CGPoint(), size: destResolution)
                destContext.draw(sourceTileImageRef, in: destTile)
            } else {
                for y in 0 ..< iterations {
                    autoreleasepool(invoking: { () in
                        sourceTile.origin.y = CGFloat(y) * sourceTileHeightMinusOverlap + CGFloat(sourceSeemOverlap)
                        destTile.origin.y = ( destResolution.height ) - ( CGFloat( y + 1 ) * sourceTileHeightMinusOverlap * imageScale.height + destSeemOverlap )
                        // create a reference to the source image with its context clipped to the argument rect.
                        guard let sourceTileImageRef = sourceCGImage.cropping(to: sourceTile ) else {
                            return
                        }
                        // if this is the last tile, it's size may be smaller than the source tile height.
                        // adjust the dest tile size to account for that difference.
                        if y == iterations - 1 && remainder > 0 {
                            var dify = destTile.size.height
                            destTile.size.height = CGFloat(sourceTileImageRef.height) * imageScale.height
                            dify -= destTile.size.height
                            destTile.origin.y += dify
                        }
                        // read and write a tile sized portion of pixels from the input image to the output image.
                        destContext.draw(sourceTileImageRef, in: destTile)
                    })
                }
            }
            
            if let destImageRef = destContext.makeImage() {
                resultingImage = UIImage(cgImage: destImageRef)
            }
            
            free(destBitmapData)
        }
        
        return resultingImage
    }
    
    class func downscaledImageWithImage(_ sourceImage: UIImage, options: DownscaledImageOptions) -> UIImage? {
        
        var resultingImage: UIImage?
        
        autoreleasepool { () in
            // create an image from the image path. Note this
            // doesn't actually read any pixel information from disk, as that
            // is actually done at draw time.
            
            guard let sourceCGImage: CGImage = sourceImage.cgImage else {
                NSLog("No CGImage for source image")
                resultingImage = nil
                return
            }
            
            // get the width and height of the input image using
            // core graphics image helper functions.
            let sourceImageWidth = sourceCGImage.width
            let sourceImageHeight = sourceCGImage.height
            let sourceResolution = CGSize(width: sourceImageWidth, height: sourceImageHeight)
            // calculate the number of MB that would be required to store
            // this image uncompressed in memory.
            let destSize = self.destinationImageSizeWithOriginalSize(sourceResolution, options: options)
            
            let scale: CGFloat = min(2.0, UIScreen.main.scale)
            
            let destWidth = floor(destSize.width * scale)
            let destHeight = floor(destSize.height * scale)
            let destResolution = CGSize(width: destWidth, height: destHeight)
            let imageScale = CGSize(width: destResolution.width / sourceResolution.width, height: destResolution.height / sourceResolution.height)
            
            guard CGFloat(sourceImageWidth) > destWidth && CGFloat(sourceImageHeight) > destHeight else {
                resultingImage = sourceImage
                return
            }
            
            // create an offscreen bitmap context that will hold the output image
            // pixel data, as it becomes available by the downscaling routine.
            // use the RGB colorspace as this is the colorspace iOS GPU is optimized for.
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bytesPerRow = bytesPerPixel * destResolution.width
            let destBitmapData = malloc(Int(bytesPerRow * destResolution.height))
            
            guard destBitmapData != nil else {
                NSLog("could not allocate memory for downscaling image")
                resultingImage = nil
                return
            }
            
            guard let destContext: CGContext = CGContext(data: destBitmapData, width: Int(destResolution.width), height: Int(destResolution.height), bitsPerComponent: 8, bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                NSLog("could not create downscaled image context")
                resultingImage = nil
                return
            }
            
            // flip the output graphics context so that it aligns with the
            // cocoa style orientation of the input document. this is needed
            // because we used cocoa's UIImage -imageNamed to open the input file.
            //            CGContextTranslateCTM(destContext, 0.0, destResolution.height)
            //            CGContextScaleCTM(destContext, 1.0, -1.0)
            
            // now define the size of the rectangle to be used for the
            // incremental blits from the input image to the output image.
            // we use a source tile width equal to the width of the source
            // image due to the way that iOS retrieves image data from disk.
            // iOS must decode an image from disk in full width 'bands', even
            // if current graphics context is clipped to a subrect within that
            // band. Therefore we fully utilize all of the pixel data that results
            // from a decoding opertion by achnoring our tile size to the full
            // width of the input image.
            var sourceTile = CGRect()
            sourceTile.size.width = sourceResolution.width
            // the source tile height is dynamic. Since we specified the size
            // of the source tile in MB, see how many rows of pixels high it
            // can be given the input image width.
            sourceTile.size.height = CGFloat(floorf(Float(tileTotalPixels / sourceTile.size.width)))
            sourceTile.origin.x = 0
            
            // the output tile is the same proportions as the input tile, but
            // scaled to image scale.
            var destTile = CGRect()
            destTile.size.width = destResolution.width
            destTile.size.height = sourceTile.size.height * imageScale.height
            destTile.origin.x = 0.0
            // the source seem overlap is proportionate to the destination seem overlap.
            // this is the amount of pixels to overlap each tile as we assemble the ouput image.
            let sourceSeemOverlap = Int((destSeemOverlap / destResolution.height) * sourceResolution.height)
            
            // calculate the number of read/write opertions required to assemble the
            // output image.
            var iterations = Int(sourceResolution.height / sourceTile.size.height)
            // if tile height doesn't divide the image height evenly, add another iteration
            // to account for the remaining pixels.
            let remainder = Int(sourceResolution.height) % Int(sourceTile.size.height)
            if remainder > 0 {
                iterations += 1
            }
            // add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
            let sourceTileHeightMinusOverlap = sourceTile.size.height
            sourceTile.size.height += CGFloat(sourceSeemOverlap)
            destTile.size.height += CGFloat(destSeemOverlap)
            
            if iterations == 1 {
                sourceTile = CGRect(origin: CGPoint(), size: sourceResolution)
                guard let sourceTileImageRef = sourceCGImage.cropping(to: sourceTile) else {
                    NSLog("Invalid source time image ref found")
                    resultingImage = nil
                    return
                }
                destTile = CGRect(origin: CGPoint(), size: destResolution)
                destContext.draw(sourceTileImageRef, in: destTile)
            } else {
                for y in 0 ..< iterations {
                    autoreleasepool(invoking: { () in
                        sourceTile.origin.y = CGFloat(y) * sourceTileHeightMinusOverlap + CGFloat(sourceSeemOverlap)
                        destTile.origin.y = ( destResolution.height ) - ( CGFloat( y + 1 ) * sourceTileHeightMinusOverlap * imageScale.height + destSeemOverlap )
                        // create a reference to the source image with its context clipped to the argument rect.
                        guard let sourceTileImageRef = sourceCGImage.cropping(to: sourceTile ) else {
                            return
                        }
                        // if this is the last tile, it's size may be smaller than the source tile height.
                        // adjust the dest tile size to account for that difference.
                        if y == iterations - 1 && remainder > 0 {
                            var dify = destTile.size.height
                            destTile.size.height = CGFloat(sourceTileImageRef.height) * imageScale.height
                            dify -= destTile.size.height
                            destTile.origin.y += dify
                        }
                        // read and write a tile sized portion of pixels from the input image to the output image.
                        destContext.draw(sourceTileImageRef, in: destTile)
                    })
                }
            }
            
            if let destImageRef = destContext.makeImage() {
                resultingImage = UIImage(cgImage: destImageRef)
            }
            
            free(destBitmapData)
        }
        
        return resultingImage
    }
    
}
