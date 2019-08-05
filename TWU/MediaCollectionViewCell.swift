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
            seriesArt.image = nil
            updateUI()

//            if (series != oldValue) || (seriesArt.image == nil) {
//                seriesArt.image = nil
//                updateUI()
//            }
        }
    }
    
    var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = UUID().uuidString
        operationQueue.qualityOfService = .userInteractive
//        operationQueue.maxConcurrentOperationCount = 3
        return operationQueue
    }()
    
    deinit {
        debug(self)
    }
    
    @IBOutlet weak var layoutAspectRatio: NSLayoutConstraint!
    
    func setImage(_ image:UIImage?)
    {
        guard let image = image else {
            return
        }
        
        Thread.onMain { [weak self] in
            let ratio = image.size.width / image.size.height
            
            self?.layoutAspectRatio = self?.layoutAspectRatio.setMultiplier(multiplier: ratio)

            self?.seriesArt.image = image

            self?.activityIndicator.isHidden = true
            self?.activityIndicator.stopAnimating()
        }
    }

    fileprivate func updateUI()
    {
        //        print("MediaCollectionViewCell.operationQueue.operationCount: ",MediaCollectionViewCell.operationQueue.operationCount)
        
        // TOTAL DISASTER when used with a static opQueue NO IDEA WHY, WRONG IMAGE SHOWS UP
//        guard series?.coverArt?.cache == nil else {
//            self.seriesArt.image = series?.coverArt?.cache
//            return
//        }
        
        guard let series = self.series else {
            return
        }
        
        guard seriesArt.image == nil else {
            return
        }
        
        Thread.onMain { [weak self] in
            self?.activityIndicator.startAnimating()
        }
        
        operationQueue.addOperation {
//            // Check to see if it is downlaoded before downloading.
//            guard series.coverArt?.retrieveIt() == nil else {
//                series.coverArt?.cache = series.coverArt?.retrieveIt()
//                Thread.onMain { [weak self] in
//                    self.seriesArt.image = series.coverArt?.cache
//                    self.activityIndicator.stopAnimating()
//                }
//                return
//            }
//
//            // The problem with this on a slow network is that it starts all possible downloads at once.
//            // Because the operations clear quick since all that happens is that a download is started.
//            series.coverArt?.downloadIt() {
                guard let image = series.coverArt?.image else {
                    Thread.onMain { [weak self] in
                        if self?.series == series {
//                            self?.activityIndicator.stopAnimating()
                            // .replacingOccurrences(of: "square", with: "").replacingOccurrences(of: "_Md", with: "_md")
                            self?.setImage(series.coverArt?.url?.image ?? UIImage(named: "twu_logo_circle_r"))
//                            self?.seriesArt.image = UIImage(named: "twu_logo_circle_r")
                        } else {

                        }
                    }
                    return
                }

                Thread.onMain { [weak self] in
                    if self?.series == series {
//                        self?.activityIndicator.stopAnimating()
                        self?.setImage(image)
//                        self?.seriesArt.image = image
                    } else {
                        //                self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
                    }
                }
//            }
        }
    }
}
