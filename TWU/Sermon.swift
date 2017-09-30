//
//  Sermon.swift
//  TWU
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

var debug = true

enum State {
    case downloading
    case downloaded
    case none
}

class Download {
    weak var sermon:Sermon?
    
    var purpose:String?
    
    var downloadURL:URL?
    var fileSystemURL:URL? {
        willSet {
            
        }
        didSet {
            state = isDownloaded() ? .downloaded : .none
        }
    }
    
    var totalBytesWritten:Int64 = 0
    var totalBytesExpectedToWrite:Int64 = 0
    
    var session:URLSession?
    
    var task:URLSessionDownloadTask?
    
    var active:Bool {
        get {
            return state == .downloading
        }
    }
    var state:State = .none {
        willSet {
            
        }
        didSet {
            if state != oldValue {
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
                })
            }
        }
    }
    
    var completionHandler: (() -> (Void))?
    
    func isDownloaded() -> Bool
    {
        if fileSystemURL != nil {
            return FileManager.default.fileExists(atPath: fileSystemURL!.path)
        } else {
            return false
        }
    }
    
    func download()
    {
        if (state == .none) {
            state = .downloading
            
            let downloadRequest = URLRequest(url: downloadURL!)

            let configuration = URLSessionConfiguration.ephemeral
            
            // This allows the downloading to continue even if the app goes into the background or terminates.
//            let configuration = URLSessionConfiguration.background(withIdentifier: Constants.IDENTIFIER.DOWNLOAD + fileSystemURL!.lastPathComponent)
//            configuration.sessionSendsLaunchEvents = true
            
            //        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            
            session = URLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
            
            session?.sessionDescription = self.fileSystemURL!.lastPathComponent
            
            task = session?.downloadTask(with: downloadRequest)
            task?.taskDescription = fileSystemURL?.lastPathComponent
            
            task?.resume()
            
            DispatchQueue.main.async(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
        }
    }
    
    func delete()
    {
        if (state == .downloaded) {
            // Check if file exists and if so, delete it.
            if (FileManager.default.fileExists(atPath: fileSystemURL!.path)){
                do {
                    try FileManager.default.removeItem(at: fileSystemURL!)
                } catch let error as NSError {
                    NSLog(error.localizedDescription)
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
            cancel()
            break
            
        case .downloaded:
            delete()
            break
            
        default:
            break
        }
    }
    
    func cancel()
    {
        if (state == .downloading) {
            //            download.task?.cancelByProducingResumeData({ (data: NSData?) -> Void in
            //            })
            state = .none

            task?.cancel()
            task = nil
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
        }
    }
}

extension Sermon : URLSessionDownloadDelegate
{
    // NEED TO HANDLED >400 ERRORS
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
                  totalBytesExpectedToWrite != -1 else {
            print("DOWNLOAD ERROR: ",(downloadTask.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
            
            if audioDownload.state != .none {
                if let range = downloadTask.taskDescription?.range(of: "."),
                    let id = downloadTask.taskDescription?.substring(to: range.lowerBound),
                    let sermon = globals.sermonFromSermonID(Int(id)!) {
                    globals.alert(title: "Download Failed", message: sermon.title)
                } else {
                    globals.alert(title: "Download Failed", message: nil)
                }
            }

//            globals.alert(title: "Download Failed", message: "Please check your network connection and try again")
                    
            audioDownload.cancel() // task?.
//            audioDownload.state = .none

            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self.audioDownload)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.audioDownload.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
                    
            return
        }
        
        if debug {
            print("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
            
            print("session: \(session.sessionDescription ?? "Session Description")")
            print("task: \(downloadTask.taskDescription ?? "Task Description")")
            print("filename: \(audioDownload.fileSystemURL!.lastPathComponent)")
            print("bytes written: \(totalBytesWritten)")
            print("bytes expected to write: \(totalBytesExpectedToWrite)")
        }
        
        if (downloadTask.taskDescription != audioDownload.fileSystemURL!.lastPathComponent) {
            print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        switch audioDownload.state {
        case .downloaded:
            break
            
        case .downloading:
            audioDownload.totalBytesWritten = totalBytesWritten
            audioDownload.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.audioDownload.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            
            break
            
        case .none:
            audioDownload.task?.cancel()
            break
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
              audioDownload.totalBytesExpectedToWrite != -1  else {
            print("DOWNLOAD ERROR: ",(downloadTask.response as? HTTPURLResponse)?.statusCode as Any,audioDownload.totalBytesExpectedToWrite)
        
            if audioDownload.state != .none {
                if let range = downloadTask.taskDescription?.range(of: "."),
                    let id = downloadTask.taskDescription?.substring(to: range.lowerBound),
                    let sermon = globals.sermonFromSermonID(Int(id)!) {
                    globals.alert(title: "Download Failed", message: sermon.title)
                } else {
                    globals.alert(title: "Download Failed", message: nil)
                }
            }
//            if audioDownload.state != .none {
//                globals.alert(title: "Download Failed", message: "Please check your network connection and try again")
//            }
            
            audioDownload.cancel() // .task?
//            audioDownload.state = .none

            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self.audioDownload)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.audioDownload.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            return
        }
        
        if debug {
            print("URLSession:downloadTask:didFinishDownloadingToURL:")
            
            print("taskDescription: \(downloadTask.taskDescription!)")
            print("filename: \(audioDownload.fileSystemURL!.lastPathComponent)")
            print("bytes written: \(audioDownload.totalBytesWritten)")
            print("bytes expected to write: \(audioDownload.totalBytesExpectedToWrite)")
            print("location: \(location)")
        }
        
        if (downloadTask.taskDescription != audioDownload.fileSystemURL!.lastPathComponent) {
            print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        let fileManager = FileManager.default
        
        // Check if file exist
        if (fileManager.fileExists(atPath: audioDownload.fileSystemURL!.path)){
            do {
                try fileManager.removeItem(at: audioDownload.fileSystemURL!)
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        }
        
        do {
            if (audioDownload.state == .downloading) {
                try fileManager.copyItem(at: location, to: audioDownload.fileSystemURL!)
                try fileManager.removeItem(at: location)
                audioDownload.state = .downloaded
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            print("failed to copy temp audio download file")
            globals.alert(title: "Network Error", message: error.localizedDescription)
            audioDownload.state = .none
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            audioDownload.totalBytesExpectedToWrite != -1,
            error == nil else {
            print("DOWNLOAD ERROR: ",(task.response as? HTTPURLResponse)?.statusCode as Any,audioDownload.totalBytesExpectedToWrite)

            if audioDownload.state != .none {
                if let range = task.taskDescription?.range(of: "."),
                    let idString = task.taskDescription?.substring(to: range.lowerBound),
                    let id = Int(idString),
                    let title = globals.sermonFromSermonID(id)?.title {
                    if let error = error {
                        globals.alert(title: "Download Failed", message: title + "\nError: " + error.localizedDescription)
                    } else {
                        globals.alert(title: "Download Failed", message: title)
                    }
                } else {
                    if let error = error {
                        globals.alert(title: "Download Failed", message: "Error: " + error.localizedDescription)
                    } else {
                        globals.alert(title: "Download Failed", message: nil)
                    }
                }
            }
            
            audioDownload.cancel() // .task?
//            audioDownload.state = .none

            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self.audioDownload)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.audioDownload.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            return
        }
        
        if debug {
            print("URLSession:task:didCompleteWithError:")
            
            print("path: \(audioDownload.fileSystemURL!.path)")
            print("filename: \(audioDownload.fileSystemURL!.lastPathComponent)")
            print("bytes written: \(audioDownload.totalBytesWritten)")
            print("bytes expected to write: \(audioDownload.totalBytesExpectedToWrite)")
        }
        
        if let error = error {
            NSLog("with error: \(error.localizedDescription) statusCode:\(statusCode)")
            // May be user initiated.
            if error.localizedDescription != "cancelled" {
                globals.alert(title: "Network Error", message: error.localizedDescription)
            }
            audioDownload.state = .none
        }
        
        //        removeTempFiles()
        
        audioDownload.session?.invalidateAndCancel()
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        if debug {
            print("URLSession:didBecomeInvalidWithError:")
            
            print("path: \(audioDownload.fileSystemURL!.path)")
            print("filename: \(audioDownload.fileSystemURL!.lastPathComponent)")
            print("bytes written: \(audioDownload.totalBytesWritten)")
            print("bytes expected to write: \(audioDownload.totalBytesExpectedToWrite)")
        }
        
        if (error != nil) {
            NSLog("with error: \(error!.localizedDescription)")
            globals.alert(title: "Network Error", message: error!.localizedDescription)
            audioDownload.state = .none
        }
        
        audioDownload.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        var filename:String?
        
        filename = session.configuration.identifier!.substring(from: Constants.IDENTIFIER.DOWNLOAD.endIndex)
        filename = filename?.substring(to: filename!.range(of: Constants.FILE_EXTENSION.MP3)!.lowerBound)
        
        for series in globals.series! {
            for sermon in series.sermons! {
                if (sermon.id == Int(filename!)) {
                    sermon.audioDownload.completionHandler?()
                }
            }
        }
    }
}

class Sermon : NSObject {
    weak var series:Series?
    
    var id:Int
    
    var title:String?
    {
        if let title = series?.title {
            return "\(title) (Part \(index+1) of \(series!.numberOfSermons))"
        } else {
            return nil
        }
    }
    
    var atEnd:Bool {
        get {
            return settings![Constants.SETTINGS.AT_END] == "YES"
        }
        
        set {
            settings?[Constants.SETTINGS.AT_END] = newValue ? "YES" : "NO"
        }
    }
    
    var audio:String? {
        get {
            return String(format: Constants.FILENAME_FORMAT, id)
        }
    }

    var audioURL:URL? {
        get {
            return URL(string: Constants.URL.BASE.AUDIO + audio!)
        }
    }

    var audioFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(audio!)
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
            if (series == nil) {
                print("sermonID: series nil")
            }
            return "\(series!.id)\(Constants.COLON)\(id)"
        }
    }

    func hasCurrentTime() -> Bool
    {
        return (currentTime != nil) && (Float(currentTime!) != nil)
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
            sermonString = "\(sermonString) \(series!.title ?? "Title")"
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
                guard (newValue != nil) else {
                    print("newValue == nil in Settings!")
                    return
                }
                
                guard (sermon != nil) else {
                    print("sermon == nil in Settings!")
                    return
                }
                
                guard (sermon?.sermonID != nil) else {
                    print("sermon!.sermonID == nil in Settings!")
                    return
                }
                
                if (globals.sermonSettings == nil) {
                    globals.sermonSettings = [String:[String:String]]()
                }
                
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
}
