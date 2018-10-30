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
    
    init(url:URL?)
    {
        self.url = url
    }
    
    // Why isn't this a var?  Would we pass parameters?
    func fetchIt() -> UIImage?
    {
        guard let image = self.url?.image else {
            return nil
        }

        // better handled in url image extension
//        if let fileSystemURL = url?.fileSystemURL, !fileSystemURL.downloaded {
//            do {
//                try UIImageJPEGRepresentation(image, 1.0)?.write(to: fileSystemURL, options: [.atomic])
//                print("Image \(fileSystemURL.lastPathComponent) saved to file system")
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                print("Image \(fileSystemURL.lastPathComponent) not saved to file system")
//            }
//        }
        
        return image
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
    
    lazy var fetch:Fetch<UIImage>? = {
        guard let imageName = imageName else {
            return nil
        }
        
        let fetch = Fetch<UIImage>(name:imageName)
        
        fetch.fetch = {
            return self.fetchIt()
        }
        
        return fetch
    }()
}

class FetchCachedImage : FetchImage
{
    private static var cache : ThreadSafeDictionary<UIImage>! = {
        return ThreadSafeDictionary<UIImage>(name:"FetchImageCache")
    }()
    
    override func fetchIt() -> UIImage?
    {
        if let image = self.cachedImage {
            return image
        }
        
        let image = super.fetchIt()
                
        self.cachedImage = image
        
        return image
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

