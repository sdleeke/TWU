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

//extension UIBarButtonItem {
//    func setTitleTextAttributes(_ attributes:[NSAttributedStringKey:UIFont])
//    {
//        setTitleTextAttributes(attributes, for: UIControlState.normal)
//        setTitleTextAttributes(attributes, for: UIControlState.disabled)
//        setTitleTextAttributes(attributes, for: UIControlState.selected)
//    }
//}
//
//extension UISegmentedControl {
//    func setTitleTextAttributes(_ attributes:[String:UIFont])
//    {
//        setTitleTextAttributes(attributes, for: UIControlState.normal)
//        setTitleTextAttributes(attributes, for: UIControlState.disabled)
//        setTitleTextAttributes(attributes, for: UIControlState.selected)
//    }
//}
//
//extension UIButton {
//    func setTitle(_ string:String?)
//    {
//        setTitle(string, for: UIControlState.normal)
//        setTitle(string, for: UIControlState.disabled)
//        setTitle(string, for: UIControlState.selected)
//    }
//}
//
//extension Thread {
//    static func onMainThread(block:(()->(Void))?)
//    {
//        if Thread.isMainThread {
//            block?()
//        } else {
//            DispatchQueue.main.async(execute: { () -> Void in
//                block?()
//            })
//        }
//    }
//}

enum Showing
{
    case all
    case filtered
}

//var globals:Globals!

struct Alert
{
    var title : String
    var message : String?
}

//class MediaRepository
//{
//    // Make thread safe?
//    var index = ThreadSafeDictionary<Series>(name: "SERIES_INDEX") // [String:Series]?
//
//    var list : [Series]?
//    {
//        willSet {
//
//        }
//        didSet {
////            index = nil
//
//            index.clear()
//
//            guard let list = list else {
//                return
//            }
//
//            for series in list {
////                if index == nil {
////                    index = [String:Series]()
////                }
//                if index[series.name] == nil {
//                    index[series.name] = series
//                } else {
//                    print("DUPLICATE SERIES ID: \(series)")
//                }
//            }
//        }
//    }
//}

//struct CoverArt {
//    var storage : [String:UIImage]?
//
////    init(storage:[String:UIImage]?)
////    {
////        self.storage = storage
////    }
//
//    // Make it threadsafe
//    let queue = DispatchQueue(label: "CoverArt")
//
//    subscript(key:String?) -> UIImage? {
//        get {
//            return queue.sync {
//                guard let key = key else {
//                    return nil
//                }
//
//                return storage?[key]
//            }
//        }
//        set {
//            queue.sync {
//                guard let key = key else {
//                    return
//                }
//
//                if storage == nil {
//                    storage = [String:UIImage]()
//                }
//                storage?[key] = newValue
//            }
//        }
//    }
//}


class Globals //: NSObject
{
    static var shared = Globals()
    
    var images = ThreadSafeDictionary<UIImage>(name: "CoverArt") // CoverArt() // [String:UIImage]()
    
    var splitViewController : UISplitViewController!
    
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

    var isRefreshing:Bool   = false
    var isLoading:Bool      = false
    
    var settings = Settings()

    var mediaPlayer = MediaPlayer()
    
    var gotoNowPlaying:Bool = false
    
    var showingAbout:Bool = false
    {
        didSet {
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOWING_ABOUT_CHANGED), object: nil)
            }
        }
    }
    
    // From NEW JSON
    // Make thread safe?
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

    // Use this to replace filteredSeries, series, index, sermonFromSermonID, seriesToSearch, activeSeries
//    var mediaRepository = MediaRepository()
    
    var series = Media()
    
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

        if priorReachabilityStatus == .notReachable, reachability.isReachable, series.all != nil {
            Alerts.shared.alert(title: "Network Connection Restored",message: "")
        }
        
        if priorReachabilityStatus != .notReachable, !reachability.isReachable, series.all != nil {
            Alerts.shared.alert(title: "No Network Connection",message: "Without a network connection only audio previously downloaded will be available.")
        }
        
        priorReachabilityStatus = reachability.currentReachabilityStatus
    }
    
    init() // override 
    {
//        super.init()
        
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


