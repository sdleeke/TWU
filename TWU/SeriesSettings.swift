//
//  SeriesSettings.swift
//  TWU
//
//  Created by Steve Leeke on 10/27/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class SeriesSettings
{
    deinit {
        print(self)
    }
    
    weak var series:Series?
    
    init(series:Series?) {
        if (series == nil) {
            print("nil series in Settings init!")
        }
        self.series = series
    }
    
    subscript(key:String) -> String? {
        get {
            var value:String?
            if let series = self.series?.name {
                value = Globals.shared.settings.series[series,key]
            }
            return value
        }
        set {
            guard (newValue != nil) else {
                print("newValue == nil in Settings!")
                return
            }
            
            guard (series != nil) else {
                print("series == nil in Settings!")
                return
            }
            
            guard let name = series?.name else {
                print("series!.name == nil in Settings!")
                return
            }
            
            Globals.shared.settings.series[name,key] = newValue
            
            // For a high volume of activity this can be very expensive.
            Globals.shared.settings.saveBackground()
        }
    }
}

