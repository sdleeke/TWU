//
//  MediaCollectionViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MediaCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var seriesArt: UIImageView!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var series:Series? {
        willSet {
            
        }
        didSet {
            if (series != oldValue) || (seriesArt.image == nil) {
                seriesArt.image = nil
                operationQueue?.cancelAllOperations()
                updateUI()
            }
        }
    }
    
    var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = UUID().uuidString
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    fileprivate func updateUI()
    {
        guard let series = self.series else {
            return
        }
        
        guard seriesArt.image == nil else {
            return
        }
        
        if let coverArt = series.coverArt.fetch?.cache {
            Thread.onMainThread {
                self.seriesArt.image = coverArt
            }
        } else {
            Thread.onMainThread {
                self.activityIndicator.startAnimating()
            }
            
            operationQueue.addOperation {
                series.coverArt.block { (image:UIImage?) in
                    Thread.onMainThread {
                        if let image = image {
                            if self.series == series {
                                self.activityIndicator.stopAnimating()
                                self.seriesArt.image = image
                            }
                        } else {
                            self.activityIndicator.stopAnimating()
                            self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
                        }
                    }
                }
            }
        }
    }
}
