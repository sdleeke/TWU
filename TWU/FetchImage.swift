//
//  FetchImage.swift
//  TWU
//
//  Created by Steve Leeke on 10/5/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class FetchImage
{
    var url : URL?
    
    init?(url:URL?)
    {
        guard let url = url else {
            return nil
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
    
    func fetchIt() -> UIImage?
    {
        return self.url?.image
    }
    
    func block(_ block:((UIImage?)->()))
    {
        if let image = image {
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
            return fetch?.result
        }
    }
    
    func load()
    {
        fetch?.load()
    }

    private var _fileSize : Int?
    {
        didSet {
            
        }
    }
    var fileSize : Int
    {
        get {
            guard let fileSize = _fileSize else {
                _fileSize = fileSystemURL?.fileSize
                return _fileSize ?? 0
            }
            
            return fileSize
        }
        set {
            _fileSize = newValue
        }
    }
    
    func delete()
    {
        _fileSize = nil
        fileSystemURL?.delete()
    }
    
    func retrieveIt() -> UIImage?
    {
        return fileSystemURL?.data?.image
        
//        guard let fileSystemURL = self.fileSystemURL else {
//            return nil
//        }
//
//        guard fileSystemURL.exists else {
//            return nil
//        }
//
//        guard let image = UIImage(contentsOfFile: fileSystemURL.path) else {
//            return nil
//        }
//
//        return image
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
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            print("Image \(fileSystemURL.lastPathComponent) not saved to file system")
        }
    }
    
    lazy var fetch:Fetch<UIImage>? = { [weak self] in // THIS IS VITAL TO PREVENT A MEMORY LEAK
        guard let imageName = imageName else {
            return nil
        }
        
        let fetch = Fetch<UIImage>(name:imageName)
        
        fetch.store = { (image:UIImage?) in
            self?.storeIt(image: image)
        }
        
        fetch.retrieve = {
            return self?.retrieveIt()
        }
        
        fetch.fetch = {
            return self?.fetchIt()
        }
        
        return fetch
    }()
}

class FetchCachedImage : FetchImage
{
    private static var cache : ThreadSafeDictionary<UIImage>! = {
        return ThreadSafeDictionary<UIImage>(name:"FetchImageCache")
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
            return FetchCachedImage.cache[self.imageName]
        }
        set {
            FetchCachedImage.cache[self.imageName] = newValue
        }
    }
}

