//
//  AVPlayer+PlaybackControls.swift
//  Beam
//
//  Created by Rens Verhoeven on 26/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import Foundation
import AVFoundation

extension AVPlayer {
    
    func rewind() {
        //Somehow AVPlayer thinks both the begining and the end are CMTimeZero. That's why it's best to use 0,001 second to make sure it starts at the first frame
        self.seek(to: CMTimeMake(1, 1000))
    }
    
}
