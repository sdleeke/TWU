//
//  FetchImage.swift
//  TWU
//
//  Created by Steve Leeke on 10/5/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class FetchImage : Fetch<UIImage>, Size
{
    deinit {
        debug(self)
    }
    
    var url : URL?
    
    init?(name:String? = nil, url:URL?)
    {
        guard let url = url else {
            return nil
        }
        
        super.init(name: name)
        
        fetch = { [weak self] () -> (UIImage?) in
            return self?.fetchIt()
        }
        
        store = { [weak self] (image:UIImage?) in
            self?.storeIt(image: image)
        }
        
        retrieve = { [weak self] in
            return self?.retrieveIt()
        }
        
        self.url = url
    }
    
    var fileSystemURL:URL?
    {
        get {
            return url?.fileSystemURL
        }
    }
    
    var exists:Bool
    {
        get {
            return fileSystemURL?.exists ?? false
        }
    }
    
    func block(_ block:((UIImage?)->()))
    {
        if let image = result {
            block(image)
        }
    }
    
    var imageName : String?
    {
        return url?.lastPathComponent
    }
    
    var image : UIImage?
    {
        get {
            return result
        }
    }
    
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
        set {
            _fileSize = newValue
        }
    }
    
    func delete(_ block:Bool = true)
    {
        clear()
        fileSize = nil
        fileSystemURL?.delete(block)
    }

    static var semaphore = DispatchSemaphore(value: 3)

    @objc func downloadFailed()
    {
        // What else should we do if a download fails?
        // Right now you have to scroll restart the download.
        download = nil
        FetchImage.semaphore.signal()
    }
    
    @objc func downloaded()
    {
        // completion was called
        download = nil
        FetchImage.semaphore.signal()
    }
    
    var download : Download?
    {
        didSet {
            guard download != oldValue else {
                return
            }
            
            if oldValue != nil {
                Thread.onMainThread {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: oldValue)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOADED), object: oldValue)
                }
            }

            if download != nil {
                Thread.onMainThread {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFailed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self.download)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.downloaded), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOADED), object: self.download)
                }
            }
        }
    }
    
    func downloadIt(completion:(()->())?)
    {
        queue.sync {
            FetchImage.semaphore.wait()
        }

        guard retrieveIt() == nil else {
            completion?()
            return
        }

        // This creates a download if one doesn't exist
        download = download ?? Download(downloadURL: url, fileSystemURL: url?.fileSystemURL)
        
        // This sets or updates the completion to be executed upon a successful download since what happens with an image
        // may change even while it is being downloaded.
        download?.completion = completion
        
        // This starts the download, but only if it isn't already downloading.
        download?.download(background: false)
    }
    
    func fetchIt() -> UIImage?
    {
        return self.url?.image
    }
    
    func retrieveIt() -> UIImage?
    {
        return fileSystemURL?.data?.image
    }
    
    func storeIt(image:UIImage?)
    {
        guard let image = image else {
            return
        }
        
        guard let fileSystemURL = self.fileSystemURL else {
            return
        }
        
        guard !fileSystemURL.exists else {
            return
        }
        
        do {
            try image.jpegData(compressionQuality: 1.0)?.write(to: fileSystemURL, options: [.atomic])
            print("Image \(fileSystemURL.lastPathComponent) saved to file system")
            fileSize = fileSystemURL.fileSize ?? 0
        } catch let error {
            print(error.localizedDescription)
            print("Image \(fileSystemURL.lastPathComponent) not saved to file system")
        }
    }
}

//class FetchImage : Size
//{
//    deinit {
//        debug(self)
//    }
//
//    var url : URL?
//
//    init?(url:URL?)
//    {
//        guard let url = url else {
//            return nil
//        }
//
//        self.url = url
//    }
//
//    var fileSystemURL:URL?
//    {
//        get {
//            return url?.fileSystemURL
//        }
//    }
//
//    var exists:Bool
//    {
//        get {
//            return fileSystemURL?.exists ?? false
//        }
//    }
//
//    func fetchIt() -> UIImage?
//    {
//        return self.url?.image
//    }
//
//    func block(_ block:((UIImage?)->()))
//    {
//        if let image = image {
//            block(image)
//        }
//    }
//
//    var imageName : String?
//    {
//        return url?.lastPathComponent
//    }
//
//    var image : UIImage?
//    {
//        get {
//            return fetch?.result
//        }
//    }
//
//    func load()
//    {
//        fetch?.load()
//    }
//
//    // Replacing these two w/ a Shadow class is a big performance hit
//    internal var _fileSize : Int?
//    var fileSize : Int
//    {
//        get {
//            guard let fileSize = _fileSize else {
//                _fileSize = fileSystemURL?.fileSize
//                return _fileSize ?? 0
//            }
//
//            return fileSize
//        }
////        set {
////            _fileSize = newValue
////        }
//    }
//
//    func delete()
//    {
//        _fileSize = nil
//        fileSystemURL?.delete()
//    }
//
//    func retrieveIt() -> UIImage?
//    {
//        return fileSystemURL?.data?.image
//
////        guard let fileSystemURL = self.fileSystemURL else {
////            return nil
////        }
////
////        guard fileSystemURL.exists else {
////            return nil
////        }
////
////        guard let image = UIImage(contentsOfFile: fileSystemURL.path) else {
////            return nil
////        }
////
////        return image
//    }
//
//    func storeIt(image:UIImage?)
//    {
//        guard let image = image else {
//            return
//        }
//
//        guard let fileSystemURL = self.fileSystemURL else {
//            return
//        }
//
//        guard !fileSystemURL.exists else {
//            return
//        }
//
//        do {
//            try image.jpegData(compressionQuality: 1.0)?.write(to: fileSystemURL, options: [.atomic])
//            print("Image \(fileSystemURL.lastPathComponent) saved to file system")
//        } catch let error as NSError {
//            print(error.localizedDescription)
//            print("Image \(fileSystemURL.lastPathComponent) not saved to file system")
//        }
//    }
//
//    lazy var fetch:Fetch<UIImage>? = { [weak self] in // THIS IS VITAL TO PREVENT A MEMORY LEAK
//        guard let imageName = imageName else {
//            return nil
//        }
//
//        let fetch = Fetch<UIImage>(name:imageName)
//
//        fetch.store = { (image:UIImage?) in
//            self?.storeIt(image: image)
//        }
//
//        fetch.retrieve = {
//            return self?.retrieveIt()
//        }
//
//        fetch.fetch = {
//            return self?.fetchIt()
//        }
//
//        return fetch
//    }()
//}

class FetchCachedImage : FetchImage
{
    deinit {
        debug(self)
    }
    
    private static var cache : ThreadSafeDN<UIImage>! = { // ictionary
        return ThreadSafeDN<UIImage>(name:"FetchImageCache") // ictionary
    }()
    
    private static var queue : DispatchQueue = {
        return DispatchQueue(label: "FetchImageCacheQueue")
    }()
    
    override func fetchIt() -> UIImage?
    {
        return FetchCachedImage.queue.sync {
            if let image = self.cachedImage {
                return image
            }
            
            let image = super.fetchIt()
            
            return image
        }
    }
    
    override func retrieveIt() -> UIImage?
    {
        return FetchCachedImage.queue.sync {
            // Belt and susupenders since this is also in fetchIt() which means it would happen there not here.
            if let image = self.cachedImage {
                return image
            }
            
            return super.retrieveIt()
        }
    }
    
    override func storeIt(image: UIImage?)
    {
        FetchCachedImage.queue.sync {
            // The indication that it needs to be stored is that it isn't in the cache yet.
            guard self.cachedImage == nil else {
                return
            }
            
            super.storeIt(image: image)
            
            self.cachedImage = image
        }
    }
    
    func clearCache()
    {
        FetchCachedImage.cache.clear()
    }
    
    var cachedImage : UIImage?
    {
        get {
            guard let imageName = self.imageName else {
                return nil
            }
            
            return FetchCachedImage.cache?[imageName]
        }
        set {
            guard let imageName = self.imageName else {
                return
            }
            
            FetchCachedImage.cache?[imageName] = newValue
        }
    }
}

