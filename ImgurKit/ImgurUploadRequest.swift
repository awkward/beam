//
//  ImgurUploadRequest.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

public class ImgurUploadRequest: ImgurRequest {

    open var image: UIImage?
    open var asset: PHAsset?
    
    public init(image: UIImage) {
        super.init()
        self.HTTPMethod = ImgurHTTPMethod.Create
        self.image = image
    }
    
    public init(asset: PHAsset) {
        super.init()
        self.HTTPMethod = ImgurHTTPMethod.Create
        self.asset = asset
    }
    
    internal override func performRequest(_ completionHandler: @escaping ((_ resultObject: AnyObject?, _ error: NSError?) -> Void)) {
        self.updateDownloadProgress(0)
        self.updateUploadProgress(0)
        if let asset = self.asset {
            let requestOptions = PHImageRequestOptions()
            requestOptions.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageData(for: asset, options: requestOptions, resultHandler: { (imageData, dataUTI, _, userInfo) in
                if let imageData = imageData, let dataUTI = dataUTI {
                    var mimeType: String = "image/jpeg"
                    if let dataMimeType = self.convertCFTypeToString(UTTypeCopyPreferredTagWithClass(dataUTI as CFString, kUTTagClassMIMEType)) {
                        mimeType = dataMimeType
                    }
                    self.startUpload(imageData, mimeType: mimeType, completionHandler: completionHandler)
                } else {
                    completionHandler(nil, userInfo![PHImageErrorKey] as? NSError)
                }
            })
        } else if let image = self.image {
            self.startUpload(UIImageJPEGRepresentation(image, 1.0)!, mimeType: "image/jpeg", completionHandler: completionHandler)
        } else {
            fatalError("Image missing!")
        }
    }
    
    fileprivate func convertCFTypeToString(_ CFValue: Unmanaged<CFString>?) -> String? {
        guard CFValue != nil else {
            return nil
        }
        
        let value = Unmanaged.fromOpaque(
            CFValue!.toOpaque()).takeUnretainedValue() as CFString
        if CFGetTypeID(value) == CFStringGetTypeID() {
            return value as String
        } else {
            return nil
        }
    }
    
    fileprivate func startUpload(_ imageData: Data, mimeType: String, completionHandler: @escaping ((_ resultObject: AnyObject?, _ error: NSError?) -> Void)) {
        let mutableRequest = (self.URLRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        let multiPartFormInformation = self.multiPartFormInformation(imageData)
        mutableRequest.setValue("multipart/form-data; boundary=\(multiPartFormInformation.boundaryString)", forHTTPHeaderField: "Content-Type")
        self.currentTask = self.session.uploadTask(with: mutableRequest as URLRequest, from: multiPartFormInformation.data, completionHandler: { (data, response, error) in
            if self.isCancelled {
                self.removeProgressObservers()
                completionHandler(nil, nil)
                return
            }
            var resultObject: AnyObject?
            if let data = data, let response = response as? HTTPURLResponse, self.HTTPMethod != ImgurHTTPMethod.Delete {
                do {
                    let JSONDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                    resultObject = try self.parseResponse(JSONDictionary, response: response)
                } catch let error as NSError {
                    self.removeProgressObservers()
                    completionHandler(nil, error)
                    return
                }
            }
            self.removeProgressObservers()
            completionHandler(resultObject, error as NSError?)
        })
        self.addProgressObservers()
        self.currentTask!.resume()
    }
    
    fileprivate func multiPartFormInformation(_ imageData: Data?) -> (data: Data, boundaryString: NSString) {
        let boundaryString = self.randomString()
        
        let body = NSMutableData()
        
        //Add parameters is available
        if let parameters = self.parameters {
            for (key, value) in parameters {
                body.appendString("--\(boundaryString)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        
        //Add the files
        if let fileData = imageData {
            let mimeType = "image/jpeg"
            body.appendString("--\(boundaryString)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"file.jpg\"\r\n")
            body.appendString("Content-Type: \(mimeType)\r\n\r\n")
            body.append(fileData)
            body.appendString("\r\n")
        }
        
        //Add the end boundary
        body.appendString("--\(boundaryString)--\r\n")
        
        return (data: body as Data, boundaryString: boundaryString)
    }
    
    fileprivate func randomString(withLength length: Int = 12) -> NSString {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString: NSMutableString = NSMutableString(capacity: length)
        let lettersLength = UInt32(letters.length)
        
        for _ in 0...length {
            let randomNumber = arc4random_uniform(lettersLength)
            randomString.appendFormat("%C", letters.character(at: Int(randomNumber)))
        }
        
        return randomString
    }
    
}
