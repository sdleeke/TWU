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

struct Player {
    var mpPlayer:MPMoviePlayerController?
    var stateTime : PlayerStateTime?
    
    var paused:Bool = true {
        didSet {
            if (paused != oldValue) || (playing != stateTime?.sermon) || (stateTime?.sermon == nil) {
                stateTime = PlayerStateTime()
                stateTime?.sermon = playing
                
                if paused {
                    stateTime?.state = .paused
                } else {
                    stateTime?.state = .playing
                }
            }
        }
    }
    
    var playOnLoad:Bool = true
    var loaded:Bool = false
    var loadFailed:Bool = false
    
    var observer: NSTimer?
    
    var playing:Sermon? {
        didSet {
            if playing == nil {
                mpPlayer = nil
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                })
            }
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if (playing != nil) {
                defaults.setObject("\(playing!.series!.id)", forKey: Constants.SERIES_PLAYING)
                defaults.setObject("\(playing!.index)", forKey: Constants.SERMON_PLAYING_INDEX)
            } else {
                defaults.removeObjectForKey(Constants.SERIES_PLAYING)
                defaults.removeObjectForKey(Constants.SERMON_PLAYING_INDEX)
            }
            defaults.synchronize()
        }
    }
    
    func logMPPlayerState()
    {
        if (mpPlayer != nil) {
            var stateName:String?
            
            switch mpPlayer!.playbackState {
            case .Interrupted:
                stateName = "Interrupted"
                break
                
            case .Paused:
                stateName = "Paused"
                break
                
            case .Playing:
                stateName = "Playing"
                break
                
            case .SeekingForward:
                stateName = "SeekingForward"
                break
                
            case .SeekingBackward:
                stateName = "SeekingBackward"
                break
                
            case .Stopped:
                stateName = "Stopped"
                break
            }
            
            if (stateName != nil) {
                print(stateName!)
            }
        }
    }
    
    func logPlayerState()
    {
        stateTime?.log()
    }
}

var globals:Globals!

class Globals {
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

    var player = Player()
    
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
            case .all:
                return series
                
            case .filtered:
                return filteredSeries
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
        
        let loadstate:UInt8 = UInt8(player.mpPlayer!.loadState.rawValue)
        
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
            
            if !player.loaded {
                if (player.playing != nil) && player.playing!.hasCurrentTime() {
                    //                    print(Int(Float(sermonPlaying!.currentTime!)!))
                    //                    print(Int(Float(mpPlayer!.duration)))
                    if (Int(Float(player.playing!.currentTime!)!) == Int(Float(player.mpPlayer!.duration))) {
                        player.playing!.currentTime = Constants.ZERO
                    } else {
                        player.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(player.playing!.currentTime!)!)
                    }
                } else {
                    player.playing?.currentTime = Constants.ZERO
                    player.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                }
                
                player.loaded = true
                
                if (player.playOnLoad) {
                    player.paused = false
                    player.mpPlayer?.play()
                }
                
                setupPlayingInfoCenter()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                })
            }
        }
        
        if !(playable || playthrough) && (player.stateTime?.state == .playing) && (player.stateTime?.timeElapsed > Constants.MIN_PLAY_TIME) {
            //            print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable or Playthrough NOT OK")
            
            player.paused = true
            player.mpPlayer?.pause()
            
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
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = player.mpPlayer != nil
        MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.enabled = player.mpPlayer != nil
        MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = player.mpPlayer != nil

        if (player.mpPlayer != nil) {
            let loadstate:UInt8 = UInt8(player.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
            
            //            if playable {
            //                print("playTimer.MPMovieLoadState.Playable")
            //            }
            //
            //            if playthrough {
            //                print("playTimer.MPMovieLoadState.Playthrough")
            //            }
            
            if (player.mpPlayer!.fullscreen) {
                player.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded // Fullscreen
            } else {
                player.mpPlayer?.controlStyle = MPMovieControlStyle.None
            }
            
            if (player.mpPlayer?.currentPlaybackRate > 0) {
                updateCurrentTimeWhilePlaying()
            }

//            player.logPlayerState()
//            player.logMPPlayerState()

            switch player.stateTime!.state {
            case .none:
                //                print("none")
                break
                
            case .playing:
                //                print("playing")
                switch player.mpPlayer!.playbackState {
                case .SeekingBackward:
                    //                    print("playTimer.SeekingBackward")
                    player.stateTime!.state = .seekingBackward
                    break
                    
                case .SeekingForward:
                    //                    print("playTimer.SeekingForward")
                    player.stateTime!.state = .seekingForward
                    break
                    
                case .Paused:
                    //                    print("playTimer.playing.Paused")
                    updateCurrentTimeExact()
                    player.paused = true
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    })
//                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
//                    } else {
//                        mpPlayer?.play()
//                    }
                    break
                    
                default:
                    if !(playable || playthrough) { // mpPlayer?.currentPlaybackRate == 0
                        //                        print("playTimer.Playthrough or Playing NOT OK")
                        if (player.stateTime!.timeElapsed > Constants.MIN_PLAY_TIME) {
                            //                            sermonLoaded = false
                            player.paused = true
                            player.mpPlayer?.pause()
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                            })
                            
                            let errorAlert = UIAlertView(title: "Unable to Play Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                            errorAlert.show()
                        } else {
                            // Wait so the player can keep trying.
                        }
                    } else {
                        //                        print("playTimer.Playthrough or Playing OK")
                        if (player.mpPlayer!.duration > 0) && (player.mpPlayer!.currentPlaybackTime > 0) &&
                            (Int(Float(player.mpPlayer!.currentPlaybackTime)) == Int(Float(player.mpPlayer!.duration))) {
                            player.mpPlayer?.pause()
                            player.paused = true
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                            })
                            
                            if (player.playing?.currentTime != player.mpPlayer!.duration.description) {
                                player.playing?.currentTime = player.mpPlayer!.duration.description
                            }
//                        } else {
//                            player.mpPlayer?.play()
                        }
                    }
                    break
                }
                break
                
            case .paused:
                //                print("paused")
                
                if !player.loaded && !player.loadFailed {
                    if (player.stateTime!.timeElapsed > Constants.MIN_LOAD_TIME) {
                        player.loadFailed = true
                        
                        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                            let errorAlert = UIAlertView(title: "Unable to Load Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                            errorAlert.show()
                        }
                    }
                }
                
                switch player.mpPlayer!.playbackState {
                case .Playing:
                    //                    print("playTimer.paused.Playing")
                    player.paused = false
                    break
                    
                case .Paused:
                    //                    print("playTimer.Paused")
                    break
                    
                default:
                    player.mpPlayer?.pause()
                    break
                }
                break
                
            case .stopped:
                //                print("stopped")
                break
                
            case .seekingForward:
                //                print("seekingForward")
                switch player.mpPlayer!.playbackState {
                case .Playing:
                    //                    print("playTimer.Playing")
                    player.stateTime!.state = .playing
                    break
                    
                case .Paused:
                    //                    print("playTimer.Paused")
                    player.stateTime!.state = .playing
                    break
                    
                default:
                    break
                }
                break
                
            case .seekingBackward:
                //                print("seekingBackward")
                switch player.mpPlayer!.playbackState {
                case .Playing:
                    //                    print("playTimer.Playing")
                    player.stateTime!.state = .playing
                    break
                    
                case .Paused:
                    //                    print("playTimer.Paused")
                    player.stateTime!.state = .playing
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

    func updateSearchResults()
    {
        if searchActive && (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
            searchSeries = seriesToSearch?.filter({ (series:Series) -> Bool in
                var seriesResult = false
                
                if series.title != nil {
                    seriesResult = seriesResult ||
                        ((series.title!.rangeOfString(searchText!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                }
                if series.scripture != nil {
                    seriesResult = seriesResult ||
                        ((series.scripture!.rangeOfString(searchText!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                }
                
                return seriesResult
            })
            
            // Filter will return an empty array and we don't want that.
            if searchSeries?.count == 0 {
                searchSeries = nil
            }
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
        
        if let settingsDictionary = defaults.dictionaryForKey(Constants.SERMON_SETTINGS_KEY) {
            //        print("\(settingsDictionary)")
            sermonSettings = settingsDictionary as? [String:[String:String]]
        }
        
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
                                player.playing = nil
                            } else {
                                player.playing = seriesPlaying?.sermons?[sermonPlayingIndex]
                            }
                        }
                    }
                } else {
                    defaults.removeObjectForKey(Constants.SERIES_PLAYING)
                }
            }
        }
        
        if (seriesSettings == nil) {
            seriesSettings = [String:[String:String]]()
        }
        
        if (sermonSettings == nil) {
            sermonSettings = [String:[String:String]]()
        }

        //    print("\(sermonSettings)")
    }
    
    func updateCurrentTimeWhilePlaying()
    {
        //        assert(player?.currentItem != nil,"player?.currentItem should not be nil if we're trying to update the currentTime in userDefaults")
        assert(player.mpPlayer != nil,"mpPlayer should not be nil if we're trying to update the currentTime in userDefaults")
        
        if (player.mpPlayer != nil) {
            //            let timeNow = Int64(player!.currentTime().value) / Int64(player!.currentTime().timescale)
            
            var timeNow = 0
            
            if (player.mpPlayer?.playbackState == .Playing) {
                if (player.mpPlayer!.currentPlaybackTime > 0) && (player.mpPlayer!.currentPlaybackTime <= player.mpPlayer!.duration) {
                    timeNow = Int(player.mpPlayer!.currentPlaybackTime)
                }
                
                if ((timeNow > 0) && (timeNow % 10) == 0) {
                    //                println("\(timeNow.description)")
                    if Int(Float(player.playing!.currentTime!)!) != Int(player.mpPlayer!.currentPlaybackTime) {
                        player.playing?.currentTime = player.mpPlayer!.currentPlaybackTime.description
                    }
                }
            }
        }
    }
    
    func updateCurrentTimeExact()
    {
        if (player.mpPlayer != nil) {
            updateCurrentTimeExact(player.mpPlayer!.currentPlaybackTime)
        }
    }
    
    func updateCurrentTimeExact(seekToTime:NSTimeInterval)
    {
        if (seekToTime >= 0) {
            player.playing?.currentTime = seekToTime.description
        }
    }
    
    func setupPlayer(sermon:Sermon?)
    {
        if (sermon != nil) {
            player.loaded = false
            player.loadFailed = false
            
            player.mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL)
            
            player.mpPlayer?.shouldAutoplay = false
            player.mpPlayer?.controlStyle = MPMovieControlStyle.None
            player.mpPlayer?.prepareToPlay()
            
            player.paused = true
        }
    }
    
    func setupPlayerAtEnd(sermon:Sermon?)
    {
        setupPlayer(sermon)
        
        if (player.mpPlayer != nil) {
            player.mpPlayer?.currentPlaybackTime = player.mpPlayer!.duration
            player.mpPlayer?.pause()
        }
    }
    
    func motionEnded(motion: UIEventSubtype, event: UIEvent?) {
        if (motion == .MotionShake) {
            if (player.playing != nil) {
                if (player.paused) {
                    player.mpPlayer?.play()
                } else {
                    player.mpPlayer?.pause()
                    updateCurrentTimeExact()
                }
                player.paused = !player.paused
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                })
            }
        }
    }

    func setupPlayingInfoCenter()
    {
        if (player.playing != nil) {
            var sermonInfo = [String:AnyObject]()
            
            sermonInfo.updateValue(player.playing!.series!.title! + " (Part \(player.playing!.index + 1))",    forKey: MPMediaItemPropertyTitle)
            sermonInfo.updateValue(Constants.Tom_Pennington,                                                            forKey: MPMediaItemPropertyArtist)
            
            sermonInfo.updateValue(player.playing!.series!.title!,                                                forKey: MPMediaItemPropertyAlbumTitle)
            sermonInfo.updateValue(Constants.Tom_Pennington,                                                            forKey: MPMediaItemPropertyAlbumArtist)
            sermonInfo.updateValue(MPMediaItemArtwork(image: player.playing!.series!.getArt()!),                        forKey: MPMediaItemPropertyArtwork)
            
            sermonInfo.updateValue(player.playing!.index + 1,                                                forKey: MPMediaItemPropertyAlbumTrackNumber)
            sermonInfo.updateValue(player.playing!.series!.numberOfSermons,                                      forKey: MPMediaItemPropertyAlbumTrackCount)
            
            if (player.mpPlayer != nil) {
                sermonInfo.updateValue(NSNumber(double: player.mpPlayer!.duration),                                forKey: MPMediaItemPropertyPlaybackDuration)
                sermonInfo.updateValue(NSNumber(double: player.mpPlayer!.currentPlaybackTime),                     forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
                
                sermonInfo.updateValue(NSNumber(float:player.mpPlayer!.currentPlaybackRate),                       forKey: MPNowPlayingInfoPropertyPlaybackRate)
            }
            
            //    println("\(sermonInfo.count)")
            
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
        }
    }

    func addAccessoryEvents()
    {
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPause")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.player.mpPlayer?.pause()
                    self.player.paused = true
                    self.updateCurrentTimeExact()
                    self.setupPlayingInfoCenter()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                    })
                } else {
                    // Shouldn't be able to happen.
                }
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().stopCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().stopCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlStop")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.updateCurrentTimeExact()
                }
                
                self.player.mpPlayer?.stop()
                self.player.paused = true
                
                self.setupPlayingInfoCenter()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                })
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPlay")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.player.mpPlayer?.play()
                    self.player.paused = false
                    
                    self.setupPlayingInfoCenter()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                    })
                } else {
                    // Need to play new sermon which may take a new notification.
                }
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlTogglePlayPause")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    if (self.player.paused) {
                        self.player.mpPlayer?.play()
                    } else {
                        self.player.mpPlayer?.pause()
                        self.updateCurrentTimeExact()
                    }
                    self.player.paused = !self.player.paused
                    self.setupPlayingInfoCenter()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                    })
                } else {
                    // Need to play new sermon which may take a new notification.
                }
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.player.mpPlayer?.beginSeekingBackward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        //
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.player.mpPlayer?.beginSeekingForward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        
        MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            if (self.player.playing != nil) && self.player.loaded {
                self.player.mpPlayer?.currentPlaybackTime -= NSTimeInterval(15)
                self.updateCurrentTimeExact()
                self.setupPlayingInfoCenter()
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            if (self.player.playing != nil) && self.player.loaded {
                self.player.mpPlayer?.currentPlaybackTime += NSTimeInterval(15)
                self.updateCurrentTimeExact()
                self.setupPlayingInfoCenter()
            }
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
}


