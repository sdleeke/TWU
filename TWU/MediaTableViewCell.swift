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
        willSet {
            
        }
        didSet {
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: oldValue)
                NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_UI), object: self.sermon)
            })
            
            updateUI()
        }
    }
    
//    var downloadObserver:Timer?
    
    var vc:UIViewController?
    
    func updateUI()
    {
        guard Thread.isMainThread else {
            return
        }
        
//        print("updateUI: \(sermon!.series!.title) \(sermon!.id)")
        
//        selected = (globals.seriesPlaying == sermon!.series) && ((globals.seriesPlaying!.startingIndex + globals.player.playingIndex) == sermon!.id)
//        print("\(selected)")
     
        if (sermon?.series?.numberOfSermons == 1) {
            title!.text = "\(sermon!.series!.title!)"
        }
        
        if (sermon?.series?.numberOfSermons > 1) {
            title!.text = "\(sermon!.series!.title!) (Part\u{00a0}\(row!+1))"
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

        downloadSwitch.isOn = sermon!.audioDownload.state != .none

//        if (sermon!.audioDownload.active) && (downloadObserver == nil) {
//            downloadObserver = Timer.scheduledTimer(timeInterval: Constants.INTERVAL.DOWNLOAD_TIMER, target: self, selector: #selector(MediaTableViewCell.updateUI), userInfo: nil, repeats: true)
//        }
//
//        if (downloadObserver != nil) &&
//            (sermon!.audioDownload.totalBytesExpectedToWrite > 0) && (sermon!.audioDownload.totalBytesExpectedToWrite > 0) &&
//            (sermon!.audioDownload.totalBytesWritten == sermon!.audioDownload.totalBytesExpectedToWrite) {
//            downloadLabel.text = Constants.Downloaded
//            downloadLabel.sizeToFit()
//            downloadObserver?.invalidate()
//            downloadObserver = nil
//        }
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    fileprivate func networkUnavailable(_ message:String?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            vc?.dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.actionSheet)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            alert.modalPresentationStyle = UIModalPresentationStyle.popover
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = downloadSwitch.frame
            
            vc?.present(alert, animated: true, completion: nil)
        }
    }
}
