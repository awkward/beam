//
//  UIDevice+ModelName.swift
//  Beam
//
//  Created by Rens Verhoeven on 15-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

public extension UIDevice {
    
    public var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
}
