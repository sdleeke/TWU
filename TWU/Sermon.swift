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

struct Download {
    var location:NSURL?
    var totalBytesWritten:Int64 = 0
    var totalBytesExpectedToWrite:Int64 = 0
    var session:NSURLSession?
    var task:NSURLSessionDownloadTask?
    var active:Bool {
        get {
            return state == .downloading
        }
    }
    var state:State = .none
    
    var completionHandler: ((Void) -> (Void))?
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

    var audioURLInFileSystem:NSURL? {
        get {
            return cachesURL()?.URLByAppendingPathComponent(audio!)
        }
    }
    var playingURL:NSURL? {
        get {
            if let url = audioURLInFileSystem {
                if !NSFileManager.defaultManager().fileExistsAtPath(url.path!){
                    return audioURL
                } else {
                    return audioURLInFileSystem
                }
            } else {
                return nil
            }
        }
    }

    var keyBase:String! {
        get {
            if (series == nil) {
                print("keyBase: series nil")
            }
            return "\(series!.id):\(id)"
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
        var sermon:Sermon?
        
        init(sermon:Sermon?) {
            if (sermon == nil) {
                print("nil sermon in Settings init!")
            }
            self.sermon = sermon
        }
        
        subscript(key:String) -> String? {
            get {
                var value:String?
                value = Globals.sermonSettings?[self.sermon!.keyBase]?[key]
                return value
            }
            set {
                if (Globals.sermonSettings?[self.sermon!.keyBase] == nil) {
                    Globals.sermonSettings?[self.sermon!.keyBase] = [String:String]()
                }
                if (newValue != nil) {
                    if (self.sermon != nil) {
                        //                        print("\(Globals.sermonSettings!)")
                        //                        print("\(sermon!)")
                        //                        print("\(newValue!)")
                        Globals.sermonSettings?[self.sermon!.keyBase]?[key] = newValue
                        
                        // For a high volume of activity this can be very expensive.
                        saveSermonSettingsBackground()
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
    
    lazy var download:Download! = {
        [unowned self] in
        var downld = Download()
        downld.state = self.isDownloaded() ? .downloaded : .none
        return downld
    }()
    
    func isDownloaded() -> Bool
    {
        let filename = String(format: Constants.FILENAME_FORMAT, id)
        if let url = cachesURL()?.URLByAppendingPathComponent(filename) {
            return NSFileManager.defaultManager().fileExistsAtPath(url.path!)
        } else {
            return false
        }
    }
    
    func deleteDownload()
    {
        //Need to check and see if we're already downloading
        cancelDownload()
        
        //Delete any previously downloaded file
        let filename = String(format: Constants.FILENAME_FORMAT, id)
        if let url = cachesURL()?.URLByAppendingPathComponent(filename) {
            // Check if file exist
            if (NSFileManager.defaultManager().fileExistsAtPath(url.path!)){
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(url)
                } catch _ {
                }
            }
        }
    }
    
    func cancelDownload()
    {
        if download.active {
            //            download.task?.cancelByProducingResumeData({ (data: NSData?) -> Void in
            //            })
            download.task?.cancel()
            download.task = nil
        }
        
        download.state = .none
        download.totalBytesWritten = 0
        download.totalBytesExpectedToWrite = 0
    }
    
    func downloadAudio()
    {
        download.state = .downloading
        
        let filename = String(format: Constants.FILENAME_FORMAT, id)
        let audioURL = Constants.BASE_AUDIO_URL + filename
        let downloadRequest = NSMutableURLRequest(URL: NSURL(string: audioURL)!)
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(Constants.DOWNLOAD_IDENTIFIER + filename)
        configuration.sessionSendsLaunchEvents = true
        
        //        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        download.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        download.task = download.session?.downloadTaskWithRequest(downloadRequest)
        download.task?.taskDescription = filename
        
        download.task?.resume()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("URLSession: \(session.description) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        let filename = downloadTask.taskDescription!
        
        if (download.state == .downloading) {
            download.totalBytesWritten = totalBytesWritten
            download.totalBytesExpectedToWrite = totalBytesExpectedToWrite
        }
        
        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) location: \(location)")
        
        let fileManager = NSFileManager.defaultManager()
        
        if let destinationURL = cachesURL()?.URLByAppendingPathComponent(filename) {
            // Check if file exist
            if (fileManager.fileExistsAtPath(destinationURL.path!)){
                do {
                    try fileManager.removeItemAtURL(destinationURL)
                } catch _ {
                }
            }
            
            do {
                if (download.state == .downloading) {
                    try fileManager.copyItemAtURL(location, toURL: destinationURL)
                    try fileManager.removeItemAtURL(location)
                    download.state = .downloaded
                }
            } catch _ {
                print("failed to copy temp audio download file")
                download.state = .none
            }
        } else {
            print("Error!")
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if (error != nil) {
            print("Download failed for: \(session.description)")
            download.state = .none
        } else {
            print("Download succeeded for: \(session.description)")
            if (download.state == .downloading) { download.state = .downloaded }
        }
        
        removeTempFiles()
        
        let filename = task.taskDescription
        print("filename: \(filename!) error: \(error)")
        
        download.session?.invalidateAndCancel()
        
        //        if let taskIndex = Globals.downloadTasks.indexOf(task as! NSURLSessionDownloadTask) {
        //            Globals.downloadTasks.removeAtIndex(taskIndex)
        //        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        download.session = nil
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        var filename:String?
        
        filename = session.configuration.identifier!.substringFromIndex(Constants.DOWNLOAD_IDENTIFIER.endIndex)
        filename = filename?.substringToIndex(filename!.rangeOfString(Constants.MP3_FILE_EXTENSION)!.startIndex)
        
        for series in Globals.series! {
            for sermon in series.sermons! {
                if (sermon.id == Int(filename!)) {
                    sermon.download.completionHandler?()
                }
            }
        }
    }
}
