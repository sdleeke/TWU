//
//  Media.swift
//  TWU
//
//  Created by Steve Leeke on 10/4/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class Media
{
    let meta = Meta()
    
    deinit {
        debug(self)
    }
    
    var showing:Showing
    {
        get {
            switch filter {
            case Constants.All:
                return .all
                
            default:
                return .filtered
            }
        }
    }
    
    var selected:Series?
    {
        get {
            var seriesSelected:Series?
            
            let defaults = UserDefaults.standard
            if let seriesSelectedName = defaults.string(forKey: Constants.SETTINGS.SELECTED.SERIES) {
                seriesSelected = index[seriesSelectedName]
            }
            
            return seriesSelected
        }
    }
    
    lazy var search:Search! = { [weak self] in
        return Search(media:self)
    }()
    
    var _sorting:String?
    {
        willSet {
            
        }
        didSet {
//            if sorting != oldValue {
//            }
            let defaults = UserDefaults.standard
            if (sorting != nil) {
                defaults.set(sorting,forKey: Constants.SORTING)
            } else {
                defaults.removeObject(forKey: Constants.SORTING)
            }
            defaults.synchronize()
        }
    }
    var sorting:String?
    {
        get {
            if _sorting == nil {
                if let sortingString = UserDefaults.standard.string(forKey: Constants.SORTING) {
                    _sorting = Constants.Sorting.Options.contains(sortingString) ? sortingString : Constants.Sorting.Newest_to_Oldest
                } else {
                    _sorting = Constants.Sorting.Newest_to_Oldest
                }
            }
            
            return _sorting
        }
        set {
            _sorting = newValue
        }
    }
    
    var _filter:String?
    {
        willSet {
            
        }
        didSet {
            guard filter != oldValue else {
                return
            }
            
//            if (filter != nil) {
//                showing = .filtered
//            } else {
//                showing = .all
//            }
            
            let defaults = UserDefaults.standard
            if (filter != nil) {
                defaults.set(filter,forKey: Constants.FILTER)
            } else {
                defaults.removeObject(forKey: Constants.FILTER)
            }
            defaults.synchronize()
        }
    }
    var filter:String?
    {
        get {
            if _filter == nil {
                if let filterString = UserDefaults.standard.string(forKey: Constants.FILTER) {
                    _filter = filterString
                } else {
                    _filter = Constants.All
                }
            }
            
            return _filter
        }
        set {
            _filter = newValue
        }
    }

    var index = ThreadSafeDN<Series>(name: "SERIES_INDEX") // [String:Series]? // ictionary
    
    var filtered:[Series]?
    {
        get {
            return all?.filter({ (series:Series) -> Bool in
                return series.book == filter
            })
        }
    }
    
    func cancelAllDownloads()
    {
        guard let series = all else {
            return
        }
        
        series.forEach { (series) in
            series.sermons?.forEach({ (sermon) in
                sermon.audioDownload?.cancel()
            })
        }
        
//        for series in series {
//            if let sermons = series.sermons {
//                for sermon in sermons {
//                    sermon.audioDownload?.cancel()
////                    if sermon.audioDownload.active {
////                        sermon.audioDownload.task?.cancel()
////                        sermon.audioDownload.task = nil
////
////                        sermon.audioDownload.totalBytesWritten = 0
////                        sermon.audioDownload.totalBytesExpectedToWrite = 0
////
////                        sermon.audioDownload.state = .none
////                    }
//                }
//            }
//        }
    }

    var all:[Series]?
    {
        willSet {
            
        }
        didSet {
            if let series = all {
                index.clear()
                for sermonSeries in series {
                    guard let name = sermonSeries.name else {
                        continue
                    }
                    
                    if index[name] == nil {
                        index[name] = sermonSeries
                    } else {
                        print("DUPLICATE SERIES ID: \(sermonSeries)")
                    }
                }
            }
            
            if let seriesPlaying = UserDefaults.standard.string(forKey: Constants.SETTINGS.PLAYING.SERIES) {
                if let index = all?.firstIndex(where: { (series) -> Bool in
                    return series.name == seriesPlaying
                }) {
                    let seriesPlaying = all?[index]
                    
                    if let sermonPlaying = UserDefaults.standard.string(forKey: Constants.SETTINGS.PLAYING.SERMON) {
                        Globals.shared.mediaPlayer.playing = seriesPlaying?.sermons?.filter({ (sermon) -> Bool in
                            return sermon.id == sermonPlaying
                        }).first
                    }
                } else {
                    UserDefaults.standard.removeObject(forKey: Constants.SETTINGS.PLAYING.SERIES)
                }
            }
        }
    }
    
    var toSearch:[Series]?
    {
        get {
            switch showing {
            case .all:
                return all
                
            case .filtered:
                return filtered
            }
        }
    }
    
    var active:[Series]?
    {
        get {
            if search.active {
                return search.results?.sort(sorting: sorting)
            } else {
                return toSearch?.sort(sorting: sorting)
            }
        }
    }
    
    func sermon(from id:String) -> Sermon?
    {
        guard let index = index.copy else {
            return nil
        }
        
        let values = Array(index.values)
        
        for value in values {
            guard let series = value as? Series else {
                continue
            }
            
            if let sermons = series.sermons {
                for sermon in sermons {
                    if sermon.id == id {
                        return sermon
                    }
                }
            }
        }
        
        return nil
    }

//    func load(seriesDicts:[[String:Any]]?)
//    {
//        all = from(seriesDicts: seriesDicts)
//    }

    // This is if we use opQueues when downloading

//    lazy var operationQueue:OperationQueue! = {
//        let operationQueue = OperationQueue()
//        operationQueue.name = "Media"
//        operationQueue.qualityOfService = .background
//        operationQueue.maxConcurrentOperationCount = 1
//        return operationQueue
//    }()
//
//    lazy var mediaQueue : OperationQueue! = {
//        let operationQueue = OperationQueue()
//        operationQueue.name = "Media:Media" + UUID().uuidString
//        operationQueue.qualityOfService = .background
//        operationQueue.maxConcurrentOperationCount = 3 // Media downloads at once.
//        return operationQueue
//    }()
//
//    deinit {
//        operationQueue.cancelAllOperations()
//    }
    
//    func from(seriesDicts:[[String:Any]]?) -> [Series]?
//    {
//        // This is if we use an opQueue when downloading
////        operationQueue.cancelAllOperations()
//
//        return seriesDicts?.filter({ (seriesDict:[String:Any]) -> Bool in
////            let series = Series(seriesDict: seriesDict)
////            return series.sermons?.count > 0 // .show != 0
//            if let programs = seriesDict["programs"] as? [[String:Any]] {
//                return programs.count > 0
//            } else {
//                return false
//            }
//        }).map({ (seriesDict:[String:Any]) -> Series in
//            let series = Series(seriesDict: seriesDict)
//
//            // This is just a way to load the artwork
////            series.coverArt?.fetch?.fill()
//            // But it seems to cause deadlocks that take a long time to clear
//
//            // But if we don't preload the series images scrolling the collection view is what does it,
//            // which creates visual lag for the user as each image is loaded, esp. if it is coming from the internet.
//
//            return series
//        })
//    }
}
