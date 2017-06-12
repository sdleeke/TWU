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
    
    convenience init(sermon:Sermon?)
    {
        self.init()
        self.sermon = sermon
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

class MediaPlayer {
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
            if (playing != stateTime?.sermon) || (stateTime?.sermon == nil) {
                stateTime = PlayerStateTime(sermon: playing)
            }
            
            stateTime?.startTime = playing?.currentTime
            
            stateTime?.state = .playing
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            })
            
            player?.play()
            
            globals.setupPlayingInfoCenter()
        }
    }
    
    func pause()
    {
        player?.pause()
        
        updateCurrentTimeExact()
        
        if (playing != stateTime?.sermon) || (stateTime?.sermon == nil) {
            stateTime = PlayerStateTime(sermon: playing)
        }
        
        stateTime?.state = .paused
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_PLAYING_PAUSED), object: nil)
        })
        
        globals.setupPlayingInfoCenter()
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
                    
                    globals.setupPlayingInfoCenter()
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

var globals:Globals!

class Globals : NSObject {
    let reachability = Reachability()!

    var playerTimerReturn:Any?

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
    
    func playerTimer()
    {
        // This function is only called when the media is playing
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = mediaPlayer.player != nil
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = mediaPlayer.player != nil
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = mediaPlayer.player != nil

        if (mediaPlayer.rate > 0) {
            updateCurrentTimeForPlaying()
        }
        
        if (mediaPlayer.player != nil) {
            switch mediaPlayer.state! {
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
    
    func updateCurrentTimeForPlaying()
    {
        //        assert(player?.currentItem != nil,"player?.currentItem should not be nil if we're trying to update the currentTime in userDefaults")
        assert(mediaPlayer.currentTime != nil,"currentTime should not be nil if we're trying to update the currentTime in userDefaults")
        
        if mediaPlayer.loaded && (mediaPlayer.currentTime != nil) && (mediaPlayer.duration != nil) {
            var timeNow = 0
            
            if (mediaPlayer.currentTime!.seconds > 0) && (mediaPlayer.currentTime!.seconds <= mediaPlayer.duration!.seconds) {
                timeNow = Int(mediaPlayer.currentTime!.seconds)
            }
            
            if ((timeNow > 0) && (timeNow % 10) == 0) {
                //                println("\(timeNow.description)")
                if Int(Float(mediaPlayer.playing!.currentTime!)!) != Int(mediaPlayer.currentTime!.seconds) {
                    mediaPlayer.playing?.currentTime = mediaPlayer.currentTime!.seconds.description
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
                
                if !mediaPlayer.loaded && (mediaPlayer.playing != nil) {
                    mediaPlayer.loaded = true

                    if globals.mediaPlayer.playing!.hasCurrentTime() {
                        if mediaPlayer.playing!.atEnd {
                            mediaPlayer.seek(to: mediaPlayer.duration!.seconds)
                        } else {
                            mediaPlayer.seek(to: Double(mediaPlayer.playing!.currentTime!)!)
                        }
                    } else {
                        mediaPlayer.playing!.currentTime = Constants.ZERO
                        mediaPlayer.seek(to: 0)
                    }
                    
                    if mediaPlayer.playOnLoad {
                        if mediaPlayer.playing!.atEnd {
                            mediaPlayer.playing!.currentTime = Constants.ZERO
                            mediaPlayer.seek(to: 0)
                            mediaPlayer.playing?.atEnd = false
                        }
                        mediaPlayer.playOnLoad = false
                        mediaPlayer.play()
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
                    })
                }
                
                if (mediaPlayer.url != nil) {
                    setupPlayingInfoCenter()
                }
                break
                
            case .failed:
                // Player item failed. See error.
                networkUnavailable("Media failed to load.")
                globals.mediaPlayer.loadFailed = true
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
                })
                break
                
            case .unknown:
                // Player item is not yet ready.
                if #available(iOS 10.0, *) {
                    print(mediaPlayer.player?.reasonForWaitingToPlay! as Any)
                } else {
                    // Fallback on earlier versions
                }
                break
            }
        }
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
    
    func didPlayToEnd()
    {
        //        print("didPlayToEnd",globals.mediaPlayer.playing)
        
        //        print(mediaPlayer.currentTime?.seconds)
        //        print(mediaPlayer.duration?.seconds)
        
        mediaPlayer.pause()
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        })
        
        if let duration = mediaPlayer.duration?.seconds, let currentTime = mediaPlayer.currentTime?.seconds {
            mediaPlayer.playing?.atEnd = currentTime >= (duration - 1)
            if (mediaPlayer.playing != nil) && !mediaPlayer.playing!.atEnd {
                reloadPlayer(globals.mediaPlayer.playing)
            }
        } else {
            mediaPlayer.playing?.atEnd = true
        }
        
        if autoAdvance, mediaPlayer.playing != nil, mediaPlayer.playing!.atEnd,
            let mediaItems = mediaPlayer.playing?.series?.sermons,
            let index = mediaItems.index(of: mediaPlayer.playing!), index < (mediaItems.count - 1) {
            let nextMediaItem = mediaItems[index + 1]
            nextMediaItem.currentTime = Constants.ZERO
            mediaPlayer.playing = nextMediaItem
            mediaPlayer.playOnLoad = true
            setupPlayer(nextMediaItem)
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
            })
        }
    }
    
    func observePlayer()
    {
        //        DispatchQueue.main.async(execute: { () -> Void in
        //            self.playerObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PLAYER, target: self, selector: #selector(Globals.playerTimer), userInfo: nil, repeats: true)
        //        })
        
        unobservePlayer()
        
        mediaPlayer.player?.currentItem?.addObserver(self,
                                                     forKeyPath: #keyPath(AVPlayerItem.status),
                                                     options: [.old, .new],
                                                     context: nil) // &GlobalPlayerContext
        mediaPlayer.observerActive = true
        
        mediaPlayer.playerTimerReturn = mediaPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (time:CMTime) in
            self?.playerTimer()
        })
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(Globals.didPlayToEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
        
        mediaPlayer.pause()
    }
    
    func unobservePlayer()
    {
        //        self.playerObserver?.invalidate()
        //        self.playerObserver = nil
        
        if mediaPlayer.playerTimerReturn != nil {
            mediaPlayer.player?.removeTimeObserver(mediaPlayer.playerTimerReturn!)
            mediaPlayer.playerTimerReturn = nil
        }
        
        if mediaPlayer.observerActive {
            mediaPlayer.player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil) // &GlobalPlayerContext
            mediaPlayer.observerActive = false
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func reloadPlayer(_ sermon:Sermon?)
    {
        if let url = sermon!.playingURL {
            reloadPlayer(url: url)
        }
    }
    
    func reloadPlayer(url:URL?)
    {
        if (url != nil) {
            mediaPlayer.unload()
            
            unobservePlayer()
            
            mediaPlayer.player?.replaceCurrentItem(with: AVPlayerItem(url: url!))
            
            observePlayer()
        }
    }
    
    func setupPlayer(_ sermon:Sermon?)
    {
        if (sermon != nil) {
            mediaPlayer.unload()
            
            unobservePlayer()
            
//            if playerTimerReturn != nil {
//                mediaPlayer.player?.removeTimeObserver(playerTimerReturn!)
//                playerTimerReturn = nil
//            }
//            
//            mediaPlayer.player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil) // &GlobalPlayerContext
//            
//            if globals.mediaPlayer.sliderTimerReturn != nil {
//                globals.mediaPlayer.player?.removeTimeObserver(globals.mediaPlayer.sliderTimerReturn!)
//                globals.mediaPlayer.sliderTimerReturn = nil
//            }
            
            mediaPlayer.player = AVPlayer(url: sermon!.playingURL!)

            if #available(iOS 10.0, *) {
                mediaPlayer.player?.automaticallyWaitsToMinimizeStalling = false
            } else {
                // Fallback on earlier versions
            }
            
            mediaPlayer.player?.actionAtItemEnd = .pause

            observePlayer()
            
//            mediaPlayer.player?.currentItem?.addObserver(self,
//                                             forKeyPath: #keyPath(AVPlayerItem.status),
//                                             options: [.old, .new],
//                                             context: nil) // &GlobalPlayerContext
            
//            playerTimerReturn = mediaPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (CMTime) in
//                self?.playerTimer()
//            })

            mediaPlayer.pause()
        }
    }
    
    func setupPlayerAtEnd(_ sermon:Sermon?)
    {
        setupPlayer(sermon)
        
        if (mediaPlayer.player != nil) {
            mediaPlayer.seek(to: mediaPlayer.duration!.seconds)
            mediaPlayer.pause()
            sermon?.currentTime = Float(mediaPlayer.duration!.seconds).description
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

    func setupPlayingInfoCenter()
    {
        if let title = mediaPlayer.playing?.series?.title, let index = mediaPlayer.playing?.index {
            var sermonInfo = [String:AnyObject]()
            
            sermonInfo[MPMediaItemPropertyTitle] = "\(title) (Part \(index + 1))" as AnyObject
            
            sermonInfo[MPMediaItemPropertyArtist] = Constants.Tom_Pennington as AnyObject
            
            sermonInfo[MPMediaItemPropertyAlbumTitle] = title as AnyObject
            
            sermonInfo[MPMediaItemPropertyAlbumArtist] = Constants.Tom_Pennington as AnyObject
            
            if let art = mediaPlayer.playing!.series!.loadArt() {
                sermonInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: art)
            }

            sermonInfo[MPMediaItemPropertyAlbumTrackNumber] = index + 1 as AnyObject
            
            if let numberOfSermons = mediaPlayer.playing?.series?.numberOfSermons {
                sermonInfo[MPMediaItemPropertyAlbumTrackCount] = numberOfSermons as AnyObject
            }
            
            if let duration = mediaPlayer.duration?.seconds {
                sermonInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: duration)
            }

            if let currentTime = mediaPlayer.currentTime?.seconds {
                sermonInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: currentTime)
            }
            
            if let rate = mediaPlayer.rate {
                sermonInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: rate)
            }
            
            //    println("\(sermonInfo.count)")
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = sermonInfo
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


