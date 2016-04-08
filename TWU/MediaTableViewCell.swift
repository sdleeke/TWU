//
//  MediaTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MediaTableViewCell: UITableViewCell {
    
    var row:Int?
    
    var sermon:Sermon? {
        didSet {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: oldValue)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: sermon)
            
            updateUI()
        }
    }
    
    var downloadObserver:NSTimer?
    
    var vc:UIViewController?
    
    func updateUI()
    {
//        print("updateUI: \(sermon!.series!.title) \(sermon!.id)")
        
//        selected = (globals.seriesPlaying == sermon!.series) && ((globals.seriesPlaying!.startingIndex + globals.player.playingIndex) == sermon!.id)
//        print("\(selected)")
     
        if (sermon?.series?.numberOfSermons == 1) {
            title!.text = "\(sermon!.series!.title!)"
        }
        
        if (sermon?.series?.numberOfSermons > 1) {
            title!.text = "\(sermon!.series!.title!) (Part\u{00a0}\(row!+1))"
        }
        
        if (sermon == globals.player.playing) {
//            title!.text = title!.text! + " (active)"

//            if (globals.player.paused) {
//                title!.text = title!.text! + " (paused)"
//            } else {
//                title!.text = title!.text! + " (playing)"
//            }
        }
        
        switch sermon!.audioDownload.state {
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
            if (sermon!.audioDownload.totalBytesExpectedToWrite > 0) {
                downloadProgressBar.progress = Float(sermon!.audioDownload.totalBytesWritten) / Float(sermon!.audioDownload.totalBytesExpectedToWrite)
            } else {
                downloadProgressBar.progress = 0
            }
            break
        }
        downloadLabel.sizeToFit()

        downloadSwitch.on = sermon!.audioDownload.state != .none

        if (sermon!.audioDownload.active) && (downloadObserver == nil) {
            downloadObserver = NSTimer.scheduledTimerWithTimeInterval(Constants.DOWNLOAD_TIMER_INTERVAL, target: self, selector: #selector(MediaTableViewCell.updateUI), userInfo: nil, repeats: true)
        }

        if (downloadObserver != nil) &&
            (sermon!.audioDownload.totalBytesExpectedToWrite > 0) && (sermon!.audioDownload.totalBytesExpectedToWrite > 0) &&
            (sermon!.audioDownload.totalBytesWritten == sermon!.audioDownload.totalBytesExpectedToWrite) {
            downloadLabel.text = Constants.Downloaded
            downloadLabel.sizeToFit()
            downloadObserver?.invalidate()
            downloadObserver = nil
        }
    }
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var downloadSwitch: UISwitch!
    @IBAction func downloadSwitchAction(sender: UISwitch)
    {
        switch sender.on {
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            vc?.dismissViewControllerAnimated(true, completion: nil)
            
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            alert.modalPresentationStyle = UIModalPresentationStyle.Popover
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = downloadSwitch.frame
            
            vc?.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
