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

struct Globals {
    //    static var downloadTasks = [NSURLSessionDownloadTask]()
    //    static var session:NSURLSession!
    static var sorting:String? = Constants.Newest_to_Oldest {
        didSet {
            let defaults = NSUserDefaults.standardUserDefaults()
            if (sorting != nil) {
                defaults.setObject(sorting,forKey: Constants.SORTING)
            } else {
                defaults.removeObjectForKey(Constants.SORTING)
            }
            defaults.synchronize()
        }
    }
    
    static var filter:String? {
        didSet {
            if (filter != nil) {
                showing = .filtered
                filteredSeries = Globals.series?.filter({ (series:Series) -> Bool in
                    return series.book == Globals.filter
                })
            } else {
                showing = .all
                filteredSeries = nil
            }
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if (sorting != nil) {
                defaults.setObject(filter,forKey: Constants.FILTER)
            } else {
                defaults.removeObjectForKey(Constants.FILTER)
            }
            defaults.synchronize()
        }
    }
    
    static var refreshing:Bool = false
    static var loading:Bool = false
    
    static var sermonSettings:[String:[String:String]]?

    static var mpPlayer:MPMoviePlayerController?
    
    static var playerPaused:Bool = false
    static var sermonLoaded:Bool = false
    
    static var sliderObserver: NSTimer?
    static var playObserver: NSTimer?
    static var seekingObserver: NSTimer?

    static var gotoNowPlaying:Bool = false
    static var searchActive:Bool = false
    static var showingAbout:Bool = false
    
//    static var seriesSelected:Series? {
//        didSet {
//            let defaults = NSUserDefaults.standardUserDefaults()
//            if (seriesSelected != nil) {
//                defaults.setObject("\(seriesSelected!.id)", forKey: Constants.SERIES_SELECTED)
//            } else {
//                // This should never happen.
//                defaults.removeObjectForKey(Constants.SERIES_SELECTED)
//            }
//            defaults.synchronize()
//
////            The next line removes the sermonSelected when defaults are loaded - so leave it commented out.
////            sermonSelected = nil
//        }
//    }
//    static var sermonSelected:Sermon? {
//        didSet {
//            let defaults = NSUserDefaults.standardUserDefaults()
//            if (sermonSelected != nil) {
//                defaults.setObject("\(sermonSelected!.index)", forKey: Constants.SERMON_SELECTED_INDEX)
//            } else {
//                // This should never happen.
//                defaults.removeObjectForKey(Constants.SERMON_SELECTED_INDEX)
//            }
//            defaults.synchronize()
//        }
//    }
    
    static var seriesSelected:Series? {
        get {
            var seriesSelected:Series?
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let seriesSelectedStr = defaults.stringForKey(Constants.SERIES_SELECTED) {
                if let seriesSelectedID = Int(seriesSelectedStr) {
                    seriesSelected = Globals.index?[seriesSelectedID]
//                    if let index = Globals.series?.indexOf({ (series) -> Bool in
//                        return series.id == seriesSelectedID
//                    }) {
//                        seriesSelected = Globals.series?[index]
//                    }
                }
            }
            defaults.synchronize()
            
            return seriesSelected
        }
    }
    
    static var sermonSelected:Sermon? {
        get {
            var sermonSelected:Sermon?
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let sermonSelectedIndexStr = defaults.stringForKey(Constants.SERMON_SELECTED_INDEX) {
                if let sermonSelectedIndex = Int(sermonSelectedIndexStr) {
                    if (sermonSelectedIndex > (seriesSelected!.show! - 1)) {
                        defaults.removeObjectForKey(Constants.SERMON_SELECTED_INDEX)
                    } else {
                        sermonSelected = Globals.seriesSelected?.sermons?[sermonSelectedIndex]
                    }
                }
            }
            defaults.synchronize()
            
            return sermonSelected
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
                    index?[sermonSeries.id] = sermonSeries
                }
            }
            if (filter != nil) {
                showing = .filtered
                filteredSeries = Globals.series?.filter({ (series:Series) -> Bool in
                    return series.book == Globals.filter
                })
            }
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


