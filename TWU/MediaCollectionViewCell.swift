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
    
    fileprivate func updateUI()
    {
        seriesArt.image = series?.getArt()
    }
}
