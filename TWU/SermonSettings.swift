//
//  SermonSettings.swift
//  TWU
//
//  Created by Steve Leeke on 10/27/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class SermonSettings
{
    deinit {
        debug(self)
    }
    
    weak var sermon:Sermon?
    
    init(sermon:Sermon?) {
        if (sermon == nil) {
            print("nil sermon in Settings init!")
        }
        self.sermon = sermon
    }
    
    subscript(key:String) -> String? {
        get {
            var value:String?
            if let sermonID = self.sermon?.id {
                value = Globals.shared.settings.sermon[sermonID,key]
            }
            return value
        }
        set {
            guard (newValue != nil) else {
                print("newValue == nil in Settings!")
                return
            }
            
            guard let sermon = sermon else {
                print("sermon == nil in Settings!")
                return
            }
            
            guard let sermonID = sermon.id else {
                print("sermon!.sermonID == nil in Settings!")
                return
            }
            
            if (Globals.shared.settings.sermon[sermonID,key] != newValue) {
                Globals.shared.settings.sermon[sermonID,key] = newValue
                
                // For a high volume of activity this can be very expensive.
                Globals.shared.settings.saveBackground()
            }
        }
    }
}

