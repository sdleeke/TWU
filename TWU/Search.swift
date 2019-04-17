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
    
    deinit {
        print(self)
    }
    
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
            guard active else {
                return nil
            }
            
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
        }
    }
}
