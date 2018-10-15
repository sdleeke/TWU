//
//  Sermon.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

var debug = false

class Sermon : NSObject
{
    weak var series:Series?
    
    var dict:[String:Any]?
    
    var id:String!
    {
        return dict?["mediaCode"] as? String
    }
    
    var partNumber:String!
    {
        return dict?["part"] as? String
    }
    
    var partString:String?
    {
        get {
            if let numberOfSermons = series?.numberOfSermons { // , let index = series?.sermons?.index(of: self)
                return "Part\u{00a0}\(partNumber!)\u{00a0}of\u{00a0}\(numberOfSermons)"
            }
            
            return "Part\u{00a0}\(partNumber!)"
        }
    }
    
    var publishDate:String!
    {
        return dict?["publishDate"] as? String
    }
    
    var text:String?
    {
        return dict?["description"] as? String
    }
    
    var title:String?
    {
        guard let series = series else {
            return nil
        }
        
        guard let title = series.title else {
            return nil
        }
        
        if let partString = partString {
            return "\(title) \(partString))"
        } else {
            return title
        }
    }
    
    var atEnd:Bool {
        get {
            return settings?[Constants.SETTINGS.AT_END] == "YES"
        }
        
        set {
            settings?[Constants.SETTINGS.AT_END] = newValue ? "YES" : "NO"
        }
    }
    
    var audio:String? {
        get {
            return id + Constants.FILE_EXTENSION.MP3
        }
    }

    var audioURL:URL? {
        get {
            guard let audioURL = Globals.shared.series.meta.audioURL else {
                return nil
            }
            
            guard let audio = audio else {
                return nil
            }
            
            return URL(string: audioURL + audio)
        }
    }

    var audioFileSystemURL:URL? {
        get {
            guard let audio = audio else {
                return nil
            }
            
            return fileSystemURL(audio)
        }
    }
    
    var playingURL:URL? {
        get {
            if let url = audioFileSystemURL {
                if !FileManager.default.fileExists(atPath: url.path){
                    return audioURL
                } else {
                    return audioFileSystemURL
                }
            } else {
                return nil
            }
        }
    }

    var sermonID:String? {
        get {
            return id
        }
    }

    var hasCurrentTime : Bool
    {
        get {
            guard let currentTime = currentTime else {
                return false
            }
            
            return (Float(currentTime) != nil)
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var currentTime:String? {
        get {
            if (settings?[Constants.CURRENT_TIME] == nil) {
                settings?[Constants.CURRENT_TIME] = Constants.ZERO
            }
            return settings?[Constants.CURRENT_TIME]
        }
        
        set {
            if (settings?[Constants.CURRENT_TIME] != newValue) {
                settings?[Constants.CURRENT_TIME] = newValue
            }
        }
    }
    
    init(series:Series,dict:[String:Any]?)
    {
        self.series = series
        
        switch Constants.JSON.URL {
        case Constants.JSON.URLS.SERIES_JSON:
            self.dict = dict?["program"] as? [String:Any]
            break
            
        default:
            self.dict = dict
            break
        }
    }
    
    override var description : String
    {
        get {
            guard let series = series else {
                return "ERROR"
            }

            //This requires that date, service, title, and speaker fields all be non-nil

            var sermonString = "Sermon:"

            sermonString = "\(sermonString) \(series.title ?? "Title")"

            sermonString = "\(sermonString) Part:\(partNumber!)"

            return sermonString
        }
    }
    
    class Settings
    {
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
                if let sermonID = self.sermon?.sermonID {
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
                
                guard let sermonID = sermon.sermonID else {
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
    
    lazy var settings:Settings? = {
        return Settings(sermon:self)
    }()
    
    var downloads = [String:Download]()
    
    lazy var audioDownload:Download! = {
        [unowned self] in
        let download = Download(sermon:self,purpose:Constants.AUDIO,downloadURL:self.audioURL,fileSystemURL:self.audioFileSystemURL)
        // didSets will NOT happen in an init but they WILL happen here so DO NOT set properties unless you are sure
        // no bad behavior will result from the didSets.
        self.downloads[Constants.AUDIO] = download
        return download
    }()
}
