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

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var vc:MediaCollectionViewController?
    
    var series:Series? {
        willSet {
            
        }
        didSet {
            if series != oldValue {
                updateUI()
            }
        }
    }
    
    fileprivate func updateUI()
    {
        if let series = self.series {
            if let image = series.loadArt() {
                seriesArt.image = image
            } else {
                activityIndicator.startAnimating()
                DispatchQueue.global(qos: .background).async { () -> Void in
                    if let image = series.fetchArt() {
                        if self.series == series {
                            DispatchQueue.main.async {
                                self.activityIndicator.stopAnimating()
                                self.seriesArt.image = image
                            }
                        }
                    }
                }
            }
        }
    }
}
