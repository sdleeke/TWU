//
//  FetchedImage.swift
//  TWU
//
//  Created by Steve Leeke on 10/5/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class FetchedImage
{
    var url : URL?
    
    init(url:URL?)
    {
        self.url = url
    }
    
    func block(_ block:((UIImage?)->()))
    {
        if let image = image {
            block(image)
        }
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
    
    private lazy var fetch : Fetch<UIImage>? = {
        if let url = url {
            let fetch = Fetch<UIImage>(name:url.lastPathComponent) //
            fetch.fetch = {
                return self.url?.image
            }
            return fetch
        }
        
        return nil
    }()
}

