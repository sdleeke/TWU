//
//  Globals.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import CloudKit

enum Showing {
    case all
    case filtered
}

enum PlayerState {
    case none
    
    case paused
    case playing
    case stopped
    
    case seekingForward
    case seekingBackward
}

class PlayerStateTime {
    var sermon:Sermon?
    
    var state:PlayerState = .none
    
    var dateEntered:NSDate?
    var timeElapsed:NSTimeInterval {
        get {
            return NSDate().timeIntervalSinceDate(dateEntered!)
        }
    }
    
    init()
    {
        dateEntered = NSDate()
    }
}

var globals:Globals!

class Globals {
    //    var downloadTasks = [NSURLSessionDownloadTask]()
    //    var session:NSURLSession!
    var sorting:String? = Constants.Newest_to_Oldest {
        didSet {
            if sorting != oldValue {
                activeSeries = sortSeries(activeSeries,sorting: sorting)
                
                let defaults = NSUserDefaults.standardUserDefaults()
                if (sorting != nil) {
                    defaults.setObject(sorting,forKey: Constants.SORTING)
                } else {
                    defaults.removeObjectForKey(Constants.SORTING)
                }
                defaults.synchronize()
            }
        }
    }
    
    var filter:String? {
        didSet {
            if filter != oldValue {
                if (filter != nil) {
                    showing = .filtered
                    filteredSeries = series?.filter({ (series:Series) -> Bool in
                        return series.book == filter
                    })
                } else {
                    showing = .all
                    filteredSeries = nil
                }
                
                updateSearchResults()
                
                activeSeries = sortSeries(activeSeries,sorting: sorting)

                let defaults = NSUserDefaults.standardUserDefaults()
                if (filter != nil) {
                    defaults.setObject(filter,forKey: Constants.FILTER)
                } else {
                    defaults.removeObjectForKey(Constants.FILTER)
                }
                defaults.synchronize()
            }
        }
    }
    
    var refreshing:Bool = false
    var loading:Bool = false
    
    var seriesSettings:[String:[String:String]]?
    var sermonSettings:[String:[String:String]]?

    var mpPlayer:MPMoviePlayerController?
    
    var mpPlayerStateTime : PlayerStateTime?
    
    var playerPaused:Bool = true {
        didSet {
            if (playerPaused != oldValue) || (sermonPlaying != mpPlayerStateTime?.sermon) || (mpPlayerStateTime?.sermon == nil) {
                mpPlayerStateTime = PlayerStateTime()
                
                mpPlayerStateTime?.sermon = sermonPlaying
                
                if playerPaused {
                    mpPlayerStateTime?.state = .paused
                } else {
                    mpPlayerStateTime?.state = .playing
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                })
            }
        }
    }
    
    var playOnLoad:Bool = false
    var playerLoaded:Bool = false
    var playerLoadFailed:Bool = false
    
    var playerObserver: NSTimer?

    var gotoNowPlaying:Bool = false
    
    var searchButtonClicked = false
    var searchActive:Bool = false {
        didSet {
            if !searchActive {
                searchText = nil
                activeSeries = sortSeries(activeSeries,sorting: sorting)
            }
        }
    }

    var searchText:String? {
        didSet {
            if searchText != oldValue {
                updateSearchResults()
            }
        }
    }

    var showingAbout:Bool = false
    
    var seriesSelected:Series? {
        get {
            var seriesSelected:Series?
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let seriesSelectedStr = defaults.stringForKey(Constants.SERIES_SELECTED) {
                if let seriesSelectedID = Int(seriesSelectedStr) {
                    seriesSelected = index?[seriesSelectedID]
                }
            }
            defaults.synchronize()
            
            return seriesSelected
        }
    }
    
    var sermonPlaying:Sermon? {
        didSet {
            let defaults = NSUserDefaults.standardUserDefaults()
            if (sermonPlaying != nil) {
                defaults.setObject("\(sermonPlaying!.series!.id)", forKey: Constants.SERIES_PLAYING)
                defaults.setObject("\(sermonPlaying!.index)", forKey: Constants.SERMON_PLAYING_INDEX)
            } else {
                defaults.removeObjectForKey(Constants.SERIES_PLAYING)
                defaults.removeObjectForKey(Constants.SERMON_PLAYING_INDEX)
            }
            defaults.synchronize()
        }
    }
    
    var searchSeries:[Series]?

    var filteredSeries:[Series]?
    
    var series:[Series]? {
        didSet {
            if (series != nil) {
                index = [Int:Series]()
                for sermonSeries in series! {
                    if index![sermonSeries.id] == nil {
                        index![sermonSeries.id] = sermonSeries
                    } else {
                        print("DUPLICATE SERIES ID: \(sermonSeries)")
                    }
                }
            }
            if (filter != nil) {
                showing = .filtered
                filteredSeries = series?.filter({ (series:Series) -> Bool in
                    return series.book == filter
                })
            }
            updateSearchResults()
        }
    }
    
    var index:[Int:Series]?
    
    var showing:Showing = .all

    var seriesToSearch:[Series]? {
        get {
            switch showing {
                case .all:      return series
                case .filtered: return filteredSeries
            }
        }
    }
    
    var activeSeries:[Series]? {
        get {
            if searchActive {
                return searchSeries
            } else {
                return seriesToSearch
            }
        }
        set {
            if searchActive {
                searchSeries = newValue
            } else {
                switch showing {
                case .all:
                    series = newValue
                    break
                case .filtered:
                    filteredSeries = newValue
                    break
                }
            }
        }
    }
    
    func mpPlayerLoadStateDidChange()
    {
        print("mpPlayerLoadStateDidChange")
        
        let loadstate:UInt8 = UInt8(mpPlayer!.loadState.rawValue)
        
        let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
        let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
        
        //        if playable {
        //            print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable")
        //        }
        //
        //        if playthrough {
        //            print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playthrough")
        //        }
        
        //        print("\(loadstate)")
        //        print("\(playable)")
        //        print("\(playthrough)")
        
        if (playable || playthrough) {
            //            print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable or Playthrough OK")
            
            if !playerLoaded {
                if (sermonPlaying != nil) && sermonPlaying!.hasCurrentTime() {
                    //                    print(Int(Float(sermonPlaying!.currentTime!)!))
                    //                    print(Int(Float(mpPlayer!.duration)))
                    if (Int(Float(sermonPlaying!.currentTime!)!) == Int(Float(mpPlayer!.duration))) {
                        sermonPlaying!.currentTime = Constants.ZERO
                    } else {
                        mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(sermonPlaying!.currentTime!)!)
                    }
                } else {
                    sermonPlaying?.currentTime = Constants.ZERO
                    mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                }
                
                setupPlayingInfoCenter()
                
                playerLoaded = true
                
                if (playOnLoad) {
                    playerPaused = false
                    mpPlayer?.play()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    })
                } else {
                    playOnLoad = true
                }
            }
        }
        
        if !(playable || playthrough) && (mpPlayerStateTime?.state == .playing) && (mpPlayerStateTime?.timeElapsed > Constants.MIN_PLAY_TIME) {
            //            print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable or Playthrough NOT OK")
            
            playerPaused = true
            mpPlayer?.pause()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
            })
        }
        
        //        switch mpPlayer!.playbackState {
        //        case .Playing:
        //            print("mpPlayerLoadStateDidChange.Playing")
        //            break
        //
        //        case .SeekingBackward:
        //            print("mpPlayerLoadStateDidChange.SeekingBackward")
        //            break
        //
        //        case .SeekingForward:
        //            print("mpPlayerLoadStateDidChange.SeekingForward")
        //            break
        //
        //        case .Stopped:
        //            print("mpPlayerLoadStateDidChange.Stopped")
        //            break
        //
        //        case .Interrupted:
        //            print("mpPlayerLoadStateDidChange.Interrupted")
        //            break
        //
        //        case .Paused:
        //            print("mpPlayerLoadStateDidChange.Paused")
        //            break
        //        }
    }
    
    func playerTimer()
    {
        if (mpPlayer != nil) {
            let loadstate:UInt8 = UInt8(mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
            
            //            if playable {
            //                print("playTimer.MPMovieLoadState.Playable")
            //            }
            //
            //            if playthrough {
            //                print("playTimer.MPMovieLoadState.Playthrough")
            //            }
            
            if (mpPlayer!.fullscreen) {
                mpPlayer?.controlStyle = MPMovieControlStyle.Embedded // Fullscreen
            } else {
                mpPlayer?.controlStyle = MPMovieControlStyle.None
            }
            
            if (mpPlayer?.currentPlaybackRate > 0) {
                updateCurrentTimeWhilePlaying()
            }
            
            switch mpPlayerStateTime!.state {
            case .none:
                //                print("none")
                break
                
            case .playing:
                //                print("playing")
                switch mpPlayer!.playbackState {
                case .SeekingBackward:
                    //                    print("playTimer.SeekingBackward")
                    mpPlayerStateTime!.state = .seekingBackward
                    break
                    
                case .SeekingForward:
                    //                    print("playTimer.SeekingForward")
                    mpPlayerStateTime!.state = .seekingForward
                    break
                    
                default:
                    if (UIApplication.sharedApplication().applicationState != UIApplicationState.Background) {
                        if (mpPlayer!.duration > 0) && (mpPlayer!.currentPlaybackTime > 0) &&
                            (Int(Float(sermonPlaying!.currentTime!)!) == Int(Float(mpPlayer!.duration))) {
                            mpPlayer?.pause()
                            playerPaused = true
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                            })
                            
                            if (sermonPlaying?.currentTime != mpPlayer!.duration.description) {
                                sermonPlaying?.currentTime = mpPlayer!.duration.description
                            }
                        } else {
                            mpPlayer?.play()
                        }
                        
                        if !(playable || playthrough) { // mpPlayer?.currentPlaybackRate == 0
                            //                            print("playTimer.Playthrough or Playing NOT OK")
                            if (mpPlayerStateTime!.timeElapsed > Constants.MIN_PLAY_TIME) {
                                playerPaused = true
                                mpPlayer?.pause()
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                                })
                                
                                let errorAlert = UIAlertView(title: "Unable to Play Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                                errorAlert.show()
                            }
                        }
                        
                        if (playable || playthrough) {
                            //                            print("playTimer.Playthrough or Playing OK")
                        }
                    }
                    break
                }
                break
                
            case .paused:
                //                print("paused")
                
                if !playerLoaded && !playerLoadFailed {
                    if (mpPlayerStateTime!.timeElapsed > Constants.MIN_LOAD_TIME) {
                        playerLoadFailed = true
                        
                        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                            let errorAlert = UIAlertView(title: "Unable to Load Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                            errorAlert.show()
                        }
                    }
                }
                
                switch mpPlayer!.playbackState {
                case .Paused:
                    //                    print("playTimer.Paused")
                    break
                    
                default:
                    mpPlayer?.pause()
                    break
                }
                break
                
            case .stopped:
                print("stopped")
                break
                
            case .seekingForward:
                //                print("seekingForward")
                switch mpPlayer!.playbackState {
                case .Playing:
                    //                    print("playTimer.Playing")
                    mpPlayerStateTime!.state = .playing
                    break
                    
                case .Paused:
                    //                    print("playTimer.Paused")
                    mpPlayerStateTime!.state = .playing
                    break
                    
                default:
                    break
                }
                break
                
            case .seekingBackward:
                //                print("seekingBackward")
                switch mpPlayer!.playbackState {
                case .Playing:
                    //                    print("playTimer.Playing")
                    mpPlayerStateTime!.state = .playing
                    break
                    
                case .Paused:
                    //                    print("playTimer.Paused")
                    mpPlayerStateTime!.state = .playing
                    break
                    
                default:
                    break
                }
                break
            }
            
            //            if (mpPlayer != nil) {
            //                switch mpPlayer!.playbackState {
            //                case .Interrupted:
            //                    print("playTimer.Interrupted")
            //                    break
            //
            //                case .Paused:
            //                    print("playTimer.Paused")
            //                    break
            //                    
            //                case .Playing:
            //                    print("playTimer.Playing")
            //                    break
            //                    
            //                case .SeekingBackward:
            //                    print("playTimer.SeekingBackward")
            //                    break
            //                    
            //                case .SeekingForward:
            //                    print("playTimer.SeekingForward")
            //                    break
            //                    
            //                case .Stopped:
            //                    print("playTimer.Stopped")
            //                    break
            //                }
            //            }
        }
    }
    
    func loadDefaults()
    {
        loadSettings()
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let sorting = defaults.stringForKey(Constants.SORTING) {
            self.sorting = sorting
        }
        
        if let filter = defaults.stringForKey(Constants.FILTER) {
            if (filter == Constants.All) {
                self.filter = nil
                self.showing = .all
            } else {
                self.filter = filter
                self.showing = .filtered
            }
        }
        
        if let seriesPlayingIDStr = defaults.stringForKey(Constants.SERIES_PLAYING) {
            if let seriesPlayingID = Int(seriesPlayingIDStr) {
                if let index = series?.indexOf({ (series) -> Bool in
                    return series.id == seriesPlayingID
                }) {
                    let seriesPlaying = series?[index]
                    
                    if let sermonPlayingIndexStr = defaults.stringForKey(Constants.SERMON_PLAYING_INDEX) {
                        if let sermonPlayingIndex = Int(sermonPlayingIndexStr) {
                            if (sermonPlayingIndex > (seriesPlaying!.show - 1)) {
                                sermonPlaying = nil
                            } else {
                                sermonPlaying = seriesPlaying?.sermons?[sermonPlayingIndex]
                            }
                        }
                    }
                } else {
                    defaults.removeObjectForKey(Constants.SERIES_PLAYING)
                }
            }
        }
    }
    
    func updateSearchResults()
    {
        if searchActive && (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
            searchSeries = seriesToSearch?.filter({ (series:Series) -> Bool in
                var seriesResult = false
                
                if series.title != nil {
                    seriesResult = seriesResult ||
                        ((series.title!.rangeOfString(searchText!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                }
                if series.name != nil {
                    seriesResult = seriesResult ||
                        ((series.scripture!.rangeOfString(searchText!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                }
                
                return seriesResult
                
                //                return ((series.title.rangeOfString(searchBar.text!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                //                    ((series.scripture.rangeOfString(searchBar.text!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
            })
        } else {
            searchSeries = nil
        }
    }
    
    func saveSettingsBackground()
    {
        print("saveSermonSettingsBackground")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            self.saveSettings()
        }
    }
    
    func saveSettings()
    {
        print("saveSermonSettings")
        let defaults = NSUserDefaults.standardUserDefaults()
        //    print("\(sermonSettings)")
        defaults.setObject(seriesSettings,forKey: Constants.SERIES_SETTINGS_KEY)
        defaults.setObject(sermonSettings,forKey: Constants.SERMON_SETTINGS_KEY)
        defaults.synchronize()
    }
    
    func loadSettings()
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let settingsDictionary = defaults.dictionaryForKey(Constants.SERIES_SETTINGS_KEY) {
            //        print("\(settingsDictionary)")
            seriesSettings = settingsDictionary as? [String:[String:String]]
        }
        
        if (seriesSettings == nil) {
            seriesSettings = [String:[String:String]]()
        }
        
        if let settingsDictionary = defaults.dictionaryForKey(Constants.SERMON_SETTINGS_KEY) {
            //        print("\(settingsDictionary)")
            sermonSettings = settingsDictionary as? [String:[String:String]]
        }
        
        if (sermonSettings == nil) {
            sermonSettings = [String:[String:String]]()
        }
        
        //    print("\(sermonSettings)")
    }
    
    func updateCurrentTimeWhilePlaying()
    {
        //        assert(player?.currentItem != nil,"player?.currentItem should not be nil if we're trying to update the currentTime in userDefaults")
        assert(mpPlayer != nil,"mpPlayer should not be nil if we're trying to update the currentTime in userDefaults")
        
        if (mpPlayer != nil) {
            //            let timeNow = Int64(player!.currentTime().value) / Int64(player!.currentTime().timescale)
            
            var timeNow = 0
            
            if (mpPlayer?.playbackState == .Playing) {
                if (mpPlayer!.currentPlaybackTime > 0) && (mpPlayer!.currentPlaybackTime <= mpPlayer!.duration) {
                    timeNow = Int(mpPlayer!.currentPlaybackTime)
                }
                
                if ((timeNow > 0) && (timeNow % 10) == 0) {
                    //                println("\(timeNow.description)")
                    sermonPlaying?.currentTime = mpPlayer!.currentPlaybackTime.description
                }
            }
        }
    }
    
    func updateCurrentTimeExact()
    {
        if (mpPlayer != nil) {
            updateCurrentTimeExact(mpPlayer!.currentPlaybackTime)
        }
    }
    
    func updateCurrentTimeExact(seekToTime:NSTimeInterval)
    {
        if (seekToTime >= 0) {
            sermonPlaying?.currentTime = seekToTime.description
        }
    }
    
    func setupPlayer(sermon:Sermon?)
    {
        if (sermon != nil) {
            playerLoaded = false
            playerLoadFailed = false
            
            mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL)
            
            mpPlayer?.shouldAutoplay = false
            mpPlayer?.controlStyle = MPMovieControlStyle.None
            mpPlayer?.prepareToPlay()
            
            setupPlayingInfoCenter()
            
            playerPaused = true
        }
    }
    
    func setupPlayerAtEnd(sermon:Sermon?)
    {
        setupPlayer(sermon)
        
        if (mpPlayer != nil) {
            mpPlayer?.currentPlaybackTime = mpPlayer!.duration
            mpPlayer?.pause()
        }
    }
    
    func motionEnded(motion: UIEventSubtype, event: UIEvent?) {
        if (motion == .MotionShake) {
            if (sermonPlaying != nil) {
                if (playerPaused) {
                    mpPlayer?.play()
                } else {
                    mpPlayer?.pause()
                    updateCurrentTimeExact()
                }
                playerPaused = !playerPaused
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                })
            }
        }
    }

    func addAccessoryEvents()
    {
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPause")
            self.mpPlayer?.pause()
            self.playerPaused = true
            self.updateCurrentTimeExact()
            self.setupPlayingInfoCenter()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
            })
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().stopCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().stopCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPlay")
            self.mpPlayer?.play()
            self.playerPaused = false
            self.setupPlayingInfoCenter()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
            })
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlTogglePlayPause")
            if (self.playerPaused) {
                self.mpPlayer?.play()
            } else {
                self.mpPlayer?.pause()
                self.updateCurrentTimeExact()
            }
            self.playerPaused = !self.playerPaused
            self.setupPlayingInfoCenter()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
            })
            return MPRemoteCommandHandlerStatus.Success
        }
        
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        //        self.mpPlayer?.beginSeekingBackward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        //
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        //        self.mpPlayer?.beginSeekingForward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        
        MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.mpPlayer?.currentPlaybackTime -= NSTimeInterval(15)
            self.updateCurrentTimeExact()
            self.setupPlayingInfoCenter()
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.mpPlayer?.currentPlaybackTime += NSTimeInterval(15)
            self.updateCurrentTimeExact()
            self.setupPlayingInfoCenter()
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = false
        
        MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = false
        
        MPRemoteCommandCenter.sharedCommandCenter().changePlaybackRateCommand.enabled = false
        
        MPRemoteCommandCenter.sharedCommandCenter().ratingCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().likeCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().dislikeCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().bookmarkCommand.enabled = false
    }
    
    func setupPlayingInfoCenter()
    {
        if (sermonPlaying != nil) {
            var sermonInfo = [String:AnyObject]()
            
            sermonInfo.updateValue(sermonPlaying!.series!.title! + " (Part \(sermonPlaying!.index + 1))",    forKey: MPMediaItemPropertyTitle)
            sermonInfo.updateValue(Constants.Tom_Pennington,                                                            forKey: MPMediaItemPropertyArtist)
            
            sermonInfo.updateValue(sermonPlaying!.series!.title!,                                                forKey: MPMediaItemPropertyAlbumTitle)
            sermonInfo.updateValue(Constants.Tom_Pennington,                                                            forKey: MPMediaItemPropertyAlbumArtist)
            sermonInfo.updateValue(MPMediaItemArtwork(image: sermonPlaying!.series!.getArt()!),                        forKey: MPMediaItemPropertyArtwork)
            
            sermonInfo.updateValue(sermonPlaying!.index + 1,                                                forKey: MPMediaItemPropertyAlbumTrackNumber)
            sermonInfo.updateValue(sermonPlaying!.series!.numberOfSermons,                                      forKey: MPMediaItemPropertyAlbumTrackCount)
            
            if (mpPlayer != nil) {
                sermonInfo.updateValue(NSNumber(double: mpPlayer!.duration),                                forKey: MPMediaItemPropertyPlaybackDuration)
                sermonInfo.updateValue(NSNumber(double: mpPlayer!.currentPlaybackTime),                     forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
                
                sermonInfo.updateValue(NSNumber(float:mpPlayer!.currentPlaybackRate),                       forKey: MPNowPlayingInfoPropertyPlaybackRate)
            }
            
            //    println("\(sermonInfo.count)")
            
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
        }
    }
}


