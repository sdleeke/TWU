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

struct Globals {
    //    static var downloadTasks = [NSURLSessionDownloadTask]()
    //    static var session:NSURLSession!
    static var sorting:String? = Constants.Newest_to_Oldest {
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
    
    static var filter:String? {
        didSet {
            if filter != oldValue {
                if (filter != nil) {
                    showing = .filtered
                    filteredSeries = Globals.series?.filter({ (series:Series) -> Bool in
                        return series.book == Globals.filter
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
    
    static var refreshing:Bool = false
    static var loading:Bool = false
    
    static var seriesSettings:[String:[String:String]]?
    static var sermonSettings:[String:[String:String]]?

    static var mpPlayer:MPMoviePlayerController?
    
    static var mpPlayerStateTime : PlayerStateTime?
    
    static var playerPaused:Bool = true {
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
    
    static var playOnLoad:Bool = false
    static var sermonLoaded:Bool = false
    
    static var playerObserver: NSTimer?

    static var gotoNowPlaying:Bool = false
    
    static var searchButtonClicked = false
    static var searchActive:Bool = false {
        didSet {
            if !searchActive {
                searchText = nil
                activeSeries = sortSeries(activeSeries,sorting: sorting)
            }
        }
    }

    static var searchText:String? {
        didSet {
            if searchText != oldValue {
                updateSearchResults()
            }
        }
    }

    static var showingAbout:Bool = false
    
    static var seriesSelected:Series? {
        get {
            var seriesSelected:Series?
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let seriesSelectedStr = defaults.stringForKey(Constants.SERIES_SELECTED) {
                if let seriesSelectedID = Int(seriesSelectedStr) {
                    seriesSelected = Globals.index?[seriesSelectedID]
                }
            }
            defaults.synchronize()
            
            return seriesSelected
        }
    }
    
    static var sermonPlaying:Sermon? {
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
    
    static var searchSeries:[Series]?

    static var filteredSeries:[Series]?
    
    static var series:[Series]? {
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
                filteredSeries = Globals.series?.filter({ (series:Series) -> Bool in
                    return series.book == Globals.filter
                })
            }
            updateSearchResults()
        }
    }
    
    static var index:[Int:Series]?
    
    static var showing:Showing = .all

    static var seriesToSearch:[Series]? {
        get {
            switch showing {
                case .all:      return Globals.series
                case .filtered: return Globals.filteredSeries
            }
        }
    }
    
    static var activeSeries:[Series]? {
        get {
            if Globals.searchActive {
                return Globals.searchSeries
            } else {
                return Globals.seriesToSearch
            }
        }
        set {
            if Globals.searchActive {
                Globals.searchSeries = newValue
            } else {
                switch showing {
                case .all:
                    Globals.series = newValue
                    break
                case .filtered:
                    Globals.filteredSeries = newValue
                    break
                }
            }
        }
    }
}


