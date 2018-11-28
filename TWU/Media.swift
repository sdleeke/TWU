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
    
    var showing:Showing = .all
    
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
    
    lazy var search:Search! = {
        return Search(media:self)
    }()
    
    var sorting:String? = Constants.Sorting.Newest_to_Oldest
    {
        willSet {
            
        }
        didSet {
            if sorting != oldValue {
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
            } else {
                showing = .all
            }
            
            let defaults = UserDefaults.standard
            if (filter != nil) {
                defaults.set(filter,forKey: Constants.FILTER)
            } else {
                defaults.removeObject(forKey: Constants.FILTER)
            }
            defaults.synchronize()
        }
    }
    
    var index = ThreadSafeDictionary<Series>(name: "SERIES_INDEX") // [String:Series]?
    
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
        
        for series in series {
            if let sermons = series.sermons {
                for sermon in sermons {
                    sermon.audioDownload.cancel()
//                    if sermon.audioDownload.active {
//                        sermon.audioDownload.task?.cancel()
//                        sermon.audioDownload.task = nil
//
//                        sermon.audioDownload.totalBytesWritten = 0
//                        sermon.audioDownload.totalBytesExpectedToWrite = 0
//
//                        sermon.audioDownload.state = .none
//                    }
                }
            }
        }
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
                return sortSeries(search.results,sorting: sorting)
            } else {
                return sortSeries(toSearch,sorting: sorting)
            }
        }
    }
    
    func sermon(from id:String) -> Sermon?
    {
        guard let index = index.copy else {
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

    func load(seriesDicts:[[String:Any]]?)
    {
        all = from(seriesDicts: seriesDicts)
    }

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
    
    func from(seriesDicts:[[String:Any]]?) -> [Series]?
    {
        // This is if we use an opQueue when downloading
//        operationQueue.cancelAllOperations()

        return seriesDicts?.filter({ (seriesDict:[String:Any]) -> Bool in
//            let series = Series(seriesDict: seriesDict)
//            return series.sermons?.count > 0 // .show != 0
            if let programs = seriesDict["programs"] as? [[String:Any]] {
                return programs.count > 0
            } else {
                return false
            }
        }).map({ (seriesDict:[String:Any]) -> Series in
            let series = Series(seriesDict: seriesDict)
            
            // This is just a way to load the artwork
            series.coverArt?.fetch?.fill()

            return series
        })
    }
}
