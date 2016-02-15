//
//  MyCollectionViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MyCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var seriesArt: UIImageView!

    var series:Series? {
        didSet {
            updateUI()
        }
    }
    
    private func updateUI() {
        if (series != nil) {
            if (series == Globals.seriesSelected) {
//                seriesArt.layer.opacity = 0.5
//                seriesArt.layer.borderWidth = 4.0
//                seriesArt.layer.borderColor = UIColor.blackColor().CGColor
            } else {
//                seriesArt.layer.opacity = 1.0
//                seriesArt.layer.borderWidth = 0.0
//                seriesArt.layer.borderColor = nil
            }
            
//            print("\(series!.title)")
            seriesArt.image = series?.getArt()
            //        println("\(size)")
            //        println("\(UIDevice.currentDevice().model)")
        }
    }
}
