//
//  MediaCollectionViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MediaCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var seriesArt: UIImageView!

    var vc:MediaCollectionViewController?
    
    var series:Series? {
        didSet {
            updateUI()
        }
    }
    
    fileprivate func updateUI() {
        if (series != nil) {
            if (series == vc?.seriesSelected) {
//                seriesArt.layer.opacity = 0.5
//                seriesArt.layer.borderWidth = 4.0
//                seriesArt.layer.borderColor = UIColor.blackColor().CGColor
            } else {
//                seriesArt.layer.opacity = 1.0
//                seriesArt.layer.borderWidth = 0.0
//                seriesArt.layer.borderColor = nil
            }
            
//            print("\(series!.title)")
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
//                if let art = self.series?.getArt() {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        self.seriesArt.image = art
//                    }
//                }
//            }
            
            seriesArt.image = series?.getArt()
            
            //        println("\(size)")
            //        println("\(UIDevice.currentDevice().model)")
        }
    }
}
