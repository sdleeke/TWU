//
//  Globals.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer

enum Showing {
    case all
    case filtered
}

struct Globals {
    //    static var downloadTasks = [NSURLSessionDownloadTask]()
    //    static var session:NSURLSession!
    static var sorting:String? = Constants.Newest_to_Oldest
    
    static var filter:String? {
        didSet {
            var filtered = [Series]()
            
            for series in Globals.series! {
                if (series.book == Globals.filter) {
                    filtered.append(series)
                }
            }
            
            self.filteredSeries = filtered.count > 0 ? filtered : nil
        }
    }
    
    static var mpPlayer:MPMoviePlayerController?
    
    static var playerPaused:Bool = false
    static var sermonLoaded:Bool = false
    
    static var sliderObserver: NSTimer?
    static var playObserver: NSTimer?
    
    static var gotoNowPlaying:Bool = false
    static var searchActive:Bool = false
    static var showingAbout:Bool = false
    
    static var seriesSelected:Series?
    static var sermonSelected:Sermon?
    
    static var sermonPlaying:Sermon?
    
    static var searchSeries:[Series]?

    static var filteredSeries:[Series]?
    static var series:[Series]?
    
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


