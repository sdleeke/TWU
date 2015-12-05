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
//            print("\(series!.title)")
            let imageName = "\(Constants.COVER_ART_PREAMBLE)\(series!.name)\(Constants.COVER_ART_POSTAMBLE)"
            seriesArt.image = UIImage(named:imageName)

            //Slows everything way down.  If we were going to do something other than embed the images 
            //in the app resources we would cache them and have to check for changes and recache changed images.
//            let imageURL = Globals.baseImageURL + imageName + ".jpg"
//            print("\(imageURL)")
//            seriesArt.image = UIImage(data: NSData(contentsOfURL: NSURL(string: imageURL)!)!)
            
            //        println("\(size)")
            //        println("\(UIDevice.currentDevice().model)")
        }
    }
}
