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
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            totalBytesExpectedToWrite != -1 else {
                print("DOWNLOAD ERROR: ",(downloadTask.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
                
                if state != .none {
                    if let taskDescription = downloadTask.taskDescription, let range = taskDescription.range(of: ".") {
                        let id = String(taskDescription[..<range.lowerBound])
                        
                        if let sermon = Globals.shared.series.sermon(from:id) { // let num = Int(id),
                            Alerts.shared.alert(title: "Download Failed", message: sermon.title)
                        }
                    } else {
                        Alerts.shared.alert(title: "Download Failed", message: nil)
                    }
                }
                
                cancel() // task?.
                
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
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
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object:self.sermon)
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
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            totalBytesExpectedToWrite != -1  else {
                print("DOWNLOAD ERROR: ",(downloadTask.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
                
                if state != .none {
                    if let taskDescription = downloadTask.taskDescription, let range = taskDescription.range(of: ".") {
                        let id = String(taskDescription[..<range.lowerBound])
                        
                        if let sermon = Globals.shared.series.sermon(from:id) { // let num = Int(id),
                            Alerts.shared.alert(title: "Download Failed", message: sermon.title)
                        }
                    } else {
                        Alerts.shared.alert(title: "Download Failed", message: nil)
                    }
                }
                
                cancel()
                
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
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
        
        // Check if file exist
        if let fileSystemURL = fileSystemURL, fileManager.fileExists(atPath: fileSystemURL.path) {
            do {
                try fileManager.removeItem(at: fileSystemURL)
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        }
        
        do {
            if state == .downloading, let fileSystemURL = fileSystemURL {
                try fileManager.copyItem(at: location, to: fileSystemURL)
                try fileManager.removeItem(at: location)
                state = .downloaded
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            print("failed to copy temp audio download file")
            Alerts.shared.alert(title: "Network Error", message: error.localizedDescription)
            state = .none
        }
        
        Thread.onMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            totalBytesExpectedToWrite != -1,
            error == nil else {
                print("DOWNLOAD ERROR: ",(task.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
                
                if state != .none {
                    if let taskDescription = task.taskDescription, let range = taskDescription.range(of: ".") {
                        let id = String(taskDescription[..<range.lowerBound])
                        
                        if let title = Globals.shared.series.sermon(from:id)?.title { // let id = Int(idString),
                            if let error = error {
                                Alerts.shared.alert(title: "Download Failed", message: title + "\nError: " + error.localizedDescription)
                            } else {
                                Alerts.shared.alert(title: "Download Failed", message: title)
                            }
                        }
                    } else {
                        if let error = error {
                            Alerts.shared.alert(title: "Download Failed", message: "Error: " + error.localizedDescription)
                        } else {
                            Alerts.shared.alert(title: "Download Failed", message: nil)
                        }
                    }
                }
                
                cancel()
                
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
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
        
        Thread.onMainThread {
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
        
        var filename = String(identifier[Constants.IDENTIFIER.DOWNLOAD.endIndex...])
        
        if let range = filename.range(of: Constants.FILE_EXTENSION.MP3) {
            filename = String(filename[..<range.lowerBound])
        }
        
        completionHandler?()
    }
}

class Download : NSObject
{
    init(sermon:Sermon?,purpose:String?,downloadURL:URL?,fileSystemURL:URL?)
    {
        self.sermon = sermon
        self.purpose = purpose
        self.downloadURL = downloadURL
        self.fileSystemURL = fileSystemURL
        
        if let fileSystemURL = fileSystemURL {
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
        
        // This allows the downloading to continue even if the app goes into the background or terminates.
        //        let downloadIdentifier = Constants.IDENTIFIER.DOWNLOAD + fileSystemURL.lastPathComponent
        //        let configuration = URLSessionConfiguration.background(withIdentifier: downloadIdentifier)
        //        configuration.sessionSendsLaunchEvents = true
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
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
        
        state = .none
        
        task?.cancel()
        task = nil
        
        totalBytesWritten = 0
        totalBytesExpectedToWrite = 0
    }
}
