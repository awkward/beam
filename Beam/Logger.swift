//
//  Logger.swift
//  beam
//
//  Created by Robin Speijer on 20-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

enum AWKLogLevel: Int {
    case trace = 0
    case debug
    case warning
    case error
    
    func description() -> String {
        switch self {
        case .trace:
            return "Trace"
        case .debug:
            return "Debug"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        }
    }
    
    static func minimum() -> AWKLogLevel {
        #if DEBUG
            return .debug
            #else
            return .warning
        #endif
    }
}

func AWKDebugLog(_ format: String, _ args: CVarArg...) {
    let level = AWKLogLevel.debug
    if AWKLogLevel.minimum().rawValue <= level.rawValue {
        let content = NSString(format: format, arguments: getVaList(args))
        NSLog("\(level.description().uppercased()): \(content)")
    }
}

func AWKLog(_ message: String, level: AWKLogLevel = .debug) {
    if level.rawValue >= AWKLogLevel.minimum().rawValue {
        NSLog("\(level.description().uppercased()): \(message)")
    }
}
