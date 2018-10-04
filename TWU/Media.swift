//
//  Media.swift
//  TWU
//
//  Created by Steve Leeke on 10/4/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class Media
{
    var showing:Showing = .all
    
    var selected:Series?
    {
        get {
            var seriesSelected:Series?
            
            let defaults = UserDefaults.standard
            if let seriesSelectedName = defaults.string(forKey: Constants.SETTINGS.SELECTED.SERIES) {
                seriesSelected = index[seriesSelectedName]
            }
            //            defaults.synchronize()
            
            return seriesSelected
        }
    }
    
    var search = Search()
    
    func updateSearchResults()
    {
        if search.active {
            search.results = toSearch?.filter({ (series:Series) -> Bool in
                guard let searchText = search.text else {
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
            
            if search.results?.count == 0 {
                search.results = nil
            }
        } else {
            search.results = toSearch
        }
    }
    
    var sorting:String? = Constants.Sorting.Newest_to_Oldest
    {
        willSet {
            
        }
        didSet {
            if sorting != oldValue {
                // BAD
                //                activeSeries = sortSeries(activeSeries,sorting: sorting)
                
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
                //                filteredSeries = series?.filter({ (series:Series) -> Bool in
                //                    return series.book == filter
                //                })
            } else {
                showing = .all
                //                filteredSeries = nil
            }
            
            updateSearchResults()
            
            // BAD
            //            activeSeries = sortSeries(activeSeries,sorting: sorting)
            
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
            
            //            if (filter != nil) {
            //                showing = .filtered
            //                filteredSeries = series?.filter({ (series:Series) -> Bool in
            //                    return series.book == filter
            //                })
            //            }
            
            //            updateSearchResults()
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
        //        set {
        //            if search.active {
        //                search.series = newValue
        //            } else {
        //                switch showing {
        //                case .all:
        //                    series = newValue
        //                    break
        //                case .filtered:
        //                    filteredSeries = newValue
        //                    break
        //                }
        //            }
        //        }
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
}
