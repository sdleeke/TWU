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
    init(sermon:Sermon?,purpose:String?,downloadURL:URL?,fileSystemURL:URL?)
    {
        self.sermon = sermon
        self.purpose = purpose
        self.downloadURL = downloadURL
        self.fileSystemURL = fileSystemURL
        
        if let fileSystemURL = fileSystemURL {
            //            print(fileSystemURL!.path!)
            //            print(FileManager.default.fileExists(atPath: fileSystemURL!.path!))
            if FileManager.default.fileExists(atPath: fileSystemURL.path) {
                self.state = .downloaded
            }
        }
    }
    
    weak var sermon:Sermon?

    var purpose:String?
    
    var downloadURL:URL?
    var fileSystemURL:URL? {
        willSet {
            
        }
        didSet {
            state = isDownloaded ? .downloaded : .none
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
            guard state != oldValue else {
                return
            }
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
            }
        }
    }
    
    var completionHandler: (() -> (Void))?
    
    var isDownloaded : Bool
    {
        get {
            guard let fileSystemURL = fileSystemURL else {
                return false
            }
            
            return FileManager.default.fileExists(atPath: fileSystemURL.path)
        }
    }
    
    func download()
    {
        guard (state == .none) else {
            return
        }
        
        guard let fileSystemURL = fileSystemURL else {
            return
        }
        
        guard let downloadURL = downloadURL else {
            return
        }
        
        state = .downloading
        
        let downloadRequest = URLRequest(url: downloadURL)

        let configuration = URLSessionConfiguration.default
        
//        let configuration = URLSessionConfiguration.ephemeral
        
        // This allows the downloading to continue even if the app goes into the background or terminates.
//        let downloadIdentifier = Constants.IDENTIFIER.DOWNLOAD + fileSystemURL.lastPathComponent
//        let configuration = URLSessionConfiguration.background(withIdentifier: downloadIdentifier)
//        configuration.sessionSendsLaunchEvents = true
        
        session = URLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
        
        session?.sessionDescription = fileSystemURL.lastPathComponent
        
        task = session?.downloadTask(with: downloadRequest)
        task?.taskDescription = fileSystemURL.lastPathComponent
        
        task?.resume()
        
        Thread.onMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }
    
    func delete()
    {
        guard (state == .downloaded) else {
            return
        }
        
        guard let fileSystemURL = fileSystemURL else {
            return
        }
        
        // Check if file exists and if so, delete it.
        if (FileManager.default.fileExists(atPath: fileSystemURL.path)){
            do {
                try FileManager.default.removeItem(at: fileSystemURL)
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        }
        
        totalBytesWritten = 0
        totalBytesExpectedToWrite = 0
        
        state = .none
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
        guard (state == .downloading) else {
            return
        }
        
        //            download.task?.cancelByProducingResumeData({ (data: NSData?) -> Void in
        //            })
        state = .none

        task?.cancel()
        task = nil
        
        totalBytesWritten = 0
        totalBytesExpectedToWrite = 0
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
                if let taskDescription = downloadTask.taskDescription, let range = taskDescription.range(of: ".") {
                    let id = String(taskDescription[..<range.lowerBound])

                    if let num = Int(id), let sermon = globals.sermonFromSermonID(num) {
                        globals.alert(title: "Download Failed", message: sermon.title)
                    }
                } else {
                    globals.alert(title: "Download Failed", message: nil)
                }
            }

            audioDownload.cancel() // task?.

            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self.audioDownload)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.audioDownload.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
                    
            return
        }
        
        if debug {
            print("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
            
            print("session: \(session.sessionDescription ?? "Session Description")")
            print("task: \(downloadTask.taskDescription ?? "Task Description")")
            
            if let fileSystemURL = audioDownload.fileSystemURL {
                print("filename: \(fileSystemURL.lastPathComponent)")
            }
            
            print("bytes written: \(totalBytesWritten)")
            print("bytes expected to write: \(totalBytesExpectedToWrite)")
        }
        
        if (downloadTask.taskDescription != audioDownload.fileSystemURL?.lastPathComponent) {
            print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        switch audioDownload.state {
        case .downloaded:
            break
            
        case .downloading:
            audioDownload.totalBytesWritten = totalBytesWritten
            audioDownload.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.audioDownload.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
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
                if let taskDescription = downloadTask.taskDescription, let range = taskDescription.range(of: ".") {
                    let id = String(taskDescription[..<range.lowerBound])
                
                    if let num = Int(id), let sermon = globals.sermonFromSermonID(num) {
                        globals.alert(title: "Download Failed", message: sermon.title)
                    }
                } else {
                    globals.alert(title: "Download Failed", message: nil)
                }
            }
            
            audioDownload.cancel()

            Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self.audioDownload)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.audioDownload.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            return
        }
        
        if debug {
            print("URLSession:downloadTask:didFinishDownloadingToURL:")
            
            print("taskDescription: \(downloadTask.taskDescription!)")
            
            if let fileSystemURL = audioDownload.fileSystemURL {
                print("filename: \(fileSystemURL.lastPathComponent)")
            }
            
            print("bytes written: \(audioDownload.totalBytesWritten)")
            print("bytes expected to write: \(audioDownload.totalBytesExpectedToWrite)")
            print("location: \(location)")
        }
        
        if (downloadTask.taskDescription != audioDownload.fileSystemURL?.lastPathComponent) {
            print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        let fileManager = FileManager.default
        
        // Check if file exist
        if let fileSystemURL = audioDownload.fileSystemURL, fileManager.fileExists(atPath: fileSystemURL.path) {
            do {
                try fileManager.removeItem(at: fileSystemURL)
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        }
        
        do {
            if audioDownload.state == .downloading, let fileSystemURL = audioDownload.fileSystemURL {
                try fileManager.copyItem(at: location, to: fileSystemURL)
                try fileManager.removeItem(at: location)
                audioDownload.state = .downloaded
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            print("failed to copy temp audio download file")
            globals.alert(title: "Network Error", message: error.localizedDescription)
            audioDownload.state = .none
        }
        
        Thread.onMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            audioDownload.totalBytesExpectedToWrite != -1,
            error == nil else {
            print("DOWNLOAD ERROR: ",(task.response as? HTTPURLResponse)?.statusCode as Any,audioDownload.totalBytesExpectedToWrite)

            if audioDownload.state != .none {
                if let taskDescription = task.taskDescription, let range = taskDescription.range(of: ".") {
                    let idString = String(taskDescription[..<range.lowerBound])
                    
                    if let id = Int(idString), let title = globals.sermonFromSermonID(id)?.title {
                        if let error = error {
                            globals.alert(title: "Download Failed", message: title + "\nError: " + error.localizedDescription)
                        } else {
                            globals.alert(title: "Download Failed", message: title)
                        }
                    }
                } else {
                    if let error = error {
                        globals.alert(title: "Download Failed", message: "Error: " + error.localizedDescription)
                    } else {
                        globals.alert(title: "Download Failed", message: nil)
                    }
                }
            }
            
            audioDownload.cancel()

            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self.audioDownload)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.audioDownload.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            return
        }
        
        if debug {
            print("URLSession:task:didCompleteWithError:")
            
            if let fileSystemURL = audioDownload.fileSystemURL {
                print("path: \(fileSystemURL.path)")
                print("filename: \(fileSystemURL.lastPathComponent)")
            }
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
        
        Thread.onMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        if debug {
            print("URLSession:didBecomeInvalidWithError:")
            
            if let fileSystemURL = audioDownload.fileSystemURL {
                print("path: \(fileSystemURL.path)")
                print("filename: \(fileSystemURL.lastPathComponent)")
            }
            
            print("bytes written: \(audioDownload.totalBytesWritten)")
            print("bytes expected to write: \(audioDownload.totalBytesExpectedToWrite)")
        }
        
        if let error = error {
            NSLog("with error: \(error.localizedDescription)")
            globals.alert(title: "Network Error", message: error.localizedDescription)
            audioDownload.state = .none
        }
        
        audioDownload.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        guard let identifier = session.configuration.identifier else {
            return
        }
        
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        
        var filename = String(identifier[Constants.IDENTIFIER.DOWNLOAD.endIndex...])
        
        if let range = filename.range(of: Constants.FILE_EXTENSION.MP3) {
            filename = String(filename[..<range.lowerBound])
        }
        
        if let series = globals.series {
            for series in series {
                if let sermons = series.sermons {
                    for sermon in sermons {
                        if sermon.id == Int(filename) {
                            sermon.audioDownload.completionHandler?()
                        }
                    }
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
        guard let series = series else {
            return nil
        }
        
        guard let title = series.title else {
            return nil
        }
        
        return "\(title) (Part \(index+1) of \(series.numberOfSermons))"
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
            return String(format: Constants.FILENAME_FORMAT, id)
        }
    }

    var audioURL:URL? {
        get {
            guard let audio = audio else {
                return nil
            }
            
            return URL(string: Constants.URL.BASE.AUDIO + audio)
        }
    }

    var audioFileSystemURL:URL? {
        get {
            guard let audio = audio else {
                return nil
            }
            
            return cachesURL()?.appendingPathComponent(audio)
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
            guard let series = series else {
                print("sermonID: series nil")
                return nil
            }
            
            return "\(series.id)\(Constants.COLON)\(id)"
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
    
    init(series:Series,id:Int) {
        self.series = series
        self.id = id
    }
    
    var index:Int {
        get {
            guard let series = series else {
                return -1
            }
            
            return id - series.startingIndex
        }
    }
    
    override var description : String {
        get {
            guard let series = series else {
                return "ERROR"
            }
            
            //This requires that date, service, title, and speaker fields all be non-nil
            
            var sermonString = "Sermon:"
            
            sermonString = "\(sermonString) \(series.title ?? "Title")"

            sermonString = "\(sermonString) Part:\(index+1)"
            
            return sermonString
        }
    }
    
    class Settings {
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
                    value = globals.sermonSettings?[sermonID]?[key]
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
                
                if (globals.sermonSettings == nil) {
                    globals.sermonSettings = [String:[String:String]]()
                }
                
                if (globals.sermonSettings?[sermonID] == nil) {
                    globals.sermonSettings?[sermonID] = [String:String]()
                }
                
                if (globals.sermonSettings?[sermonID]?[key] != newValue) {
                    globals.sermonSettings?[sermonID]?[key] = newValue
                    
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
    
    lazy var audioDownload:Download! = {
        [unowned self] in
        let download = Download(sermon:self,purpose:Constants.AUDIO,downloadURL:self.audioURL,fileSystemURL:self.audioFileSystemURL)
        // NEVER EVER DO THIS.  Causes LOTS of bad behavior since didSets will NOT happen in an init but they WILL happen below.
//        download.sermon = self
//        download.purpose = Constants.AUDIO
//        download.downloadURL = self.audioURL
//        download.fileSystemURL = self.audioFileSystemURL
        self.downloads[Constants.AUDIO] = download
        return download
    }()
}
