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
    
    var series:Series?
    {
        willSet {
            
        }
        didSet {
            if (series != oldValue) || (seriesArt.image == nil) {
                seriesArt.image = nil
                updateUI()
            }
        }
    }
    
    static var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = UUID().uuidString
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 3
        return operationQueue
    }()
    
    deinit {
        debug(self)
    }
    
    fileprivate func updateUI()
    {
        guard let series = self.series else {
            return
        }
        
        guard seriesArt.image == nil else {
            return
        }
        
        guard series.coverArt?.cache == nil else {
            self.seriesArt.image = series.coverArt?.cache
            self.activityIndicator.stopAnimating()
            return
        }
        
        Thread.onMainThread {
            self.activityIndicator.startAnimating()
        }

//        print(MediaCollectionViewCell.operationQueue.operationCount)
        
        MediaCollectionViewCell.operationQueue.addOperation {
            guard let image = series.coverArt?.image else {
                Thread.onMainThread {
                    if self.series == series {
                        self.activityIndicator.stopAnimating()
                        self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
                    } else {
                        
                    }
                }
                return
            }
            
            if self.series == series {
                Thread.onMainThread {
                    self.activityIndicator.stopAnimating()
                    self.seriesArt.image = image
                }
            } else {
                //                self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
            }
        }
    }
}
