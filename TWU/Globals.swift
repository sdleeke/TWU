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

extension UIBarButtonItem {
    func setTitleTextAttributes(_ attributes:[NSAttributedStringKey:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UISegmentedControl {
    func setTitleTextAttributes(_ attributes:[String:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UIButton {
    func setTitle(_ string:String?)
    {
        setTitle(string, for: UIControlState.normal)
        setTitle(string, for: UIControlState.disabled)
        setTitle(string, for: UIControlState.selected)
    }
}

extension Thread {
    static func onMainThread(block:(()->(Void))?)
    {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                block?()
            })
        }
    }
}

enum Showing {
    case all
    case filtered
}

//var globals:Globals!

struct Alert {
    var title : String
    var message : String?
}

class MediaRepository {
    var list : [Series]?
    {
        willSet {
            
        }
        didSet {
            index = nil
            
            guard let list = list else {
                return
            }

            for series in list {
                if index == nil {
                    index = [String:Series]()
                }
                if index?[series.name] == nil {
                    index?[series.name] = series
                } else {
                    print("DUPLICATE SERIES ID: \(series)")
                }
            }
        }
    }
    var index: [String:Series]?
}

struct CoverArt {
    var storage : [String:UIImage]?
    
//    init(storage:[String:UIImage]?)
//    {
//        self.storage = storage
//    }
    
    // Make it threadsafe
    let queue = DispatchQueue(label: "CoverArt")
    
    subscript(key:String?) -> UIImage? {
        get {
            return queue.sync {
                guard let key = key else {
                    return nil
                }
                
                return storage?[key]
            }
        }
        set {
            queue.sync {
                guard let key = key else {
                    return
                }
                
                if storage == nil {
                    storage = [String:UIImage]()
                }
                storage?[key] = newValue
            }
        }
    }
}

class Globals //: NSObject
{
    static var shared = Globals()
    
    var images = CoverArt() // [String:UIImage]()
    
    var splitViewController : UISplitViewController!
    
    var sorting:String? = Constants.Sorting.Newest_to_Oldest
    {
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
    
    var format:String?
    {
        get {
            let defaults = UserDefaults.standard

            return defaults.string(forKey: Constants.FORMAT)
        }
        
        set {
            let defaults = UserDefaults.standard
            if (newValue != nil) {
                defaults.set(newValue,forKey: Constants.FORMAT)
            } else {
                defaults.removeObject(forKey: Constants.FORMAT)
            }
            defaults.synchronize()
        }
    }

    
    var filter:String?
    {
        willSet {
            
        }
        didSet {
            guard filter != oldValue else {
                return
            }
            
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
    
    var isRefreshing:Bool   = false
    var isLoading:Bool      = false
    
    var seriesSettings:[String:[String:String]]?
    var sermonSettings:[String:[String:String]]?

    var mediaPlayer = MediaPlayer()
    
    var gotoNowPlaying:Bool = false
    
    var searchButtonClicked = false

    var searchActive:Bool = false
    {
        willSet {
            
        }
        didSet {
            if !searchActive {
                searchText = nil
                activeSeries = sortSeries(activeSeries,sorting: sorting)
            }
        }
    }
    
    var searchValid:Bool
    {
        get {
            return searchActive && (searchText != nil) && (searchText != Constants.EMPTY_STRING)
        }
    }
    
    var searchSeries:[Series]?
    
    var searchText:String?

    var showingAbout:Bool = false
    {
        didSet {
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOWING_ABOUT_CHANGED), object: nil)
            }
        }
    }
    
    var seriesSelected:Series?
    {
        get {
            var seriesSelected:Series?
            
            let defaults = UserDefaults.standard
            if let seriesSelectedName = defaults.string(forKey: Constants.SETTINGS.SELECTED.SERIES) {
                seriesSelected = index?[seriesSelectedName]
            }
//            defaults.synchronize()
            
            return seriesSelected
        }
    }
    
    var mediaRepository = MediaRepository()
    
    var filteredSeries:[Series]?
    
    var meta:[String:Any]?
    
    var audioURL : String?
    {
        switch Constants.JSON.URL {
        case Constants.JSON.URLS.MEDIALIST_PHP:
            return Constants.URL.BASE.PHP_AUDIO
            
        default:
            return meta?["audio"] as? String
        }
    }
    
    var imageURL : String?
    {
        return meta?["image"] as? String
    }

    var squareSuffix : String?
    {
        return (meta?["imageSuffix"] as? [String:String])?["1x1"]
    }
    
    var wideSuffix : String?
    {
        return (meta?["imageSuffix"] as? [String:String])?["16x9"]
    }
    
    var series:[Series]?
    {
        willSet {
            
        }
        didSet {
            if let series = series {
                index = [String:Series]()
                for sermonSeries in series {
                    guard let name = sermonSeries.name else {
                        continue
                    }
                    
                    if index?[name] == nil {
                        index?[name] = sermonSeries
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
    
    var index:[String:Series]?
    
    func sermonFromSermonID(_ id:String) -> Sermon?
    {
        guard let index = index else {
            return nil
        }
        
        for (_,value) in index {
            if let sermons = value.sermons {
                for sermon in sermons {
                    if sermon.id == id {
                        return sermon
                    }
                }
            }
        }
        
        return nil
    }
    
    var showing:Showing = .all

    var seriesToSearch:[Series]?
    {
        get {
            switch showing {
            case .all:
                return series
                
            case .filtered:
                return filteredSeries
            }
        }
    }
    
    var activeSeries:[Series]?
    {
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
    
    var reachability = Reachability(hostname: "www.thewordunleashed.org")!
    
    var priorReachabilityStatus : Reachability.NetworkStatus?
    
    func reachabilityTransition()
    {
//        guard let reachability = reachability else {
//            return
//        }
//
//        guard let priorReachabilityStatus = priorReachabilityStatus else {
//            switch reachability.currentReachabilityStatus {
//            case .notReachable:
//                print("Not Reachable")
//                break
//
//            case .reachableViaWLAN:
//                print("Reachable via WLAN, e.g. WiFi or Bluetooth")
//                break
//
//            case .reachableViaWWAN:
//                print("Reachable via WWAN, e.g. Cellular")
//                break
//            }
//
//            return
//        }
//
//        switch priorReachabilityStatus {
//        case .notReachable:
//            switch reachability.currentReachabilityStatus {
//            case .notReachable:
//                print("Not Reachable -> Not Reachable")
//                break
//
//            case .reachableViaWLAN:
//                print("Not Reachable -> Reachable via WLAN, e.g. WiFi or Bluetooth")
//                break
//
//            case .reachableViaWWAN:
//                print("Not Reachable -> Reachable via WWAN, e.g. Cellular")
//                break
//            }
//            break
//
//        case .reachableViaWLAN:
//            switch reachability.currentReachabilityStatus {
//            case .notReachable:
//                print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Not Reachable")
//                break
//
//            case .reachableViaWLAN:
//                print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Reachable via WLAN, e.g. WiFi or Bluetooth")
//                break
//
//            case .reachableViaWWAN:
//                print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Reachable via WWAN, e.g. Cellular")
//                break
//            }
//            break
//
//        case .reachableViaWWAN:
//            switch reachability.currentReachabilityStatus {
//            case .notReachable:
//                print("Reachable via WWAN, e.g. Cellular -> Not Reachable")
//                break
//
//            case .reachableViaWLAN:
//                print("Reachable via WWAN, e.g. Cellular -> Reachable via WLAN, e.g. WiFi or Bluetooth")
//                break
//
//            case .reachableViaWWAN:
//                print("Reachable via WWAN, e.g. Cellular -> Reachable via WWAN, e.g. Cellular")
//                break
//            }
//            break
//        }
        
        if let priorReachabilityStatus = priorReachabilityStatus {
            switch priorReachabilityStatus {
            case .notReachable:
                switch reachability.currentReachabilityStatus {
                case .notReachable:
                    print("Not Reachable -> Not Reachable")
                    break
                    
                case .reachableViaWLAN:
                    print("Not Reachable -> Reachable via WLAN, e.g. WiFi or Bluetooth")
                    break
                    
                case .reachableViaWWAN:
                    print("Not Reachable -> Reachable via WWAN, e.g. Cellular")
                    break
                }
                break
                
            case .reachableViaWLAN:
                switch reachability.currentReachabilityStatus {
                case .notReachable:
                    print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Not Reachable")
                    break
                    
                case .reachableViaWLAN:
                    print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Reachable via WLAN, e.g. WiFi or Bluetooth")
                    break
                    
                case .reachableViaWWAN:
                    print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Reachable via WWAN, e.g. Cellular")
                    break
                }
                break
                
            case .reachableViaWWAN:
                switch reachability.currentReachabilityStatus {
                case .notReachable:
                    print("Reachable via WWAN, e.g. Cellular -> Not Reachable")
                    break
                    
                case .reachableViaWLAN:
                    print("Reachable via WWAN, e.g. Cellular -> Reachable via WLAN, e.g. WiFi or Bluetooth")
                    break
                    
                case .reachableViaWWAN:
                    print("Reachable via WWAN, e.g. Cellular -> Reachable via WWAN, e.g. Cellular")
                    break
                }
                break
            }
        } else {
            switch reachability.currentReachabilityStatus {
            case .notReachable:
                print("Not Reachable")
                break
                
            case .reachableViaWLAN:
                print("Reachable via WLAN, e.g. WiFi or Bluetooth")
                break
                
            case .reachableViaWWAN:
                print("Reachable via WWAN, e.g. Cellular")
                break
            }
        }

        if priorReachabilityStatus == .notReachable, reachability.isReachable, series != nil {
            alert(title: "Network Connection Restored",message: "")
        }
        
        if priorReachabilityStatus != .notReachable, !reachability.isReachable, series != nil {
            alert(title: "No Network Connection",message: "Without a network connection only audio previously downloaded will be available.")
        }
        
        priorReachabilityStatus = reachability.currentReachabilityStatus
    }
    
    init() // override 
    {
//        super.init()
        
        Thread.onMainThread {
            self.alertTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.alertViewer), userInfo: nil, repeats: true)
        }

//        guard let reachability = Reachability(hostname: "www.thewordunleashed.org") else {
//            return
//        }
//        
//        self.reachability = reachability
        
        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
            }
        }
        
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
            }
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    func cancelAllDownloads()
    {
        guard let series = series else {
            return
        }
        
        for series in series {
            if let sermons = series.sermons {
                for sermon in sermons {
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
    
    func updateSearchResults()
    {
        if searchActive {
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
        defaults.set(seriesSettings,forKey: Constants.SETTINGS.KEY.SERIES)
        defaults.set(sermonSettings,forKey: Constants.SETTINGS.KEY.SERMON)
        defaults.synchronize()
    }
    
    func loadSettings()
    {
        let defaults = UserDefaults.standard
        
        if let settingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.SERIES) {
            seriesSettings = settingsDictionary as? [String:[String:String]]
        }
        
        if let settingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.SERMON) {
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
        
        if let seriesPlaying = defaults.string(forKey: Constants.SETTINGS.PLAYING.SERIES) {
            if let index = self.series?.index(where: { (series) -> Bool in
                return series.name == seriesPlaying
            }) {
                let seriesPlaying = series?[index]
                
                if let sermonPlaying = defaults.string(forKey: Constants.SETTINGS.PLAYING.SERMON) {
                    mediaPlayer.playing = seriesPlaying?.sermons?.filter({ (sermon) -> Bool in
                        return sermon.id == sermonPlaying
                    }).first

//                    if let show = seriesPlaying?.show {
//                        if (sermonPlayingIndex > (show - 1)) {
//                            mediaPlayer.playing = nil
//                        } else {
//                            mediaPlayer.playing = seriesPlaying?.sermons?[sermonPlayingIndex]
//                        }
//                    } else {
//                        mediaPlayer.playing = nil
//                    }
                }
            } else {
                defaults.removeObject(forKey: Constants.SETTINGS.PLAYING.SERIES)
            }
        }
    }
    
    @objc func alertViewer()
    {
//        for alert in alerts {
//            print(alert)
//        }
        
        guard UIApplication.shared.applicationState == UIApplicationState.active else {
            return
        }
        
        guard alerts.count > 0, let alert = alerts.first else {
            return
        }
        
        let alertVC = UIAlertController(title:alert.title,
                                        message:alert.message,
                                        preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alertVC.addAction(action)
        
        Thread.onMainThread {
            self.splitViewController.present(alertVC, animated: true, completion: {
                self.alerts.remove(at: 0)
            })
        }
    }
    
    var alerts = [Alert]()
    
    var alertTimer : Timer?
    
    func alert(title:String,message:String?)
    {
        alerts.append(Alert(title: title, message: message))
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
    
    func motionEnded(_ motion: UIEventSubtype, event: UIEvent?)
    {
        guard (motion == .motionShake) else {
            return
        }
        
        guard (mediaPlayer.playing != nil) else {
            return
        }
        
        if let state = mediaPlayer.state {
            switch state {
            case .paused:
                mediaPlayer.play()
                break
                
            default:
                mediaPlayer.pause()
                break
            }
        }
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAYING_PAUSED), object: nil)
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
            if let seconds = self.mediaPlayer.currentTime?.seconds {
                self.mediaPlayer.seek(to: seconds - 15)
                return MPRemoteCommandHandlerStatus.success
            } else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
        })
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            if let seconds = self.mediaPlayer.currentTime?.seconds {
                self.mediaPlayer.seek(to: seconds + 15)
                return MPRemoteCommandHandlerStatus.success
            } else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
        })
        
        if #available(iOS 9.1, *) {
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
                NSLog("MPChangePlaybackPositionCommand")
                if let positionTime = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime {
                    self.mediaPlayer.seek(to: positionTime)
                    return MPRemoteCommandHandlerStatus.success
                } else {
                    return MPRemoteCommandHandlerStatus.commandFailed
                }
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


