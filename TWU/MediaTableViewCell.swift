//
//  MediaTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MediaTableViewCell: UITableViewCell
{
    var sermon:Sermon? {
        willSet {
            
        }
        didSet {
            Thread.onMainThread {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: oldValue)
                NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
            }
            
            updateUI()
        }
    }
    
    func updateUI()
    {
        guard Thread.isMainThread else {
            return
        }
        
        if sermon?.series?.numberOfSermons == 1, let title = sermon?.series?.title {
            self.title?.text = title
        }
        
        if (sermon?.series?.numberOfSermons > 1) {
            if  let range = sermon?.title?.range(of: "(Part "), let endIndex = sermon?.title?.endIndex,
                let text = sermon?.title?.replacingOccurrences(of: " ", with: "\u{00a0}", options: String.CompareOptions.caseInsensitive,
                                                               range: Range(uncheckedBounds: (lower: range.lowerBound, upper: endIndex))) {
                title?.text = text
            } else {
                title?.text = sermon?.title
            }
        }
        
        if let state = sermon?.audioDownload.state {
            switch state {
            case .none:
                downloadLabel.text = Constants.Download
                downloadProgressBar.progress = 0
                break
                
            case .downloaded:
                downloadLabel.text = Constants.Downloaded
                downloadProgressBar.progress = 1
                break
                
            case .downloading:
                downloadLabel.text = Constants.Downloading
                if  let totalBytesExpectedToWrite = sermon?.audioDownload.totalBytesExpectedToWrite, totalBytesExpectedToWrite > 0,
                    let totalBytesWritten = sermon?.audioDownload.totalBytesWritten {
                    downloadProgressBar.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                } else {
                    downloadProgressBar.progress = 0
                }
                break
            }
            
            downloadLabel.sizeToFit()

            downloadSwitch.isOn = state != .none
        } else {
            downloadSwitch.isOn = false
        }
    }
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var downloadSwitch: UISwitch!
    @IBAction func downloadSwitchAction(_ sender: UISwitch)
    {
        switch sender.isOn {
        case true:
            //Download the audio file and use it in future playback.
            //The file should not already exist.
            sermon?.audioDownload.download()
            break
            
        case false:
            sermon?.audioDownload.cancelOrDeleteDownload()
            break
        }
    }
    
    @IBOutlet weak var downloadProgressBar: UIProgressView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
