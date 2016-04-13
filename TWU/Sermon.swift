//
//  Sermon.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

enum State {
    case downloading
    case downloaded
    case none
}

class Download {
    weak var sermon:Sermon?
    
    var purpose:String?
    
    var downloadURL:NSURL?
    var fileSystemURL:NSURL? {
        didSet {
            state = isDownloaded() ? .downloaded : .none
        }
    }
    
    var totalBytesWritten:Int64 = 0
    var totalBytesExpectedToWrite:Int64 = 0
    
    var session:NSURLSession?
    
    var task:NSURLSessionDownloadTask?
    
    var active:Bool {
        get {
            return state == .downloading
        }
    }
    var state:State = .none {
        didSet {
            if state != oldValue {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self.sermon)
                })
            }
        }
    }
    
    var completionHandler: ((Void) -> (Void))?
    
    func isDownloaded() -> Bool
    {
        if fileSystemURL != nil {
            return NSFileManager.defaultManager().fileExistsAtPath(fileSystemURL!.path!)
        } else {
            return false
        }
    }
    
    func download()
    {
        if (state == .none) {
            state = .downloading
            
            let downloadRequest = NSMutableURLRequest(URL: downloadURL!)
            
            // This allows the downloading to continue even if the app goes into the background or terminates.
            let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(Constants.DOWNLOAD_IDENTIFIER + fileSystemURL!.lastPathComponent!)
            configuration.sessionSendsLaunchEvents = true
            
            //        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            
            session = NSURLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
            
            task = session?.downloadTaskWithRequest(downloadRequest)
            task?.taskDescription = fileSystemURL?.lastPathComponent
            
            task?.resume()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            })
        }
    }
    
    func deleteDownload()
    {
        if (state == .downloaded) {
            // Check if file exists and if so, delete it.
            if (NSFileManager.defaultManager().fileExistsAtPath(fileSystemURL!.path!)){
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(fileSystemURL!)
                } catch _ {
                }
            }
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
            
            state = .none
        }
    }
    
    func cancelOrDeleteDownload()
    {
        switch state {
        case .downloading:
            cancelDownload()
            break
            
        case .downloaded:
            deleteDownload()
            break
            
        default:
            break
        }
    }
    
    func cancelDownload()
    {
        if (state == .downloading) {
            //            download.task?.cancelByProducingResumeData({ (data: NSData?) -> Void in
            //            })
            task?.cancel()
            task = nil
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
            
            state = .none
        }
    }
}

class Sermon : NSObject, NSURLSessionDownloadDelegate {
    var series:Series?
    
    var id:Int
    
    var audio:String? {
        get {
            return String(format: Constants.FILENAME_FORMAT, id)
        }
    }

    var audioURL:NSURL? {
        get {
            return NSURL(string: Constants.BASE_AUDIO_URL + audio!)
        }
    }

    var audioFileSystemURL:NSURL? {
        get {
            return cachesURL()?.URLByAppendingPathComponent(audio!)
        }
    }
    
    var playingURL:NSURL? {
        get {
            if let url = audioFileSystemURL {
                if !NSFileManager.defaultManager().fileExistsAtPath(url.path!){
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
            if (series == nil) {
                print("sermonID: series nil")
            }
            return "\(series!.id)\(Constants.COLON)\(id)"
        }
    }

    func hasCurrentTime() -> Bool
    {
        return (currentTime != nil) && (currentTime != "nan")
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
            settings?[Constants.CURRENT_TIME] = newValue
        }
    }
    
    init(series:Series,id:Int) {
        self.series = series
        self.id = id
    }
    
    var index:Int {
        get {
            return id - series!.startingIndex
        }
    }
    
    override var description : String {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var sermonString = "Sermon:"
        
        if (series != nil) {
            sermonString = "\(sermonString) \(series!.title)"
        }
        
        sermonString = "\(sermonString) Part:\(index+1)"
        
        return sermonString
    }
    
    struct Settings {
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
                value = globals.sermonSettings?[self.sermon!.sermonID!]?[key]
                return value
            }
            set {
                if (newValue != nil) {
                    if (sermon != nil) {
                        if (sermon!.sermonID != nil) {
                            if (globals.sermonSettings != nil) {
                                if (globals.sermonSettings?[sermon!.sermonID!] == nil) {
                                    globals.sermonSettings?[sermon!.sermonID!] = [String:String]()
                                }

    //                            print("\(globals.sermonSettings!)")
    //                            print("\(sermon!)")
    //                            print("\(newValue!)")
                                
                                if (globals.sermonSettings?[sermon!.sermonID!]?[key] != newValue) {
                                    globals.sermonSettings?[sermon!.sermonID!]?[key] = newValue
                                    
                                    // For a high volume of activity this can be very expensive.
                                    globals.saveSettingsBackground()
                                }
                            } else {
                                print("globals.sermonSettings == nil in Settings!")
                            }
                        } else {
                            print("sermon!.sermonID == nil in Settings!")
                        }
                    } else {
                        print("sermon == nil in Settings!")
                    }
                } else {
                    print("newValue == nil in Settings!")
                }
            }
        }
    }
    
    lazy var settings:Settings? = {
        return Settings(sermon:self)
    }()
    
    var downloads = [String:Download]()
    
    //    lazy var downloads:[String:Download]? = {
    //        return [String:Download]()
    //    }()
    
    lazy var audioDownload:Download! = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Constants.AUDIO
        download.downloadURL = self.audioURL
        download.fileSystemURL = self.audioFileSystemURL
        self.downloads[Constants.AUDIO] = download
        return download
    }()
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//        print("URLSession: \(session.description) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
//        let filename = downloadTask.taskDescription!
  
        if (downloadTask.taskDescription != audioDownload.fileSystemURL!.lastPathComponent) {
            print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        switch audioDownload.state {
        case .downloaded:
            break
            
        case .downloading:
            audioDownload.totalBytesWritten = totalBytesWritten
            audioDownload.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            })
            break
            
        case .none:
            audioDownload.task?.cancel()
            break
        }
        
        print("filename: \(downloadTask.taskDescription!) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print("URLSession:downloadTask:didFinishDownloadingToURL:")
        
//        print("filename: \(filename) location: \(location)")
        
        if (downloadTask.taskDescription != audioDownload.fileSystemURL!.lastPathComponent) {
            print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        let fileManager = NSFileManager.defaultManager()
        
        // Check if file exist
        if (fileManager.fileExistsAtPath(audioDownload.fileSystemURL!.path!)){
            do {
                try fileManager.removeItemAtURL(audioDownload.fileSystemURL!)
            } catch _ {
            }
        }
        
        do {
            if (audioDownload.state == .downloading) {
                try fileManager.copyItemAtURL(location, toURL: audioDownload.fileSystemURL!)
                try fileManager.removeItemAtURL(location)
                audioDownload.state = .downloaded
            }
        } catch _ {
            print("failed to copy temp audio download file")
            audioDownload.state = .none
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        print("URLSession:task:didCompleteWithError:")
        
        print("filename: \(audioDownload.fileSystemURL!.lastPathComponent!)")
        print("bytes written: \(audioDownload.totalBytesWritten)")
        print("bytes expected to write: \(audioDownload.totalBytesExpectedToWrite)")
        
        if (error != nil) {
            print("with error: \(error!.localizedDescription)")
            audioDownload.state = .none
        }
        
//        removeTempFiles()
        
        audioDownload.session?.invalidateAndCancel()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("URLSession:didBecomeInvalidWithError:")
        
        print("filename: \(audioDownload.fileSystemURL!.lastPathComponent!)")
        print("bytes written: \(audioDownload.totalBytesWritten)")
        print("bytes expected to write: \(audioDownload.totalBytesExpectedToWrite)")
        
        if (error != nil) {
            print("with error: \(error!.localizedDescription)")
        }
        
        audioDownload.session = nil
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        var filename:String?
        
        filename = session.configuration.identifier!.substringFromIndex(Constants.DOWNLOAD_IDENTIFIER.endIndex)
        filename = filename?.substringToIndex(filename!.rangeOfString(Constants.MP3_FILE_EXTENSION)!.startIndex)
        
        for series in globals.series! {
            for sermon in series.sermons! {
                if (sermon.id == Int(filename!)) {
                    sermon.audioDownload.completionHandler?()
                }
            }
        }
    }
}
