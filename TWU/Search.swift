//
//  Search.swift
//  TWU
//
//  Created by Steve Leeke on 10/4/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class Search
{
    weak var media : Media?
    
    init(media:Media?)
    {
        self.media = media
    }
    
    var buttonClicked = false
    
    var text:String?

    var active:Bool = false
    {
        willSet {
            
        }
        didSet {
            if !active {
                text = nil
                // BAD
                //                    activeSeries = sortSeries(activeSeries,sorting: sorting)
            }
        }
    }
    
    var valid:Bool
    {
        get {
            return active && (text != nil) && (text != Constants.EMPTY_STRING)
        }
    }
    
    // Search results
    var results:[Series]?
    {
        get {
            if active {
                return media?.toSearch?.filter({ (series:Series) -> Bool in
                    guard let searchText = self.text else {
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
                
//                if search.results?.count == 0 {
//                    search.results = nil
//                }
            } else {
                return nil // media?.toSearch
            }
        }
    }
    
//    func updateSearchResults()
//    {
//        if search.active {
//            search.results = toSearch?.filter({ (series:Series) -> Bool in
//                guard let searchText = search.text else {
//                    return false
//                }
//                
//                var seriesResult = false
//                
//                if let string = series.title  {
//                    seriesResult = seriesResult || ((string.range(of: searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil)
//                }
//                
//                if let string = series.scripture {
//                    seriesResult = seriesResult || ((string.range(of: searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil)
//                }
//                
//                return seriesResult
//            })
//            
//            // Filter will return an empty array and we don't want that.
//            
//            if search.results?.count == 0 {
//                search.results = nil
//            }
//        } else {
//            search.results = toSearch
//        }
//    }
}
