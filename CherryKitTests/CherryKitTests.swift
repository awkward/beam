//
//  CherryKitTests.swift
//  CherryKitTests
//
//  Created by Laurin Brandner on 25/06/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import XCTest
@testable import CherryKit

class CherryKitTests: XCTestCase {
    
    let accessToken = "ad66070eabbadd3f1b1ea61e9e39eee5f354c386"
    
    override func setUp() {
        super.setUp()
        Cherry.appVersion = "2.0"
    }
    
    func testImageMetadata() {
        let expectation = self.expectation(description: "Image metadata")
        
        let imageRequest = ImageRequest(postID: "t5_3223", imageURL: "http://i.imgur.com/spygYxW.jpg")
        ImageMetadataTask(token: accessToken, imageRequests: [imageRequest]).start { (result: TaskResult) -> Void in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssert(result is ImageMetadataTaskResult, "An error occured while getting metadata")
            if let result = result as? ImageMetadataTaskResult {
                XCTAssertTrue(result.metadata.count == 1)
                let first = result.metadata.first!
                XCTAssertEqual(first.request, imageRequest)
                
                if let spec = first.imageSpecs.first {
                    XCTAssertEqual(spec.size, CGSize(width: 620, height: 2342))
                    XCTAssertEqual(spec.URL, NSURL(string: "http://i.imgur.com/spygYxW.jpg")! as URL)
                } else {
                    XCTFail("First image spec missing")
                }
            } else {
                XCTFail("Result missing")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testImgurRegex() {
        let string = "http://i.imgur.com/spygYxW.jpg"
        let pattern = "^https?://.*imgur.com/"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.caseInsensitive])
            if let match = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
                XCTAssert(match.numberOfRanges > 0, "Match must have at least 1 range.")
            } else {
                XCTFail("Pattern not found for '\(string)")
            }
        } catch {
            XCTFail("Regex failed with error: \(error as NSError)")
        }
    }
    
    func testGfycatRegex() {
        let string = "http://gfycat.com/IdleExhaustedIrishterrier"
        let pattern = "^https?://(?: www.)?gfycat.com/"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.caseInsensitive])
            if let match = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
                XCTAssert(match.numberOfRanges > 0, "Match must not have 0 ranges.")
                XCTAssert(match.numberOfRanges == 1, "Match must have 1 range.")
            } else {
                XCTFail("Pattern not found for '\(string)")
            }
        } catch {
            XCTFail("Regex failed with error: \(error as NSError)")
        }
    }
    
    func testExtensionRegex() {
        let acceptingStrings = ["http://i.imgur.com/spygYxW.jpg", "http://i.imgur.com/spygYxW.png", "http://i.imgur.com/spygYxW.jpeg", "http://i.imgur.com/spygYxW.gif"]
        
        for string in acceptingStrings {
            let pattern = "(.jpe?g|.png|.gif)$"
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.caseInsensitive])
                if let match = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
                    XCTAssert(match.numberOfRanges > 0, "Match must more than 0 ranges.")
                } else {
                    XCTFail("Pattern not found for '\(string)")
                }
            } catch {
                XCTFail("Regex failed with error: \(error as NSError)")
            }
        }
    }
    
}
