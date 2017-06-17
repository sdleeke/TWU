//
//  MediaPlayer.swift
//  TWU
//
//  Created by Steve Leeke on 6/16/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer

enum PlayerState {
    case none
    
    case paused
    case playing
    case stopped
    
    case seekingForward
    case seekingBackward
}

class PlayerStateTime {
    var sermon:Sermon? {
        willSet {
            
        }
        didSet {
            startTime = sermon?.currentTime
        }
    }
    
    var state:PlayerState = .none {
        willSet {
            
        }
        didSet {
            if (state != oldValue) {
                dateEntered = Date()
            }
        }
    }
    
    var startTime:String?
    
    var dateEntered:Date?
    var timeElapsed:TimeInterval {
        get {
            return Date().timeIntervalSince(dateEntered!)
        }
    }
    
    init()
    {
        dateEntered = Date()
    }
    
    convenience init(sermon:Sermon?,state:PlayerState)
    {
        self.init()
        self.sermon = sermon
        self.state = state
        self.startTime = sermon?.currentTime
    }
    
    func log()
    {
        var stateName:String?
        
        switch state {
        case .none:
            stateName = "none"
            break
            
        case .paused:
            stateName = "paused"
            break
            
        case .playing:
            stateName = "playing"
            break
            
        case .seekingForward:
            stateName = "seekingForward"
            break
            
        case .seekingBackward:
            stateName = "seekingBackward"
            break
            
        case .stopped:
            stateName = "stopped"
            break
        }
        
        if stateName != nil {
            print(stateName!)
        }
    }
}

class MediaPlayer : NSObject {
    var playerTimerReturn:Any? = nil
    var sliderTimerReturn:Any? = nil
    
    var observerActive = false
    
    var url : URL? {
        get {
            return (player?.currentItem?.asset as? AVURLAsset)?.url
        }
    }
    
    var hiddenPlayer:AVPlayer?
    
    var player:AVPlayer? {
        get {
            return hiddenPlayer
        }
        
        set {
            if sliderTimerReturn != nil {
                hiddenPlayer?.removeTimeObserver(sliderTimerReturn!)
                sliderTimerReturn = nil
            }
            
            if playerTimerReturn != nil {
                hiddenPlayer?.removeTimeObserver(playerTimerReturn!)
                playerTimerReturn = nil
            }
            
            self.hiddenPlayer = newValue
        }
    }
    
    private var stateTime : PlayerStateTime?

    func setupPlayingInfoCenter()
    {
        if let title = playing?.series?.title, let index = playing?.index {
            var sermonInfo = [String:AnyObject]()
            
            sermonInfo[MPMediaItemPropertyTitle] = "\(title) (Part \(index + 1))" as AnyObject
            
            sermonInfo[MPMediaItemPropertyArtist] = Constants.Tom_Pennington as AnyObject
            
            sermonInfo[MPMediaItemPropertyAlbumTitle] = title as AnyObject
            
            sermonInfo[MPMediaItemPropertyAlbumArtist] = Constants.Tom_Pennington as AnyObject
            
            if let art = playing!.series!.loadArt() {
                sermonInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: art)
            }
            
            sermonInfo[MPMediaItemPropertyAlbumTrackNumber] = index + 1 as AnyObject
            
            if let numberOfSermons = playing?.series?.numberOfSermons {
                sermonInfo[MPMediaItemPropertyAlbumTrackCount] = numberOfSermons as AnyObject
            }
            
            if let duration = duration?.seconds {
                sermonInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: duration)
            }
            
            if let currentTime = currentTime?.seconds {
                sermonInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: currentTime)
            }
            
            if let rate = rate {
                sermonInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: rate)
            }
            
            //    println("\(sermonInfo.count)")
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = sermonInfo
        }
    }
    
    func updateCurrentTimeForPlaying()
    {
        //        assert(player?.currentItem != nil,"player?.currentItem should not be nil if we're trying to update the currentTime in userDefaults")
        assert(currentTime != nil,"currentTime should not be nil if we're trying to update the currentTime in userDefaults")
        
        if loaded && (currentTime != nil) && (duration != nil) {
            var timeNow = 0
            
            if (currentTime!.seconds > 0) && (currentTime!.seconds <= duration!.seconds) {
                timeNow = Int(currentTime!.seconds)
            }
            
            if ((timeNow > 0) && (timeNow % 10) == 0) {
                //                println("\(timeNow.description)")
                if Int(Float(playing!.currentTime!)!) != Int(currentTime!.seconds) {
                    playing?.currentTime = currentTime!.seconds.description
                }
            }
        }
    }
    
    //    private var GlobalPlayerContext = 0
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        //        guard context == &GlobalPlayerContext else {
        //            super.observeValue(forKeyPath: keyPath,
        //                               of: object,
        //                               change: change,
        //                               context: context)
        //            return
        //        }
        
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            if #available(iOS 10.0, *) {
                if  let statusNumber = change?[.newKey] as? NSNumber,
                    let status = AVPlayerTimeControlStatus(rawValue: statusNumber.intValue) {
                    switch status {
                    case .waitingToPlayAtSpecifiedRate:
                        if let reason = player?.reasonForWaitingToPlay {
                            print("waitingToPlayAtSpecifiedRate: ",reason)
                        } else {
                            print("waitingToPlayAtSpecifiedRate: no reason")
                        }
                        break
                        
                    case .paused:
                        if let state = state {
                            switch state {
                            case .none:
                                break
                                
                            case .paused:
                                break
                                
                            case .playing:
                                pause()
                                
                                // didPlayToEnd observer doesn't always work.  This seemds to catch the cases where it doesn't.
                                if let currentTime = currentTime?.seconds,
                                    let duration = duration?.seconds,
                                    Int(currentTime) >= Int(duration) {
                                    didPlayToEnd()
                                }
                                break
                                
                            case .seekingBackward:
                                //                                pause()
                                break
                                
                            case .seekingForward:
                                //                                pause()
                                break
                                
                            case .stopped:
                                break
                            }
                        }
                        break
                        
                    case .playing:
                        if let state = state {
                            switch state {
                            case .none:
                                break
                                
                            case .paused:
                                play()
                                break
                                
                            case .playing:
                                break
                                
                            case .seekingBackward:
                                //                                play()
                                break
                                
                            case .seekingForward:
                                //                                play()
                                break
                                
                            case .stopped:
                                break
                            }
                        }
                        break
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                //                print(player?.currentItem?.duration.value)
                //                print(player?.currentItem?.duration.timescale)
                //                print(player?.currentItem?.duration.seconds)
                
                if !loaded && (playing != nil) {
                    loaded = true
                    
                    if playing!.hasCurrentTime() {
                        if playing!.atEnd {
                            seek(to: duration!.seconds)
                        } else {
                            seek(to: Double(playing!.currentTime!)!)
                        }
                    } else {
                        playing!.currentTime = Constants.ZERO
                        seek(to: 0)
                    }
                    
                    if playOnLoad {
                        if playing!.atEnd {
                            playing!.currentTime = Constants.ZERO
                            seek(to: 0)
                            playing?.atEnd = false
                        }
                        playOnLoad = false
                        play()
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
                    })
                }
                
                if (url != nil) {
                    setupPlayingInfoCenter()
                }
                break
                
            case .failed:
                // Player item failed. See error.
                networkUnavailable("Media failed to load.")
                loadFailed = true
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
                })
                break
                
            case .unknown:
                // Player item is not yet ready.
                if #available(iOS 10.0, *) {
                    print(player?.reasonForWaitingToPlay! as Any)
                } else {
                    // Fallback on earlier versions
                }
                break
            }
        }
    }

//    @objc func didPlayToEnd()
//    {
//        globals.didPlayToEnd()
//    }
    
    @objc func didPlayToEnd()
    {
        //        print("didPlayToEnd",playing)
        
        //        print(currentTime?.seconds)
        //        print(duration?.seconds)
        
        pause()
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        })
        
        if let duration = duration?.seconds, let currentTime = currentTime?.seconds {
            playing?.atEnd = currentTime >= (duration - 1)
            if (playing != nil) && !playing!.atEnd {
                reload(playing)
            }
        } else {
            playing?.atEnd = true
        }
        
        if globals.autoAdvance, playing != nil, playing!.atEnd,
            let mediaItems = playing?.series?.sermons,
            let index = mediaItems.index(of: playing!), index < (mediaItems.count - 1) {
            let nextMediaItem = mediaItems[index + 1]
            
            nextMediaItem.currentTime = Constants.ZERO
            
            playing = nextMediaItem
            playOnLoad = true
            
            setup(nextMediaItem)
        } else {
            stop()
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        })
    }
    
    func reload(_ sermon:Sermon?)
    {
        if let url = sermon!.playingURL {
            reload(url: url)
        }
    }
    
    func reload(url:URL?)
    {
        if (url != nil) {
            unload()
            
            unobserve()
            
            player?.replaceCurrentItem(with: AVPlayerItem(url: url!))
            
            observe()
        }
    }
    
    func setup(_ sermon:Sermon?)
    {
        if (sermon != nil) {
            unload()
            
            unobserve()
            
            //            if playerTimerReturn != nil {
            //                player?.removeTimeObserver(playerTimerReturn!)
            //                playerTimerReturn = nil
            //            }
            //
            //            player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil) // &GlobalPlayerContext
            //
            //            if sliderTimerReturn != nil {
            //                player?.removeTimeObserver(sliderTimerReturn!)
            //                sliderTimerReturn = nil
            //            }
            
            player = AVPlayer(url: sermon!.playingURL!)
            
            if #available(iOS 10.0, *) {
                player?.automaticallyWaitsToMinimizeStalling = false
            } else {
                // Fallback on earlier versions
            }
            
            player?.actionAtItemEnd = .pause
            
            observe()
            
            //            player?.currentItem?.addObserver(self,
            //                                             forKeyPath: #keyPath(AVPlayerItem.status),
            //                                             options: [.old, .new],
            //                                             context: nil) // &GlobalPlayerContext
            
            //            playerTimerReturn = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (CMTime) in
            //                self?.playerTimer()
            //            })
            
            pause()
        }
    }
    
    func setupAtEnd(_ sermon:Sermon?)
    {
        setup(sermon)
        
        if (player != nil) {
            seek(to: duration!.seconds)
            pause()
            sermon?.currentTime = Float(duration!.seconds).description
        }
    }
    
    func playerTimer()
    {
        // This function is only called when the media is playing
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = player != nil
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = player != nil
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = player != nil
        
        if (rate > 0) {
            updateCurrentTimeForPlaying()
        }
        
        if (player != nil) {
            switch state! {
            case .none:
                //                print("none")
                break
                
            case .playing:
                //                print("playing")
                break
                
            case .paused:
                //                print("paused")
                
                //                if !mediaPlayer.loaded && !mediaPlayer.loadFailed {
                //                    if (mediaPlayer.stateTime!.timeElapsed > Constants.MIN_LOAD_TIME) {
                //                        mediaPlayer.loadFailed = true
                //
                //                        if (UIApplication.shared.applicationState == UIApplicationState.active) {
                //                            let errorAlert = UIAlertView(title: "Unable to Load Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                //                            errorAlert.show()
                //                        }
                //                    }
                //                }
                break
                
            case .stopped:
                //                print("stopped")
                break
                
            case .seekingForward:
                //                print("seekingForward")
                break
                
            case .seekingBackward:
                //                print("seekingBackward")
                break
            }
        }
    }
    
    func observe()
    {
        // We use both a timer and a periodicTimeObserver in CBC.  Why?  Because we need to monitor the player even when it isn't playing.  Do we need to do that here?
        
        //        DispatchQueue.main.async(execute: { () -> Void in
        //            self.playerObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PLAYER, target: self, selector: #selector(Globals.playerTimer), userInfo: nil, repeats: true)
        //        })
        
        unobserve()
        
        player?.addObserver( self,
                             forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                             options: [.old, .new],
                             context: nil) // &GlobalPlayerContext
        
        player?.currentItem?.addObserver(self,
                                         forKeyPath: #keyPath(AVPlayerItem.status),
                                         options: [.old, .new],
                                         context: nil) // &GlobalPlayerContext
        observerActive = true
        
        playerTimerReturn = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { (time:CMTime) in // [weak globals]
            self.playerTimer()
        })
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaPlayer.didPlayToEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
        
        pause()
    }
    
    func unobserve()
    {
        //        self.playerObserver?.invalidate()
        //        self.playerObserver = nil
        
        if playerTimerReturn != nil {
            player?.removeTimeObserver(playerTimerReturn!)
            playerTimerReturn = nil
        }
        
        if observerActive {
            player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: nil) // &GlobalPlayerContext
            player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil) // &GlobalPlayerContext
            observerActive = false
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func unload()
    {
        loaded = false
        loadFailed = false
    }
    
    func updateCurrentTimeExactWhilePlaying()
    {
        if isPlaying {
            updateCurrentTimeExact()
        }
    }
    
    func updateCurrentTimeExact()
    {
        if loaded && (currentTime != nil) {
            updateCurrentTimeExact(currentTime!.seconds)
        } else {
            print("Player NOT loaded or has no currentTime.")
        }
    }
    
    func updateCurrentTimeExact(_ seekToTime:Double)
    {
        if (seekToTime >= 0) {
            playing?.currentTime = seekToTime.description
        } else {
            print("seekeToTime < 0")
        }
    }
    
    func pauseIfPlaying()
    {
        if isPlaying {
            pause()
        } else {
            print("Player NOT playing.")
        }
    }
    
    func play()
    {
        if loaded {
            //            if (playing != stateTime?.sermon) || (stateTime?.sermon == nil) {
            //                stateTime = PlayerStateTime(sermon: playing)
            //            }
            
            stateTime = PlayerStateTime(sermon: playing,state:.playing)
            
            //            stateTime?.startTime = playing?.currentTime
            //            stateTime?.state = .playing
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            })
            
            player?.play()
            
            setupPlayingInfoCenter()
        }
    }
    
    func pause()
    {
        updateCurrentTimeExact()
        stateTime = PlayerStateTime(sermon: playing,state:.paused)
        
        player?.pause()
        
        //        if (playing != stateTime?.sermon) || (stateTime?.sermon == nil) {
        //            stateTime = PlayerStateTime(sermon: playing)
        //        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_PLAYING_PAUSED), object: nil)
        })
        
        setupPlayingInfoCenter()
    }
    
    func stop()
    {
        pause()
        
        unload()
        
        unobserve()
        
        stateTime = PlayerStateTime(sermon: playing,state:.stopped)
        
        playing = nil
        player = nil
    }
    
    func seek(to: Double?)
    {
        if to != nil {
            if url != nil {
                if loaded {
                    var seek = to!
                    
                    if seek > currentItem!.duration.seconds {
                        seek = currentItem!.duration.seconds
                    }
                    
                    if seek < 0 {
                        seek = 0
                    }
                    
                    player?.seek(to: CMTimeMakeWithSeconds(seek,Constants.CMTime_Resolution), toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution), toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution))
                    
                    playing?.currentTime = seek.description
                    stateTime?.startTime = seek.description
                    
                    setupPlayingInfoCenter()
                }
            }
        }
    }
    
    var currentItem:AVPlayerItem? {
        get {
            return player?.currentItem
        }
    }
    
    var currentTime:CMTime? {
        get {
            return player?.currentTime()
        }
    }
    
    var duration:CMTime? {
        get {
            return player?.currentItem?.duration
        }
    }
    
    var state:PlayerState? {
        get {
            return stateTime?.state
        }
        set {
            if newValue != nil {
                stateTime?.state = newValue!
            }
        }
    }
    
    var startTime:String? {
        get {
            return stateTime?.startTime
        }
        set {
            stateTime?.startTime = newValue
        }
    }
    
    var rate:Float? {
        get {
            return player?.rate
        }
    }
    
    var isPlaying:Bool {
        get {
            return stateTime?.state == .playing
        }
    }
    
    var isPaused:Bool {
        get {
            return stateTime?.state == .paused
        }
    }
    
    var playOnLoad:Bool = true
    var loaded:Bool = false
    var loadFailed:Bool = false
    
    //    var observer: Timer?
    
    var playing:Sermon? {
        willSet {
            
        }
        didSet {
            if playing == nil {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_PLAYING_PAUSED), object: nil)
                })
            }
            
            let defaults = UserDefaults.standard
            if (playing != nil) {
                defaults.set("\(playing!.series!.id)", forKey: Constants.SETTINGS.PLAYING.SERIES)
                defaults.set("\(playing!.index)", forKey: Constants.SETTINGS.PLAYING.SERMON_INDEX)
            } else {
                defaults.removeObject(forKey: Constants.SETTINGS.PLAYING.SERIES)
                defaults.removeObject(forKey: Constants.SETTINGS.PLAYING.SERMON_INDEX)
            }
            defaults.synchronize()
        }
    }
    
    func logPlayerState()
    {
        stateTime?.log()
    }
}

