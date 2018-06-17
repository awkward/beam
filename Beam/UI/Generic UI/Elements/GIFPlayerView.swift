//
//  GIFPlayerView.swift
//  Beam
//
//  Created by Rens Verhoeven on 21/11/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Snoo

@objc
class GIFPlayerView: UIView {
    
    class var canAutoplayGifs: Bool {
        let is64bit = MemoryLayout<Int>.size == MemoryLayout<Int64>.size
        let enabled = UserSettings[.autoPlayGifsEnabled]
        
        let playAllowed = UserSettings[.autoPlayGifsEnabledOnCellular] || (!UserSettings[.autoPlayGifsEnabledOnCellular] && DataController.shared.redditReachability?.isReachableViaWiFi == true)
        return is64bit && enabled && playAllowed
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    private var videoPlayerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    /// The current gif url that is being played.
    private var currentUrl: URL?
    
    /// A retained version of the player item on the AVPlayerLayer's player. Improves playback
    private var currentPlayerItem: AVPlayerItem?
    
    /// A retained version of the player on the AVPlayerLayer. Improves playback
    private var privatePlayer: AVPlayer?
    
    private var videoPlayer: AVPlayer? {
        get {
            return self.videoPlayerLayer.player
        }
        set {
            self.privatePlayer = newValue
            self.videoPlayerLayer.player = newValue
        }
    }
    
    //Because @available doesn't work for properties, we have to make this AnyObject. But in fact it will always be a AVPlayerLooper if it's not null
    private var playerLooper: AnyObject?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(GIFPlayerView.applicationDidBecomeActive(notification:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GIFPlayerView.applicationWillResignActive(notification:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
        self.videoPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }
    
    func play(url: URL) {
        self.replace(url: url)
        self.play()
    }
    
    private func replace(url: URL, force: Bool = false) {
        guard self.currentUrl != url || force else {
            return
        }
        self.currentUrl = url
        
        //Make the playerItem on a different thread, it improves scrolling
        DispatchQueue.global(qos: .userInteractive).async {
            let item = AVPlayerItem(url: url)
            DispatchQueue.main.async {
                guard let urlAsset = item.asset as? AVURLAsset, urlAsset.url == self.currentUrl else {
                    return
                }
                self.currentPlayerItem = item
                if self.videoPlayerLayer.player == nil {
                    
                    if #available(iOS 10.0, *) {
                        let queuePlayer = AVQueuePlayer(playerItem: item)
                        queuePlayer.isMuted = true
                        
                        //Create the looper controller. We need to retain this, otherwise the looping stops
                        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
                        
                        self.videoPlayer = queuePlayer
                    } else {
                        //Observe when the player ends
                        NotificationCenter.default.addObserver(self, selector: #selector(GIFPlayerView.avPlayerItemDidFinishPlaying(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
                        
                        let player = AVPlayer(playerItem: item)
                        player.isMuted = true
                        player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
                        player.rewind()
                        self.videoPlayer = player
                    }
                } else {
                    if #available(iOS 10.0, *), let queuePlayer = self.videoPlayer as? AVQueuePlayer {
                        self.stop()
                        queuePlayer.removeAllItems()
                        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
                    } else {
                        self.stop()
                        self.videoPlayer?.replaceCurrentItem(with: item)
                    }
                    
                }
            }
        }
    }
    
    func play() {
        //Play changes the playing state of the AVPlayer, regardless of if it contains an item or not
        self.videoPlayer?.play()
        
    }
    
    func pause() {
        self.videoPlayer?.pause()
    }
    
    func stop() {
        self.currentUrl = nil
        self.videoPlayer?.pause()
        self.videoPlayer?.rewind()
        if #available(iOS 10.0, *), let queuePlayer = self.videoPlayer as? AVQueuePlayer {
            queuePlayer.removeAllItems()
            (self.playerLooper as? AVPlayerLooper)?.disableLooping()
            self.playerLooper = nil
        } else {
            self.videoPlayer?.replaceCurrentItem(with: nil)
        }
    }
    
    var isPlaying: Bool {
        guard let player = self.videoPlayer else {
            return false
        }
        return player.rate >= 1
    }

    //If the gif was playing before the app became inactive
    private var wasPlayingBeforeInactive: Bool = false
    
    // MARK: - Auto Play gifs
    
    //This notification is only called on iOS 9 for AVPlayer to begin the loop again. On iOS 10+ AVQueuePlayer and AVPlayerLooper take care of the looping
    @objc fileprivate func avPlayerItemDidFinishPlaying(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem, playerItem == self.videoPlayer?.currentItem && self.window != nil && UIApplication.shared.applicationState == UIApplicationState.active {
            self.videoPlayer?.rewind()
            self.videoPlayer?.play()
        }
    }
    
    @objc fileprivate func applicationDidBecomeActive(notification: Notification) {
        if self.videoPlayer?.currentItem != nil && self.window != nil && self.wasPlayingBeforeInactive {
            self.wasPlayingBeforeInactive = false
            self.videoPlayer?.play()
        }
    }
    
    @objc fileprivate func applicationWillResignActive(notification: Notification) {
        if self.videoPlayer?.currentItem != nil {
            self.wasPlayingBeforeInactive = self.isPlaying
            self.videoPlayer?.pause()
        }
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            self.videoPlayer?.pause()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.videoPlayer?.pause()
        self.videoPlayer = nil
    }
    
}
