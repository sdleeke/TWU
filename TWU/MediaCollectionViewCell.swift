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
    
//    var vc:MediaCollectionViewController?
    
    var series:Series? {
        willSet {
            
        }
        didSet {
            if series != oldValue {
                seriesArt.image = nil
                updateUI()
            }
        }
    }
    
    fileprivate func updateUI()
    {
        guard let series = self.series else {
            return
        }
        
//        guard let name = series.coverArtURL?.lastPathComponent else {
//            return
//        }

        self.activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInteractive).async { () -> Void in
            series.coverArt.block { (image:UIImage?) in
                Thread.onMainThread {
                    self.activityIndicator.stopAnimating()
                    
                    if let image = image {
                        if self.series == series {
//                            Globals.shared.series.images[name] = image
                            self.seriesArt.image = image
                        }
                    } else {
                        self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
                    }
                }
            }
        }
        
//        if let image = Globals.shared.series.images[name] {
//            self.seriesArt.image = image
//        } else {
//            self.activityIndicator.startAnimating()
//
//            DispatchQueue.global(qos: .userInteractive).async { () -> Void in
//                series.coverArt { (image:UIImage?) in
//                    Thread.onMainThread {
//                        self.activityIndicator.stopAnimating()
//
//                        if let image = image {
//                            if self.series == series {
//                                Globals.shared.series.images[name] = image
//                                self.seriesArt.image = image
//                            }
//                        } else {
//                            self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
//                        }
//                    }
//                }
//            }
//        }
        
//            DispatchQueue.global(qos: .userInteractive).async { () -> Void in
//                series.coverArt { (image:UIImage?) in
//                    Thread.onMainThread {
//                        self.activityIndicator.stopAnimating()
//
//                        if let image = image {
//                            if self.series == series {
//                                self.seriesArt.image = image
//                            }
//                        } else {
//                            self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
//                        }
//                    }
//                }
////                if let image = series.coverArt {
////                    Thread.onMainThread {
////                        self.activityIndicator.stopAnimating()
////                        if self.series == series {
////                            self.seriesArt.image = image
////                        }
////                    }
////                } else {
////                    Thread.onMainThread {
////                        self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
////                    }
////                }
//            }
            
//            if let image = series.loadArt() {
//                self.seriesArt.image = image
//            } else {
//                self.activityIndicator.startAnimating()
//
//                DispatchQueue.global(qos: .userInteractive).async { () -> Void in
//                    if let image = series.fetchArt() {
//                        Thread.onMainThread {
//                            self.activityIndicator.stopAnimating()
//                            if self.series == series {
//                                self.seriesArt.image = image
//                            }
//                        }
//                    } else {
//                        Thread.onMainThread {
//                            self.seriesArt.image = UIImage(named: "twu_logo_circle_r")
//                        }
//                    }
//                }
//            }
//        }
    }
}
