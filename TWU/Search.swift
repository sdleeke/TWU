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
    var buttonClicked = false
    
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
    
    var text:String?
}
