//
//  MyTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MyTableViewCell: UITableViewCell {
    
    var row:Int?
    
    var sermon:Sermon? {
        didSet {
            updateUI()
        }
    }
    
    var downloadObserver:NSTimer?
    
    func updateUI()
    {
//        print("updateUI: \(sermon!.series!.title) \(sermon!.id)")
        
//        selected = (Globals.seriesPlaying == sermon!.series) && ((Globals.seriesPlaying!.startingIndex + Globals.sermonPlayingIndex) == sermon!.id)
//        print("\(selected)")
     
        if (sermon?.series?.numberOfSermons == 1) {
            title!.text = "\(sermon!.series!.title)"
        }
        
        if (sermon?.series?.numberOfSermons > 1) {
            title!.text = "\(sermon!.series!.title) (Part\u{00a0}\(row!+1))"
        }
        
        if (sermon == Globals.sermonPlaying) {
//            title!.text = title!.text! + " (active)"

//            if (Globals.playerPaused) {
//                title!.text = title!.text! + " (paused)"
//            } else {
//                title!.text = title!.text! + " (playing)"
//            }
        }
        
        switch sermon!.download.state {
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
            if (sermon!.download.totalBytesExpectedToWrite > 0) {
                downloadProgressBar.progress = Float(sermon!.download.totalBytesWritten) / Float(sermon!.download.totalBytesExpectedToWrite)
            } else {
                downloadProgressBar.progress = 0
            }
            break
        }
        downloadLabel.sizeToFit()

        downloadSwitch.on = sermon!.download.state != .none

        if (sermon!.download.active) && (downloadObserver == nil) {
            downloadObserver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateUI", userInfo: nil, repeats: true)
        }

        if (downloadObserver != nil) &&
            (sermon!.download.totalBytesExpectedToWrite > 0) && (sermon!.download.totalBytesExpectedToWrite > 0) &&
            (sermon!.download.totalBytesWritten == sermon!.download.totalBytesExpectedToWrite) {
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
            downloadAudio()
            break
        case false:
            deleteDownload()
            break
        }
    }
    
    func deleteDownload()
    {
        sermon?.deleteDownload()
        updateUI()
    }
    
    func cancelDownload()
    {
        sermon?.deleteDownload()
        updateUI()
    }
    
    func downloadAudio()
    {
        sermon!.downloadAudio()
        downloadObserver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateUI", userInfo: nil, repeats: true)
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
}
