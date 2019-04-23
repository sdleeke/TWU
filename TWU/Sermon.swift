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
    deinit {
        debug(self)
    }
    
    weak var series:Series?
    
    var dict:[String:Any]?
    
    var id:String?
    {
        return mediaCode
    }
    
    var mediaCode:String?
    {
        get {
            return dict?["mediaCode"] as? String
        }
    }
    
    var cbcMediaCode:String?
    {
        get {
            return dict?["cbcMediaCode"] as? String
        }
    }
    
    var url:URL?
    {
        get {
            guard let cbcMediaCode = cbcMediaCode else {
                return nil
            }
            return URL(string: Constants.URL.BASE.SERMON_WEB + cbcMediaCode)
        }
    }
    
    var cbcURL:URL?
    {
        get {
            guard let cbcMediaCode = cbcMediaCode else {
                return nil
            }
            return URL(string: Constants.CBC.ARCHIVES_URL + "&mediaCode=" + cbcMediaCode)
        }
    }
    
    var partNumber:String?
    {
        get {
            return dict?["part"] as? String
        }
    }
    
    var partString:String?
    {
        get {
            guard let partNumber = partNumber else {
                return nil
            }
            
            if let numberOfSermons = series?.sermons?.count { // , let index = series?.sermons?.index(of: self)
                return "Part\u{00a0}\(partNumber)\u{00a0}of\u{00a0}\(numberOfSermons)"
            }
            
            return "Part\u{00a0}\(partNumber)"
        }
    }
    
    var publishDate:String?
    {
        get {
            return dict?["publishDate"] as? String
        }
    }
    
    var text:String?
    {
        get {
            return dict?["description"] as? String
        }
    }
    
    var title:String?
    {
        get {
            guard let series = series else {
                return nil
            }
            
            guard let title = series.title else {
                return nil
            }
            
            if let partString = partString {
                return "\(title) (\(partString))"
            } else {
                return title
            }
        }
    }

    var atEnd:Bool
    {
        get {
            return sermonSettings?[Constants.SETTINGS.AT_END] == "YES"
        }
        
        set {
            sermonSettings?[Constants.SETTINGS.AT_END] = newValue ? "YES" : "NO"
        }
    }
    
    var audio:String?
    {
        get {
            guard let id = id else {
                return nil
            }
            return id + Constants.FILE_EXTENSION.MP3
        }
    }

    var audioURL:URL?
    {
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

    var audioFileSystemURL:URL?
    {
        get {
            guard let audio = audio else {
                return nil
            }
            
            return audio.fileSystemURL
        }
    }
    
    var playingURL:URL?
    {
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

//    var sermonID:String? {
//        get {
//            return id
//        }
//    }

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
    var currentTime:String?
    {
        get {
            if (sermonSettings?[Constants.CURRENT_TIME] == nil) {
                sermonSettings?[Constants.CURRENT_TIME] = Constants.ZERO
            }
            return sermonSettings?[Constants.CURRENT_TIME]
        }
        
        set {
            if (sermonSettings?[Constants.CURRENT_TIME] != newValue) {
                sermonSettings?[Constants.CURRENT_TIME] = newValue
            }
        }
    }
    
    init(series:Series,dict:[String:Any]?)
    {
        self.series = series

        self.dict = dict?["program"] as? [String:Any]

//        switch Constants.JSON.URL {
//        case Constants.JSON.URLS.SERIES_JSON:
//            self.dict = dict?["program"] as? [String:Any]
//            break
//            
//        default:
//            self.dict = dict
//            break
//        }
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

            if let partNumber = partNumber {
                sermonString = "\(sermonString) Part:\(partNumber)"
            }

            return sermonString
        }
    }
    
    lazy var sermonSettings:SermonSettings? = { [weak self] in
        return SermonSettings(sermon:self)
    }()
    
    var downloads = [String:Download]()
    
    lazy var audioDownload:Download? = { [weak self] in
        guard let download = Download(sermon:self,purpose:Constants.AUDIO,downloadURL:self?.audioURL,fileSystemURL:self?.audioFileSystemURL) else {
            return nil
        }
        
        // didSets will NOT happen in an init but they WILL happen here so DO NOT set properties unless you are sure
        // no bad behavior will result from the didSets.
        
        self?.downloads[Constants.AUDIO] = download
        
        return download
    }()
}
