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

var globals:Globals!

class Globals : NSObject {
    let reachability = Reachability()!

//    var playerTimerReturn:Any?

    var sorting:String? = Constants.Sorting.Newest_to_Oldest {
        willSet {
            
        }
        didSet {
            if sorting != oldValue {
                activeSeries = sortSeries(activeSeries,sorting: sorting)
                
                let defaults = UserDefaults.standard
                if (sorting != nil) {
                    defaults.set(sorting,forKey: Constants.SORTING)
                } else {
                    defaults.removeObject(forKey: Constants.SORTING)
                }
                defaults.synchronize()
            }
        }
    }
    
    var filter:String? {
        willSet {
            
        }
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

                let defaults = UserDefaults.standard
                if (filter != nil) {
                    defaults.set(filter,forKey: Constants.FILTER)
                } else {
                    defaults.removeObject(forKey: Constants.FILTER)
                }
                defaults.synchronize()
            }
        }
    }
    
    var isRefreshing:Bool   = false
    var isLoading:Bool      = false
    
    var seriesSettings:[String:[String:String]]?
    var sermonSettings:[String:[String:String]]?

    var mediaPlayer = MediaPlayer()
    
    var gotoNowPlaying:Bool = false
    
    var searchButtonClicked = false

    var searchActive:Bool = false {
        willSet {
            
        }
        didSet {
            if !searchActive {
                searchText = nil
                activeSeries = sortSeries(activeSeries,sorting: sorting)
            }
        }
    }
    
    var searchValid:Bool {
        get {
            return searchActive && (searchText != nil) && (searchText != Constants.EMPTY_STRING)
        }
    }
    
    var searchSeries:[Series]?
    
    var searchText:String?
//    {
//        didSet {
//            if searchText != oldValue {
//                updateSearchResults()
//            }
//        }
//    }

    var showingAbout:Bool = false
    
    var seriesSelected:Series? {
        get {
            var seriesSelected:Series?
            
            let defaults = UserDefaults.standard
            if let seriesSelectedStr = defaults.string(forKey: Constants.SETTINGS.SELECTED.SERIES) {
                if let seriesSelectedID = Int(seriesSelectedStr) {
                    seriesSelected = index?[seriesSelectedID]
                }
            }
            defaults.synchronize()
            
            return seriesSelected
        }
    }
    
    var filteredSeries:[Series]?
    
    var series:[Series]? {
        willSet {
            
        }
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
    
    func cancelAllDownloads()
    {
        if (series != nil) {
            for series in series! {
                if series.sermons != nil {
                    for sermon in series.sermons! {
                        if sermon.audioDownload.active {
                            sermon.audioDownload.task?.cancel()
                            sermon.audioDownload.task = nil
                            
                            sermon.audioDownload.totalBytesWritten = 0
                            sermon.audioDownload.totalBytesExpectedToWrite = 0
                            
                            sermon.audioDownload.state = .none
                        }
                    }
                }
            }
        }
    }
    
    func updateSearchResults()
    {
        if searchActive { //  && (searchText != nil) && (searchText != Constants.EMPTY_STRING)
            searchSeries = seriesToSearch?.filter({ (series:Series) -> Bool in
                guard let searchText = searchText else {
                    return false
                }
                
                var seriesResult = false
                
                if let string = series.title  {
                    seriesResult = seriesResult || ((string.range(of: searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil)
                }
                
                if let string = series.scripture {
                    seriesResult = seriesResult || ((string.range(of: searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil)
                }
                
                return seriesResult
            })
            
            // Filter will return an empty array and we don't want that.
            
            if searchSeries?.count == 0 {
                searchSeries = nil
            }
        } else {
            searchSeries = seriesToSearch
        }
    }
    
    func saveSettingsBackground()
    {
        print("saveSermonSettingsBackground")
        DispatchQueue.global(qos: .background).async { () -> Void in
            self.saveSettings()
        }
    }
    
    func saveSettings()
    {
        print("saveSermonSettings")
        let defaults = UserDefaults.standard
        //    print("\(sermonSettings)")
        defaults.set(seriesSettings,forKey: Constants.SETTINGS.KEY.SERIES)
        defaults.set(sermonSettings,forKey: Constants.SETTINGS.KEY.SERMON)
        defaults.synchronize()
    }
    
    func loadSettings()
    {
        let defaults = UserDefaults.standard
        
        if let settingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.SERIES) {
            //        print("\(settingsDictionary)")
            seriesSettings = settingsDictionary as? [String:[String:String]]
        }
        
        if let settingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.SERMON) {
            //        print("\(settingsDictionary)")
            sermonSettings = settingsDictionary as? [String:[String:String]]
        }
        
        if let sorting = defaults.string(forKey: Constants.SORTING) {
            self.sorting = sorting
        }
        
        if let filter = defaults.string(forKey: Constants.FILTER) {
            if (filter == Constants.All) {
                self.filter = nil
                self.showing = .all
            } else {
                self.filter = filter
                self.showing = .filtered
            }
        }
        
        if let seriesPlayingIDStr = defaults.string(forKey: Constants.SETTINGS.PLAYING.SERIES) {
            if let seriesPlayingID = Int(seriesPlayingIDStr) {
                if let index = series?.index(where: { (series) -> Bool in
                    return series.id == seriesPlayingID
                }) {
                    let seriesPlaying = series?[index]
                    
                    if let sermonPlayingIndexStr = defaults.string(forKey: Constants.SETTINGS.PLAYING.SERMON_INDEX) {
                        if let sermonPlayingIndex = Int(sermonPlayingIndexStr) {
                            if (sermonPlayingIndex > (seriesPlaying!.show - 1)) {
                                mediaPlayer.playing = nil
                            } else {
                                mediaPlayer.playing = seriesPlaying?.sermons?[sermonPlayingIndex]
                            }
                        }
                    }
                } else {
                    defaults.removeObject(forKey: Constants.SETTINGS.PLAYING.SERIES)
                }
            }
        }

        //    print("\(sermonSettings)")
    }
    
    var autoAdvance:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.AUTO_ADVANCE)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.AUTO_ADVANCE)
            UserDefaults.standard.synchronize()
        }
    }
    
    func motionEnded(_ motion: UIEventSubtype, event: UIEvent?) {
        if (motion == .motionShake) {
            if (mediaPlayer.playing != nil) {
                switch mediaPlayer.state! {
                case .paused:
                    mediaPlayer.play()
                    break
                    
                default:
                    mediaPlayer.pause()
                    break
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_PLAY_PAUSE), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_PLAYING_PAUSED), object: nil)
                })
            }
        }
    }

    func addAccessoryEvents()
    {
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPlay")
            self.mediaPlayer.play()
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPause")
            self.mediaPlayer.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlTogglePlayPause")
            if self.mediaPlayer.isPaused {
                self.mediaPlayer.play()
            } else {
                self.mediaPlayer.pause()
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().stopCommand.isEnabled = true
        MPRemoteCommandCenter.shared().stopCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlStop")
            self.mediaPlayer.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.mediaPlayer.player?.beginSeekingBackward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        //
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.mediaPlayer.player?.beginSeekingForward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.mediaPlayer.seek(to: self.mediaPlayer.currentTime!.seconds - 15)
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.mediaPlayer.seek(to: self.mediaPlayer.currentTime!.seconds + 15)
            return MPRemoteCommandHandlerStatus.success
        })
        
        if #available(iOS 9.1, *) {
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
                NSLog("MPChangePlaybackPositionCommand")
                self.mediaPlayer.seek(to: (event as! MPChangePlaybackPositionCommandEvent).positionTime)
                return MPRemoteCommandHandlerStatus.success
            })
        } else {
            // Fallback on earlier versions
        }
        
        MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = false
        MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = false
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().changePlaybackRateCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().ratingCommand.isEnabled = false
        MPRemoteCommandCenter.shared().likeCommand.isEnabled = false
        MPRemoteCommandCenter.shared().dislikeCommand.isEnabled = false
        MPRemoteCommandCenter.shared().bookmarkCommand.isEnabled = false
    }
}


