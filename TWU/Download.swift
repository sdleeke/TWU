//
//  Download.swift
//  TWU
//
//  Created by Steve Leeke on 10/15/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

enum State {
    case downloading
    case downloaded
    case none
}

extension Download : URLSessionDownloadDelegate
{
    // NEED TO HANDLE >400 ERRORS

    func downloadFailed()
    {
        print("DOWNLOAD ERROR: ",(task?.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
        
        if state != .none {
            if let taskDescription = task?.taskDescription, let range = taskDescription.range(of: ".") {
                let id = String(taskDescription[..<range.lowerBound])
                
                if let sermon = Globals.shared.series.sermon(from:id) { // let num = Int(id),
                    Alerts.shared.alert(title: "Download Failed", message: sermon.title)
                }
            } else {
                Alerts.shared.alert(title: "Download Failed", message: nil)
            }
        }
        
        cancel()
        
        Thread.onMain { [weak self] in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self?.sermon)
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }

//        print("DOWNLOAD ERROR: ",(downloadTask.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
//
//        if state != .none {
//            if let taskDescription = downloadTask.taskDescription, let range = taskDescription.range(of: ".") {
//                let id = String(taskDescription[..<range.lowerBound])
//
//                if let sermon = Globals.shared.series.sermon(from:id) { // let num = Int(id),
//                    Alerts.shared.alert(title: "Download Failed", message: sermon.title)
//                }
//            } else {
//                Alerts.shared.alert(title: "Download Failed", message: nil)
//            }
//        }
//
//        cancel() // task?.
//
//        Thread.onMain { [weak self] in
//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self)
//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
//            UIApplication.shared.isNetworkActivityIndicatorVisible = false
//        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            totalBytesExpectedToWrite != -1 else {
                downloadFailed()
                return
        }
        
        if debug {
            print("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
            
            print("session: \(session.sessionDescription ?? "Session Description")")
            print("task: \(downloadTask.taskDescription ?? "Task Description")")
            
            if let fileSystemURL = fileSystemURL {
                print("filename: \(fileSystemURL.lastPathComponent)")
            }
            
            print("bytes written: \(totalBytesWritten)")
            print("bytes expected to write: \(totalBytesExpectedToWrite)")
        }
        
        if (downloadTask.taskDescription != fileSystemURL?.lastPathComponent) {
            print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        switch state {
        case .downloaded:
            break
            
        case .downloading:
            self.totalBytesWritten = totalBytesWritten
            self.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            
            Thread.onMain { [weak self] in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object:self?.sermon)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            break
            
        case .none:
            task?.cancel()
            break
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400  else {
                downloadFailed()
                return
        }
        
        if debug {
            print("URLSession:downloadTask:didFinishDownloadingToURL:")
            
            if let taskDescription = downloadTask.taskDescription {
                print("taskDescription: \(taskDescription)")
            }
            
            if let fileSystemURL = fileSystemURL {
                print("filename: \(fileSystemURL.lastPathComponent)")
            }
            
            print("bytes written: \(totalBytesWritten)")
            print("bytes expected to write: \(totalBytesExpectedToWrite)")
            print("location: \(location)")
        }
        
        if (downloadTask.taskDescription != fileSystemURL?.lastPathComponent) {
            print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        let fileManager = FileManager.default
       
        fileSystemURL?.delete()
        
//        // Check if file exist
//        if let fileSystemURL = fileSystemURL, fileManager.fileExists(atPath: fileSystemURL.path) {
//            do {
//                try fileManager.removeItem(at: fileSystemURL)
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//            }
//        }
        
        do {
            if state == .downloading, let fileSystemURL = fileSystemURL {
                try fileManager.copyItem(at: location, to: fileSystemURL)
                
                location.delete()
//                try fileManager.removeItem(at: location)
                
                state = .downloaded
            }
            
            completion?()
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            print("failed to copy temp audio download file")
            Alerts.shared.alert(title: "Network Error", message: error.localizedDescription)
            state = .none
        }
        
        Thread.onMain { [weak self] in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            error == nil else {
                downloadFailed()
//                print("DOWNLOAD ERROR: ",(task.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
//
//                if state != .none {
//                    if let taskDescription = task.taskDescription, let range = taskDescription.range(of: ".") {
//                        let id = String(taskDescription[..<range.lowerBound])
//
//                        if let title = Globals.shared.series.sermon(from:id)?.title { // let id = Int(idString),
//                            if let error = error {
//                                Alerts.shared.alert(title: "Download Failed", message: title + "\nError: " + error.localizedDescription)
//                            } else {
//                                Alerts.shared.alert(title: "Download Failed", message: title)
//                            }
//                        }
//                    } else {
//                        if let error = error {
//                            Alerts.shared.alert(title: "Download Failed", message: "Error: " + error.localizedDescription)
//                        } else {
//                            Alerts.shared.alert(title: "Download Failed", message: nil)
//                        }
//                    }
//                }
//
//                cancel()
//
//                Thread.onMain { [weak self] in
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self)
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
//                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                }
                return
        }
        
        if debug {
            print("URLSession:task:didCompleteWithError:")
            
            if let fileSystemURL = fileSystemURL {
                print("path: \(fileSystemURL.path)")
                print("filename: \(fileSystemURL.lastPathComponent)")
            }
            print("bytes written: \(totalBytesWritten)")
            print("bytes expected to write: \(totalBytesExpectedToWrite)")
        }
        
        if let error = error {
            NSLog("with error: \(error.localizedDescription) statusCode:\(statusCode)")
            // May be user initiated.
            if error.localizedDescription != "cancelled" {
                Alerts.shared.alert(title: "Network Error", message: error.localizedDescription)
            }
            state = .none
        }
        
        session.invalidateAndCancel()
        
        Thread.onMain { [weak self] in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        if debug {
            print("URLSession:didBecomeInvalidWithError:")
            
            if let fileSystemURL = fileSystemURL {
                print("path: \(fileSystemURL.path)")
                print("filename: \(fileSystemURL.lastPathComponent)")
            }
            
            print("bytes written: \(totalBytesWritten)")
            print("bytes expected to write: \(totalBytesExpectedToWrite)")
        }
        
        if let error = error {
            NSLog("with error: \(error.localizedDescription)")
            Alerts.shared.alert(title: "Network Error", message: error.localizedDescription)
            state = .none
        }
        
        self.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        guard let identifier = session.configuration.identifier else {
            return
        }
        
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        
//        var filename = String(identifier[Constants.IDENTIFIER.DOWNLOAD.endIndex...])
        if let range = identifier.range(of: ":") {
            let filename = String(identifier[range.upperBound...])
            
//            if let range = filename.range(of: Constants.FILE_EXTENSION.MP3) {
            
//            filename = String(filename[..<range.lowerBound])
            
            if task?.taskDescription == filename {
                completion?()
            }
        }
//
//        completionHandler?()
    }
}

class Download : NSObject, Size
{
    deinit {
        debug(self)
    }
    
    init?(downloadURL:URL?, fileSystemURL:URL?)
    {
        guard let downloadURL = downloadURL else {
            return nil
        }
        
        guard let fileSystemURL = fileSystemURL else {
            return nil
        }
        
        super.init()
        
        self.downloadURL = downloadURL
        self.fileSystemURL = fileSystemURL
        
        if FileManager.default.fileExists(atPath: fileSystemURL.path) {
            self.state = .downloaded
        }
    }
    
    init?(sermon:Sermon?,purpose:String?,downloadURL:URL?,fileSystemURL:URL?)
    {
        guard let sermon = sermon else {
            return nil
        }
        
        guard let purpose = purpose else {
            return nil
        }

        guard let downloadURL = downloadURL else {
            return nil
        }
        
        guard let fileSystemURL = fileSystemURL else {
            return nil
        }
        
        super.init()
        
        self.sermon = sermon
        self.purpose = purpose
        
        self.downloadURL = downloadURL
        self.fileSystemURL = fileSystemURL
        
        if FileManager.default.fileExists(atPath: fileSystemURL.path) {
            self.state = .downloaded
        }
    }
    
    weak var sermon:Sermon?
    
    var purpose:String?
    
    var id:String?
    
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
    
    var state:State
    {
        get {
            if _state == .downloaded {
                if downloadURL?.exists != true {
                    _state = .none
                }
            }
            return _state
        }
        set {
            _state = newValue
        }
    }
    
    var _state:State = .none
    {
        willSet {
            
        }
        didSet {
            guard _state != oldValue else {
                return
            }
            
            if self.sermon != nil {
                Thread.onMain { [weak self] in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self?.sermon)
                }
            }
            
            if state == .downloaded {
                Thread.onMain { [weak self] in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOADED), object: self)
                }
            }
        }
    }
    
    var completion: (() -> (Void))?
    
    var isDownloaded : Bool
    {
        get {
            guard let fileSystemURL = fileSystemURL else {
                return false
            }
            
            return FileManager.default.fileExists(atPath: fileSystemURL.path)
        }
    }
    
    func download(background:Bool)
    {
        guard (state == .none) else {
            return
        }
        
        guard state != .downloading else {
            return
        }
        
        guard fileSystemURL?.exists == false else {
            return
        }
        
        guard let downloadURL = downloadURL else {
            return
        }
        
        state = .downloading
        
        let downloadRequest = URLRequest(url: downloadURL)
        
        var configuration : URLSessionConfiguration?

        id = Constants.IDENTIFIER.DOWNLOAD + Date().timeIntervalSinceReferenceDate.description + ":"
        
        if background, let id = id, let lastPathComponent = fileSystemURL?.lastPathComponent {
//            configuration = .background(withIdentifier: Constants.IDENTIFIER.DOWNLOAD + lastPathComponent)
            
            configuration = .background(withIdentifier: id + lastPathComponent)
            
            // This allows the downloading to continue even if the app goes into the background or terminates.
            configuration?.sessionSendsLaunchEvents = true
        } else {
            configuration = .default
        }
        
        if let configuration = configuration {
            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            
            session?.sessionDescription = fileSystemURL?.lastPathComponent
            
            task = session?.downloadTask(with: downloadRequest)
            task?.taskDescription = fileSystemURL?.lastPathComponent
            
            task?.resume()
            
            Thread.onMain { [weak self] in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
    }
    
    // Replacing these two w/ a Shadow class is a big performance hit
    internal var _fileSize : Int?
    var fileSize : Int?
    {
        get {
            guard let fileSize = _fileSize else {
                _fileSize = fileSystemURL?.fileSize
                return _fileSize
            }
            
            return fileSize
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

        _fileSize = nil
        fileSystemURL.delete()
        
//        // Check if file exists and if so, delete it.
//        if (FileManager.default.fileExists(atPath: fileSystemURL.path)){
//            do {
//                try FileManager.default.removeItem(at: fileSystemURL)
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//            }
//        }
        
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
        
        state = .none
        
        task?.cancel()
        task = nil
        
        totalBytesWritten = 0
        totalBytesExpectedToWrite = 0
    }
}
