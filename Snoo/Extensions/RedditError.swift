//
//  RedditError.swift
//  Snoo
//
//  Created by Rens Verhoeven on 23-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

public let RedditErrorDomain = "com.reddit.reddit"
public let RedditUnknownErrorCode = -200
let RedditUnknownErrorDescription = "Unknown reddit.com error"

public let RedditErrorDescriptionKey = "RedditErrorDescriptionKey"
public let RedditErrorsArrayKey = "RedditErrorsArrayKey"
let RedditErrorKeyKey = "RedditErrorKeyKey"

public enum RedditErrorKey: String {
    case InvalidCredentials = "WRONG_PASSWORD"
    case BadCaptcha = "BAD_CAPTCHA"
    case RateLimited = "RATELIMIT"
    case BadCSSName = "BAD_CSS_NAME"
    case Archived = "TOO_OLD"
    case TooMuchFlairCSS = "TOO_MUCH_FLAIR_CSS"
    case SubredditDoesntExist = "SUBREDDIT_NOEXIST"
    case AlreadySubmitted = "ALREADY_SUB"
    case InvalidMultiredditName = "BAD_MULTI_NAME"
    case UserRequired = "USER_REQUIRED"
    case NoLinksAllowed = "NO_LINKS"
    case NoSelfTextAllowed = "NO_SELFS"
    case SubredditNotAllowed = "SUBREDDIT_NOTALLOWED"
    
    var errorCode: Int {
        switch self {
        case .BadCaptcha:
            return 201
        case .BadCSSName:
            return 202
        case .InvalidCredentials:
            return 203
        case .RateLimited:
            return 204
        case .TooMuchFlairCSS:
            return 205
        case .Archived:
            return 206
        case .SubredditDoesntExist:
            return 207
        case .AlreadySubmitted:
            return 208
        case .UserRequired:
            return 209
        case .NoLinksAllowed:
            return 210
        case .NoSelfTextAllowed:
            return 211
        case .InvalidMultiredditName:
            return 401
        case .SubredditNotAllowed:
            return 402

        }
    }
    
    var errorDescription: String {
        switch self {
        case .InvalidCredentials:
            return "Invalid credentials"
        case .BadCaptcha:
            return "Incorrect captcha"
        case .RateLimited:
            return "Rate limited reached"
        case .BadCSSName:
            return "Incorrect CSS class name"
        case .Archived:
            return "This object has been archived"
        case .TooMuchFlairCSS:
            return "Too much flair CSS classes"
        case .SubredditDoesntExist:
            return "Subreddit doesn't exist"
        case .AlreadySubmitted:
            return "Link has already been submitted"
        case .InvalidMultiredditName:
            return "Invalid multireddit name"
        case .UserRequired:
            return "A user is required for this action"
        case .NoLinksAllowed:
            return "Links are not allowed in this subreddit"
        case .NoSelfTextAllowed:
            return "Self posts are not allowed in this subreddit"
        case .SubredditNotAllowed:
            return "You are not allowed to post in this subreddit"
        }
    }
}

extension NSError {
    
    static public func redditError(_ code: Int, localizedDescription: String?) -> NSError {
        if let localizedDescription = localizedDescription {
            return NSError(domain: RedditErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
        } else {
            return NSError(domain: RedditErrorDomain, code: code, userInfo: nil)
        }
    }
    
    static public func redditError(errorsArray errors: NSArray) -> NSError {
        var errorKey: RedditErrorKey?
        var redditErrorDescription: String?
        var redditErrorKeyString: String?
        //We get an array of errors, we only care about the first one because that is the most important one
        if let firstError = errors.firstObject as? NSArray {
            //Reddit errors are an array where 0 is the key, 1 is description and 2-20 are the fields
            if let key = firstError[0] as? String {
                errorKey = RedditErrorKey(rawValue: key)
                redditErrorKeyString = key
            }
            if let error = firstError[1] as? String {
                 redditErrorDescription = error
            }
        }
        var userInfo = [String: Any]()
        userInfo[NSLocalizedDescriptionKey] = errorKey?.errorDescription ?? RedditUnknownErrorDescription
        if let redditErrorDescription = redditErrorDescription {
            userInfo[RedditErrorDescriptionKey] = redditErrorDescription
        }
        if let redditErrorKeyString = redditErrorKeyString {
            userInfo[RedditErrorKeyKey] = redditErrorKeyString
        }
        userInfo[RedditErrorsArrayKey] = errors
        return NSError(domain: RedditErrorDomain, code: errorKey?.errorCode ?? RedditUnknownErrorCode, userInfo: userInfo)
    }
    
    public var redditErrorKey: RedditErrorKey? {
        if let keyString = self.userInfo[RedditErrorKeyKey] as? String, let key = RedditErrorKey(rawValue: keyString) {
            return key
        }
        return nil
    }
    
}
