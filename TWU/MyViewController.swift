//
//  MyViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/31/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MessageUI
import MediaPlayer
import Social


class MyViewController: UIViewController, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBAction func pageControlAction(sender: UIPageControl)
    {
        flip(self)
    }
    
    var seriesSelected:Series?
//        {
//        didSet {
//            if (seriesSelected != nil) {
////                print("\(seriesSelected)")
//                // We can only set, not unset
////                Globals.seriesSelected = seriesSelected // Set to nil means key removed means not in defaults any longer (this is done in Globals)
//                let defaults = NSUserDefaults.standardUserDefaults()
//                defaults.setObject("\(seriesSelected!.id)", forKey: Constants.SERIES_SELECTED)
//                defaults.synchronize()
//
//                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
//            } else {
//                print("MyViewController:seriesSelected nil")
//            }
//        }
//    }
    
    var sermonSelected:Sermon? {
        didSet {
            seriesSelected?.sermonSelected = sermonSelected

            if (sermonSelected != nil) {
//                print("\(sermonSelected)")
                // We can only set, not unset
//                Globals.sermonSelected = sermonSelected // Set to nil means key removed means not in defaults any longer (this is done in Globals)

//                let defaults = NSUserDefaults.standardUserDefaults()
//                defaults.setObject("\(sermonSelected!.index)", forKey: Constants.SERMON_SELECTED_INDEX)
//                defaults.synchronize()

                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
            } else {
                print("MyViewController:sermonSelected nil")
            }
        }
    }
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBAction func playPause(sender: UIButton) {
        if (Globals.sermonPlaying != nil) && (Globals.sermonPlaying == sermonSelected) && (Globals.mpPlayer != nil) {
            switch Globals.mpPlayer!.playbackState {
            case .SeekingBackward:
                print("playPause.SeekingBackward")
                fallthrough
                
            case .SeekingForward:
                print("playPause.SeekingForward")
                fallthrough
                
            case .Playing:
                print("playPause.Playing")
                
//                removePlayObserver()
                
                Globals.mpPlayer?.pause()
                Globals.playerPaused = true
                updateCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
                setupPlayPauseButton()
                break
                
            case .Stopped:
                print("playPause.Stopped")
                fallthrough
                
            case .Interrupted:
                print("playPause.Interrupted")
                fallthrough
                
            case .Paused:
                print("playPause.Paused")
                
                let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
                let loadvalue:UInt8 = UInt8(MPMovieLoadState.Playable.rawValue)
                
                let playable = (loadstate & loadvalue) == loadvalue

//                print("\(loadstate)")
//                print("\(loadvalue)")
                
                if (playable) {
                    print("playPause.MPMovieLoadState.Playable")
                    Globals.playerPaused = false
                    
                    if (Globals.mpPlayer!.contentURL == sermonSelected?.playingURL) {
                        //                    print("\(selectedSermon!.currentTime!)")
                        //                    print("\(NSTimeInterval(Float(selectedSermon!.currentTime!)!))")
                        if sermonSelected!.hasCurrentTime() {
                            //Make the comparision an Int to avoid missing minor differences
                            if (Globals.mpPlayer!.duration >= 0) && (Int(Float(Globals.mpPlayer!.duration)) == Int(Float(sermonSelected!.currentTime!)!)) {
                                Globals.sermonPlaying!.currentTime = Constants.ZERO
                                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                            }
                            if (Globals.mpPlayer!.currentPlaybackTime >= 0) && (Int(Globals.mpPlayer!.currentPlaybackTime) != Int(Float(sermonSelected!.currentTime!)!)) {
                                print("currentPlayBackTime: \(Globals.mpPlayer!.currentPlaybackTime) != currentTime: \(sermonSelected!.currentTime!)")
                            }
                        } else {
                            Globals.sermonPlaying!.currentTime = Constants.ZERO
                            Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                        }
                        
                        if (Globals.mpPlayer?.currentPlaybackTime == 0) {
                            print("Globals.mpPlayer?.currentPlaybackTime == 0!")
                        }
                        
                        spinner.stopAnimating()
                        spinner.hidden = true
                        
                        Globals.mpPlayer?.play()
                        
                        setupPlayingInfoCenter()
                        setupPlayPauseButton()
                    } else {
                        playNewSermon(sermonSelected)
                    }
                } else {
                    print("playPause.MPMovieLoadState.Playthrough NOT OK")
                    if (Globals.playerPaused) {
                        playNewSermon(sermonSelected)
                    } else {
                        Globals.playerPaused = true
                        spinner.stopAnimating()
                        spinner.hidden = true
                        setupPlayPauseButton()
                    }
                }
                break
            }
        } else {
            playNewSermon(sermonSelected)
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.sermonPlaying != nil) {
                if (Globals.playerPaused) {
                    Globals.mpPlayer?.play()
                } else {
                    Globals.mpPlayer?.pause()
                    updateCurrentTimeExact()
                }
                Globals.playerPaused = !Globals.playerPaused
                
                if (sermonSelected == Globals.sermonPlaying) {
                    setupPlayPauseButton()
                }
            } else {
                if (sermonSelected != nil) {
                    playNewSermon(sermonSelected)
                }
            }
        }
    }

    func setupPlayPauseButton()
    {
        if (sermonSelected != nil) {
            if (sermonSelected == Globals.sermonPlaying) {
                playPauseButton.enabled = Globals.sermonLoaded
                
                if (Globals.playerPaused) {
                    playPauseButton.setTitle(Constants.FA_PLAY, forState: UIControlState.Normal)
                } else {
                    playPauseButton.setTitle(Constants.FA_PAUSE, forState: UIControlState.Normal)
                }
            } else {
                playPauseButton.enabled = true
                playPauseButton.setTitle(Constants.FA_PLAY, forState: UIControlState.Normal)
            }

            playPauseButton.hidden = false
        } else {
            playPauseButton.enabled = false
            playPauseButton.hidden = true
        }
    }
    
    
    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var remaining: UILabel!
    
    @IBOutlet weak var seriesArtAndDescription: UIView!
    
    @IBOutlet weak var seriesArt: UIImageView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: "flip:")
            seriesArt.addGestureRecognizer(tap)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: "flipFromLeft:")
            swipeRight.direction = UISwipeGestureRecognizerDirection.Right
            seriesArt.addGestureRecognizer(swipeRight)
            
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: "flipFromRight:")
            swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
            seriesArt.addGestureRecognizer(swipeLeft)
        }
    }
    
    @IBOutlet weak var seriesDescription: UITextView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: "flip:")
            seriesDescription.addGestureRecognizer(tap)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: "flipFromLeft:")
            swipeRight.direction = UISwipeGestureRecognizerDirection.Right
            seriesDescription.addGestureRecognizer(swipeRight)
            
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: "flipFromRight:")
            swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
            seriesDescription.addGestureRecognizer(swipeLeft)
            
            seriesDescription.text = seriesSelected?.text
            seriesDescription.alwaysBounceVertical = true
            seriesDescription.selectable = false
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var slider: OBSlider!
    
    private func adjustAudioAfterUserMovedSlider()
    {
//        if (Globals.mpPlayer == nil) {
//            setupPlayer()
//        }
        
        if (Globals.mpPlayer != nil) {
            if (slider.value < 1.0) {
                let length = Float(Globals.mpPlayer!.duration)
                let seekToTime = slider.value * Float(length)
                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(seekToTime)
                Globals.sermonPlaying?.currentTime = seekToTime.description
                
//                if (Globals.playerPaused) {
//                    Globals.mpPlayer?.pause()
//                } else {
//                    Globals.mpPlayer?.play()
//                }
            } else {
                Globals.mpPlayer?.pause()
                Globals.playerPaused = true

                Globals.mpPlayer?.currentPlaybackTime = Globals.mpPlayer!.duration
                Globals.sermonPlaying?.currentTime = Globals.mpPlayer!.duration.description
            }
            
            setupPlayPauseButton()
            addSliderObserver()
        }
    }
    
    @IBAction func sliderTouchDown(sender: UISlider) {
        //        println("sliderTouchDown")
        removeSliderObserver()

//        if (Globals.mpPlayer == nil) {
//            setupPlayer()
//        }
    }
    
    @IBAction func sliderTouchUpOutside(sender: UISlider) {
        //        println("sliderTouchUpOutside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderTouchUpInside(sender: UISlider) {
        //        println("sliderTouchUpInside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderValueChanging(sender: UISlider) {
        setTimeToSlider()
    }
    
    var views : (seriesArt: UIView!, seriesDescription: UIView!)

//    var sliderObserver: NSTimer?
//    var playObserver: NSTimer?

    var actionButton:UIBarButtonItem?
    
    private func showSendMessageErrorAlert() {
        let sendMessageErrorAlert = UIAlertView(title: "Could Not Send a Message", message: "Your device could not send a text message.  Please check your configuration and try again.", delegate: self, cancelButtonTitle: Constants.Okay)
        sendMessageErrorAlert.show()
    }
    
    // MARK: MFMessageComposeViewControllerDelegate Method
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func message()
    {
        
        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self // Extremely important to set the --messageComposeDelegate-- property, NOT the --delegate-- property
        
        messageComposeViewController.recipients = []
        messageComposeViewController.subject = Constants.Email_Subject
        messageComposeViewController.body = setupBody()
        
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(messageComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    private func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check your e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func setupBody() -> String {
        var bodyString = String()
        
        bodyString = "I've enjoyed the sermon series \""
        bodyString = bodyString + seriesSelected!.title!
        bodyString = bodyString + "\" by Tom Pennington and thought you would enjoy it as well."
        bodyString = bodyString + "\n\nThis series of sermons is available at "
        bodyString = bodyString + seriesSelected!.url!.absoluteString
        
        return bodyString
    }
    
    private func setupBodyHTML(series:Series?) -> String? {
        var bodyString:String!
        
        if (series?.url != nil) && (series?.title != nil) {
            bodyString = "I've enjoyed the sermon series "
            bodyString = bodyString + "<a href=\"" + series!.url!.absoluteString + "\">" + series!.title! + "</a>"
            bodyString = bodyString + " by " + "Tom Pennington"
            bodyString = bodyString + " from <a href=\"http://www.thewordunleashed.org\">" + "The Word Unleashed" + "</a>"
            bodyString = bodyString + " and thought you would enjoy it as well."
            bodyString = bodyString + "</br>"
        }
        
        return bodyString
    }
    
    private func addressStringHTML() -> String
    {
        let addressString:String = "</br>Countryside Bible Church</br>250 Countryside Ct.</br>Southlake, TX 76092</br>(817) 488-5381</br><a href=\"mailto:cbcstaff@countrysidebible.org\">cbcstaff@countrysidebible.org</a></br>www.countrysidebible.org"
        
        return addressString
    }
    
    private func addressString() -> String
    {
        let addressString:String = "\n\nCountryside Bible Church\n250 Countryside Ct.\nSouthlake, TX 76092\nPhone: (817) 488-5381\nE-mail:cbcstaff@countrysidebible.org\nWeb: www.countrysidebible.org"
        
        return addressString
    }
    
    private func emailSeries(series:Series?)
    {
        let bodyString:String! = setupBodyHTML(series)
        
//        bodyString = bodyString + addressStringHTML()
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.Email_Subject)
        //        mailComposeViewController.setMessageBody(bodyString, isHTML: false)
        mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    private func openSeriesOnWeb(series:Series?)
    {
        if let url = series?.url {
            if UIApplication.sharedApplication().canOpenURL(url) {
                UIApplication.sharedApplication().openURL(url)
            } else {
                networkUnavailable("Unable to open url: \(url)")
            }
        }
    }
    
    private func openScripture(series:Series?)
    {
        if (series?.scripture != nil) {
            var urlString = Constants.SCRIPTURE_URL_PREFIX + series!.scripture! + Constants.SCRIPTURE_URL_POSTFIX
            
            urlString = urlString.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            //        println("\(urlString)")
            
            if let url = NSURL(string:urlString) {
                if UIApplication.sharedApplication().canOpenURL(url) {
                    UIApplication.sharedApplication().openURL(url)
                } else {
                    networkUnavailable("Unable to open url: \(url)")
                }
                //            if Reachability.isConnectedToNetwork() {
                //                if UIApplication.sharedApplication().canOpenURL(url) {
                //                    UIApplication.sharedApplication().openURL(url)
                //                } else {
                //                    networkUnavailable("Unable to open url: \(url)")
                //                }
                //            } else {
                //                networkUnavailable("Unable to connect to the internet to open: \(url)")
                //            }
            }
        }
    }
    
    func twitter()
    {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter){
            var bodyString = String()
            
            bodyString = "Great sermon series: \"\(seriesSelected!.title)\" by \(Constants.Tom_Pennington).  " + seriesSelected!.url!.absoluteString
            
            let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twitterSheet.setInitialText(bodyString)
            self.presentViewController(twitterSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
//        if Reachability.isConnectedToNetwork() {
//            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter){
//                var bodyString = String()
//                
//                bodyString = "Great sermon series: \"\(Globals.seriesSelected!.title)\" by \(Constants.Tom_Pennington).  " + Constants.BASE_WEB_URL + String(Globals.seriesSelected!.id)
//                
//                let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
//                twitterSheet.setInitialText(bodyString)
//                self.presentViewController(twitterSheet, animated: true, completion: nil)
//            } else {
//                let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
//                alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
//        } else {
//            networkUnavailable("Unable to connect to the internet to tweet.")
//        }
    }
    
    func facebook()
    {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
            var bodyString = String()
            
            bodyString = "Great sermon series: \"\(seriesSelected!.title)\" by \(Constants.Tom_Pennington).  " + seriesSelected!.url!.absoluteString
            
            //So the user can paste the initialText into the post dialog/view
            //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
            UIPasteboard.generalPasteboard().string = bodyString
            
            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            facebookSheet.setInitialText(bodyString)
            self.presentViewController(facebookSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
//        if Reachability.isConnectedToNetwork() {
//            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
//                var bodyString = String()
//                
//                bodyString = "Great sermon series: \"\(Globals.seriesSelected!.title)\" by \(Constants.Tom_Pennington).  " + Constants.BASE_WEB_URL + String(Globals.seriesSelected!.id)
//                
//                //So the user can paste the initialText into the post dialog/view
//                //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
//                UIPasteboard.generalPasteboard().string = bodyString
//
//                let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
//                facebookSheet.setInitialText(bodyString)
//                self.presentViewController(facebookSheet, animated: true, completion: nil)
//            } else {
//                let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
//                alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
//        } else {
//            networkUnavailable("Unable to connect to the internet to post to Facebook.")
//        }
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func rowClickedAtIndex(index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismissViewControllerAnimated(true, completion: nil)
        
        switch purpose {
            
        case .selectingAction:
            switch strings[index] {
            case Constants.Open_Scripture:
                openScripture(seriesSelected)
                break
                
            case Constants.Open_Series:
                openSeriesOnWeb(seriesSelected)
                break
                
            case Constants.Download_All:
                if (seriesSelected?.sermons != nil) {
                    for sermon in seriesSelected!.sermons! {
                        sermon.audioDownload?.download()
                    }
                }
                //                tableView.reloadData()
                //                scrollToSermon(selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                break
                
            case Constants.Cancel_All_Downloads:
                if (seriesSelected?.sermons != nil) {
                    for sermon in seriesSelected!.sermons! {
                        sermon.audioDownload?.cancelDownload()
                    }
                }
                //                tableView.reloadData()
                //                scrollToSermon(selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                break
                
            case Constants.Delete_All_Downloads:
                if (seriesSelected?.sermons != nil) {
                    for sermon in seriesSelected!.sermons! {
                        sermon.audioDownload?.deleteDownload()
                    }
                }
                //                tableView.reloadData()
                //                scrollToSermon(selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                break
                
            case Constants.Email_Series:
                emailSeries(seriesSelected)
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    func actions()
    {
        //        println("action!")
        
        // Put up an action sheet
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = actionButton
                
                //                popover.navigationItem.title = "Show"
                
                popover.navigationController?.navigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                if ((seriesSelected?.scripture != nil) && (seriesSelected?.scripture != "") && (seriesSelected?.scripture != Constants.Selected_Scriptures)) {
                    actionMenu.append(Constants.Open_Scripture)
                }

                actionMenu.append(Constants.Open_Series)
                
                if (seriesSelected?.sermons != nil) {
                    var sermonsToDownload = 0
                    var sermonsDownloading = 0
                    var sermonsDownloaded = 0
                    
                    for sermon in seriesSelected!.sermons! {
                        switch sermon.audioDownload!.state {
                        case .none:
                            sermonsToDownload++
                            break
                        case .downloading:
                            sermonsDownloading++
                            break
                        case .downloaded:
                            sermonsDownloaded++
                            break
                        }
                    }
                    
                    if (sermonsToDownload > 0) {
                        actionMenu.append(Constants.Download_All)
                    }
                    
                    if (sermonsDownloading > 0) {
                        actionMenu.append(Constants.Cancel_All_Downloads)
                    }
                    
                    if (sermonsDownloaded > 0) {
                        actionMenu.append(Constants.Delete_All_Downloads)
                    }
                }
                
                actionMenu.append(Constants.Email_Series)
                
                popover.strings = actionMenu
                
                popover.showIndex = false //(Globals.grouping == .series)
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }

//        let alert = UIAlertController(title: "",
//            message: "",
//            preferredStyle: UIAlertControllerStyle.ActionSheet)
//        
//        var action : UIAlertAction
//        
//        if ((seriesSelected?.scripture != nil) && (seriesSelected?.scripture != "") && (seriesSelected?.scripture != Constants.Selected_Scriptures)) {
//            action = UIAlertAction(title: Constants.Open_Scripture, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                self.openScripture()
//            })
//            alert.addAction(action)
//        }
//        
//        action = UIAlertAction(title: "Open Series on TWU Web Site", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//            self.openSeriesOnWeb(self.seriesSelected)
//        })
//        alert.addAction(action)
//
//        action = UIAlertAction(title: Constants.EMail_Series, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//            //            println("mail!")
//            self.mail()
//        })
//        alert.addAction(action)
//     
//        var sermonsToDownload = 0
//        var sermonsDownloaded = 0
//        var sermonsDownloading = 0
//        
//        for sermon in seriesSelected!.sermons! {
//            switch sermon.audioDownload.state {
//            case .none:
//                sermonsToDownload++
//                break
//                
//            case .downloading:
//                sermonsDownloading++
//                break
//                
//            case .downloaded:
//                sermonsDownloaded++
//                break
//            }
//        }
//
//        if (sermonsToDownload > 0) {
//            action = UIAlertAction(title: Constants.Download_All, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                if let sermons = self.seriesSelected?.sermons {
//                    for sermon in sermons {
//                        sermon.audioDownload.download()
//                    }
//                }
////                self.tableView.reloadData()
////                self.selectSermon(Globals.sermonPlaying)
//            })
//            alert.addAction(action)
//        }
//        
//        if (sermonsDownloading > 0) {
//            action = UIAlertAction(title: Constants.Cancel_All_Downloads, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            println("mail!")
//                for i in 0..<self.seriesSelected!.sermons!.count {
//                    self.seriesSelected?.sermons?[i].audioDownload.cancelDownload()
//                }
//                //                self.tableView.reloadData()
//                //                self.selectSermon(Globals.sermonPlaying)
//            })
//            alert.addAction(action)
//        }
//        
//        if (sermonsDownloaded > 0) {
//            action = UIAlertAction(title: Constants.Delete_All_Downloads, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            println("mail!")
//                for i in 0..<self.seriesSelected!.numberOfSermons {
//                    self.seriesSelected?.sermons?[i].audioDownload.deleteDownload()
//                }
////                self.tableView.reloadData()
////                self.selectSermon(Globals.sermonPlaying)
//            })
//            alert.addAction(action)
//        }
        
//        if (splitViewController == nil) {
//            action = UIAlertAction(title: Constants.Share_on_Facebook, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            println("mail!")
//                self.facebook()
//            })
//            alert.addAction(action)
//            
//            action = UIAlertAction(title: Constants.Share_on_Twitter, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            println("mail!")
//                self.twitter()
//            })
//            alert.addAction(action)
//        }
        
        //        action = UIAlertAction(title: "Message", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
        ////            println("message!")
        //            self.message()
        //        })
        //        alert.addAction(action)
        //
        //        action = UIAlertAction(title: "Print", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
        //            println("print!")
        //        })
        //        alert.addAction(action)
        //
//        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
////            println("cancel!")
//        })
//        alert.addAction(action)
//        
//        //on iPad this is a popover
//        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
//        alert.popoverPresentationController?.barButtonItem = actionButton
//        
//        presentViewController(alert, animated: true, completion: nil)
    }
    
    func applicationWillResignActive(notification:NSNotification)
    {
        setupPlayingInfoCenter()
//        removePlayObserver()
//        removeSliderObserver()
    }
    
    func applicationWillEnterForeground(notification:NSNotification)
    {
        if (Globals.mpPlayer?.currentPlaybackRate == 0) {
            //It is paused, possibly not by us, but by the system
            //But how do we know it hasn't simply finished playing?
            updateCurrentTimeExact()
            Globals.playerPaused = true
        } else {
            Globals.playerPaused = false
        }
        
//        addPlayObserver()
//        addSliderObserver()
        setupPlayPauseButton()
    }

    func updateView()
    {
        seriesSelected = Globals.seriesSelected
        sermonSelected = seriesSelected?.sermonSelected
        
//        sermonSelected = Globals.sermonSelected
        
        //        print(seriesSelected)
        //        print(sermonSelected)
        
        tableView.reloadData()
        selectSermon(sermonSelected)

        updateUI()
    }
    
    func clearView()
    {
        seriesSelected = nil
        sermonSelected = nil
        
        tableView.reloadData()
        
        updateUI()
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        navigationController?.toolbarHidden = true
        
        if (splitViewController != nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateView", name: Constants.UPDATE_VIEW_NOTIFICATION, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearView", name: Constants.CLEAR_VIEW_NOTIFICATION, object: nil)
        }

        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        
//        tableView.allowsSelection = true

        // Can't do this or selecting a row doesn't work reliably.
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                if let view = self.seriesArtAndDescription.subviews[1] as? UITextView {
                    //            view.scrollRectToVisible(CGRectMake(0, 0, 50, 50), animated: false)
                    view.scrollRangeToVisible(NSMakeRange(0, 0))
                }
                self.navigationController?.toolbarHidden = true
        }
    }
    
    private func setupActionsButton()
    {
        if (seriesSelected != nil) {
            actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "actions")
            self.navigationItem.rightBarButtonItem = actionButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
            actionButton = nil
        }
    }
    
    private func setupSlider()
    {
        if spinner.isAnimating() {
            spinner.stopAnimating()
            spinner.hidden = true
        }

        slider.enabled = Globals.sermonLoaded
        
        if (Globals.mpPlayer != nil) && (Globals.sermonPlaying != nil) {
            if (Globals.sermonPlaying == sermonSelected) {
                elapsed.hidden = false
                remaining.hidden = false
                slider.hidden = false
                
                setSliderAndTimesToAudio()
            } else {
                elapsed.hidden = true
                remaining.hidden = true
                slider.hidden = true
            }
        } else {
            elapsed.hidden = true
            remaining.hidden = true
            slider.hidden = true
        }
    }
    
    private func setupArtAndDescription()
    {
        if (seriesSelected != nil) {
            seriesArtAndDescription.hidden = false
            
            seriesArt.hidden = false
            seriesDescription.hidden = true
            
            pageControl.hidden = false
        } else {
            //iPad only
            seriesArtAndDescription.hidden = true
            pageControl.hidden = true
        }
    }
    
//    func updateCVC()
//    {
//        if (sermonSelected != nil) { // && (sermonSelected == Globals.sermonPlaying)
//            if let nvc = self.splitViewController?.viewControllers[0] as? UINavigationController {
//                if let mycvc = nvc.topViewController as? MyCollectionViewController {
//                    mycvc.setupPlayingPausedButton()
//                }
//            }
//        }
//    }
    
    private func setupTitle()
    {
        self.navigationItem.title = seriesSelected?.title
    }
    
    func setupPlayerAtEnd(sermon:Sermon?)
    {
        setupPlayer(sermon)
        
        if (Globals.mpPlayer != nil) {
            Globals.mpPlayer?.currentPlaybackTime = Globals.mpPlayer!.duration
            Globals.mpPlayer?.pause()
            
        }
    }
    
    func showUpdate(message message:String?,title:String?)
    {
        //        let application = UIApplication.sharedApplication()
        //        application.applicationIconBadgeNumber++
        //        let alert = UIAlertView(title: message, message: title, delegate: self, cancelButtonTitle: "OK")
        //        alert.show()
        
        UIApplication.sharedApplication().applicationIconBadgeNumber++
        let alert = UIAlertView(title: "Sermon Update Available", message: "Return to the series view to update.", delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    func sermonUpdateAvailable()
    {
        //        let application = UIApplication.sharedApplication()
        //        application.applicationIconBadgeNumber++
        //        let alert = UIAlertView(title: message, message: title, delegate: self, cancelButtonTitle: "OK")
        //        alert.show()
        
        let alert = UIAlertView(title: "Sermon Update Available", message: "Return to the series view to update.", delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    func updateUI()
    {
        //Done in sliderTimer()
//        if (Globals.sermonLoaded) { // || ((seriesSelected != nil) && (seriesSelected != Globals.sermonPlaying?.series))) {
//            spinner.stopAnimating()
//            spinner.hidden = true
//        }
        
        if (seriesSelected != nil) {
            logo.hidden = true
            seriesArt.image = seriesSelected?.getArt()
            seriesDescription.text = seriesSelected?.text
        } else {
            logo.hidden = false
            seriesArt.hidden = true
            seriesDescription.hidden = true
        }

        //Done in sliderTimer()
//        if (!Globals.sermonLoaded && (Globals.sermonPlaying != nil) && (sermonSelected == Globals.sermonPlaying)) {
//            spinner.startAnimating()
//        }
        
        //Done in sliderTimer()
//        if (Globals.sermonLoaded || (sermonSelected != Globals.sermonPlaying)) {
//            // Redundant - also done in viewDidLoad
//            spinner.stopAnimating()
//        }
        
        if (sermonSelected != nil) && (Globals.mpPlayer == nil) {
            setupPlayerAtEnd(sermonSelected)
        }

        addSliderObserver()
        
        setupActionsButton()
        setupArtAndDescription()
//        updateCVC()
        
        setupTitle()
        setupPlayPauseButton()
        setupSlider()
    }
    
    func scrollToSermon(sermon:Sermon?,select:Bool,position:UITableViewScrollPosition)
    {
        if (sermon != nil) {
            var indexPath = NSIndexPath(forRow: 0, inSection: 0)
            
            if (seriesSelected?.numberOfSermons > 1) {
                if let sermonIndex = seriesSelected?.sermons?.indexOf(sermon!) {
//                    print("\(sermonIndex)")
                    indexPath = NSIndexPath(forRow: sermonIndex, inSection: 0)
                }
            }
            
            //            print("\(tableView.bounds)")
            
            if (select) {
//                print(indexPath)
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: position)
            }
            
            //            print("Row: \(indexPath.row) Section: \(indexPath.section)")
            
            if (position == UITableViewScrollPosition.Top) {
                //                var point = CGPointZero //tableView.bounds.origin
                //                point.y += tableView.rowHeight * CGFloat(indexPath.row)
                //                tableView.setContentOffset(point, animated: true)
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: position, animated: true)
            } else {
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: position, animated: true)
            }
        } else {
            //No sermon to scroll to.
            
        }
    }

    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)

        //Unreliable
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        
        pageControl.enabled = true
        
        views = (seriesArt: self.seriesArt, seriesDescription: self.seriesDescription)
        
        if (seriesSelected == nil) { //  && (Globals.seriesSelected != nil)
            // Should only happen on an iPad on initial startup, i.e. when this view initially loads, not because of a segue.
            seriesSelected = Globals.seriesSelected

//            sermonSelected = Globals.sermonSelected?.series == Globals.seriesSelected ? Globals.sermonSelected : nil
        }
        
        sermonSelected = seriesSelected?.sermonSelected

        if (sermonSelected == nil) && (seriesSelected != nil) && (seriesSelected == Globals.sermonPlaying?.series) {
            sermonSelected = Globals.sermonPlaying
        }

//        tableView.reloadData()

        updateUI()
        
//        println("\(Globals.mpPlayer!.currentPlaybackTime)")
        
    }
    
    func selectSermon(sermon:Sermon?)
    {
        if (seriesSelected != nil) {
            setupPlayPauseButton()
            
//            print("\(seriesSelected!.title)")
            if (seriesSelected == sermon?.series) {
                if (sermon != nil) {
                    let indexPath = NSIndexPath(forItem: sermon!.index, inSection: 0)
                    //                    println("\(Globals.sermonPlayingIndex)")
                    tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
                }
            } else {
                
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if (UIApplication.sharedApplication().applicationIconBadgeNumber > 0) && ((splitViewController == nil) || (splitViewController!.viewControllers.count == 1)) {
            sermonUpdateAvailable()
        }
        
//        print("Series Selected: \(seriesSelected?.title) Playing: \(Globals.sermonPlaying?.series?.title)")
//        print("Sermon Selected: \(sermonSelected?.series?.title)")
        
        if (sermonSelected != nil) {
            if (sermonSelected == Globals.sermonPlaying) {
                setupSlider()  // calls addSliderObserver()
//                updateCVC()
//
//                if let nvc = self.splitViewController?.viewControllers[0] as? UINavigationController {
//                    if let mycvc = nvc.topViewController as? MyCollectionViewController {
//                        mycvc.setupPlayingPausedButton()
//                    }
//                }
            }
            
            //Have to wait until viewDidAppear to do the selection because the row heights aren't yet set in viewWillAppear
//            let indexPath = NSIndexPath(forItem: sermonSelected!.index, inSection: 0)
//            print("\(sermonSelected!.index)")
//            
//            tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Top)
//            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            scrollToSermon(sermonSelected,select:true,position:UITableViewScrollPosition.Middle)

//            var point = CGPointZero //tableView.bounds.origin
//            point.y += tableView.rowHeight * CGFloat(sermonSelected!.index)
//            tableView.setContentOffset(point, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
//        sermonSelected = nil
//        seriesSelected = nil
//        
//        removeSliderObserver()
//        removePlayObserver()
        
//        UIApplication.sharedApplication().endReceivingRemoteControlEvents()

//        NSNotificationCenter.defaultCenter().removeObserver(self,name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
//        NSNotificationCenter.defaultCenter().removeObserver(self,name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func flipFromLeft(sender: MyViewController) {
        //        println("tap")
        
        // set a transition style
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
        
        if let view = self.seriesArtAndDescription.subviews[0] as? UITextView {
            view.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(self.seriesArtAndDescription, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            let frontView = self.seriesArtAndDescription.subviews[0]
            let backView = self.seriesArtAndDescription.subviews[1]
            
            frontView.hidden = false
            self.seriesArtAndDescription.bringSubviewToFront(frontView)
            backView.hidden = true
            
            if frontView == self.seriesArt {
                self.pageControl.currentPage = 0
            }
            
            if frontView == self.seriesDescription {
                self.pageControl.currentPage = 1
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    func flipFromRight(sender: MyViewController) {
        //        println("tap")
        
        // set a transition style
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
        
        if let view = self.seriesArtAndDescription.subviews[0] as? UITextView {
            view.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(self.seriesArtAndDescription, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            let frontView = self.seriesArtAndDescription.subviews[0]
            let backView = self.seriesArtAndDescription.subviews[1]
            
            frontView.hidden = false
            self.seriesArtAndDescription.bringSubviewToFront(frontView)
            backView.hidden = true
            
            if frontView == self.seriesArt {
                self.pageControl.currentPage = 0
            }
            
            if frontView == self.seriesDescription {
                self.pageControl.currentPage = 1
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    func flip(sender: MyViewController) {
        //        println("tap")
        
        // set a transition style
        var transitionOptions:UIViewAnimationOptions!
        
        let frontView = self.seriesArtAndDescription.subviews[0]
        let backView = self.seriesArtAndDescription.subviews[1]
        
        if frontView == self.seriesArt {
            transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
        }
        
        if frontView == self.seriesDescription {
            transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
        }

        if let view = self.seriesArtAndDescription.subviews[0] as? UITextView {
            view.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(self.seriesArtAndDescription, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            frontView.hidden = false
            self.seriesArtAndDescription.bringSubviewToFront(frontView)
            backView.hidden = true
            
            if frontView == self.seriesArt {
                self.pageControl.currentPage = 0
            }
            
            if frontView == self.seriesDescription {
                self.pageControl.currentPage = 1
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destinationViewController as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
//        if let avpc = destination as? UIViewController? {
//            if let identifier = segue.identifier {
//                switch identifier {
//                case "Show Sermon":
//                    if let myCell = sender as? MyTableViewCell {
//                        let indexPath = seriesSermons!.indexPathForCell(myCell)
//
//                    }
//                    break
//                default:
//                    break
//                }
//            }
//        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if (seriesSelected != nil) {
            return seriesSelected!.show!
        } else {
            return 0
        }
    }
    
    /*
    */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SERMON_CELL_IDENTIFIER, forIndexPath: indexPath) as! MyTableViewCell
    
        // Configure the cell...
        cell.row = indexPath.row
        cell.sermon = seriesSelected?.sermons?[indexPath.row]
        cell.vc = self
        
        return cell
    }
    
    func tableView(tableView: UITableView, shouldSelectRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    private func addEndObserver() {
        if (Globals.mpPlayer != nil) && (Globals.sermonPlaying != nil) {

        }
    }
    
    private func setTimes(timeNow:Float, length:Float)
    {
        let elapsedHours = Int(timeNow / (60*60))
        let elapsedMins = Int((timeNow - (Float(elapsedHours) * 60*60)) / 60)
        let elapsedSec = Int(timeNow % 60)

        var elapsed:String
        
        if (elapsedHours > 0) {
            elapsed = "\(String(format: "%d",elapsedHours)):"
        } else {
            elapsed = Constants.EMPTY_STRING
        }
        
        elapsed = elapsed + "\(String(format: "%02d",elapsedMins)):\(String(format: "%02d",elapsedSec))"
        
        self.elapsed.text = elapsed
        
        let timeRemaining = length - timeNow
        let remainingHours = Int(timeRemaining / (60*60))
        let remainingMins = Int((timeRemaining - (Float(remainingHours) * 60*60)) / 60)
        let remainingSec = Int(timeRemaining % 60)
        
        var remaining:String
        
        if (remainingHours > 0) {
            remaining = "\(String(format: "%d",remainingHours)):"
        } else {
            remaining = Constants.EMPTY_STRING
        }
        
        remaining = remaining + "\(String(format: "%02d",remainingMins)):\(String(format: "%02d",remainingSec))"
        
        self.remaining.text = remaining
    }
    
    
    private func setSliderAndTimesToAudio() {
        if (Globals.mpPlayer != nil) {
            let length = Float(Globals.mpPlayer!.duration)
            
            //Crashes if currentPlaybackTime is not a number (NaN) or infinite!  I.e. when nothing has been playing.  This is only a problem on the iPad, I think.
            
            var timeNow:Float = 0.0
            
            if (Globals.mpPlayer!.currentPlaybackTime >= 0) && (Globals.mpPlayer!.currentPlaybackTime <= Globals.mpPlayer!.duration) {
                timeNow = Float(Globals.mpPlayer!.currentPlaybackTime)
            }
            
            let progress = timeNow / length
            
            self.slider.value = progress
            
            setTimes(timeNow,length: length)
        }
    }
    
    private func setTimeToSlider() {
        if (Globals.mpPlayer != nil) {
//            let length = Int64(CMTimeGetSeconds(Globals.player!.currentItem.asset.duration))
            let length = Float(Globals.mpPlayer!.duration)
            
            let timeNow = self.slider.value * length
            
            setTimes(timeNow,length: length)
        }
    }
    
    
//    func playTimer()
//    {
//        if (Globals.mpPlayer != nil) {
//            switch Globals.mpPlayer!.playbackState {
//            case .Interrupted:
//                print("playTimer.Interrupted")
//                Globals.playerPaused = true
//                updateCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
//                removePlayObserver()
//                break
//                
//            case .Paused:
//                print("playTimer.Paused")
//                if (!Globals.playerPaused) {
//                    networkUnavailable("The internet connection appears to be offline.")
//                    Globals.playerPaused = true
//                    setupPlayPauseButton()
//                }
//
//                //Not sure this is working to pick up network errors only.
//                
////                if (!Globals.playerPaused) {
////                    if (Int(Globals.mpPlayer!.currentPlaybackTime) < Int(Globals.mpPlayer!.duration)) {
////                        print("player paused when it should be playing")
////                        
////                        //Something happened.  We called this because we wanted the audio to play.
////                        //Can't say this since this is called on viewWillAppear to handle spinner
////                        
////                        //Alert - network unavailable.
////                        networkUnavailable()
////                    }
////                    
////                    updateCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
////                    
////                    //Don't stop and don't lose the time.
////                    //                Globals.mpPlayer?.stop()
////                    
////                    spinner.stopAnimating()
////                    spinner.hidden = true
////                    Globals.playerPaused = true
////                    setupPlayPauseButton()
////                    
////                    removePlayObserver()
////                }
//                break
//                
//            case .Playing:
//                print("playTimer.Playing")
//                if (Globals.playerPaused) {
//                    Globals.playerPaused = false
//                    setupPlayPauseButton()
//                }
//                //Don't do the following so we can determine if, after it starts playing, the player stops when it shouldn't
//                //removePlayObserver()
//                break
//                
//            case .SeekingBackward:
//                print("playTimer.SeekingBackward")
//                if (Globals.playerPaused) {
//                    Globals.playerPaused = false
//                    setupPlayPauseButton()
//                }
//                break
//                
//            case .SeekingForward:
//                print("playTimer.SeekingForward")
//                if (Globals.playerPaused) {
//                    Globals.playerPaused = false
//                    setupPlayPauseButton()
//                }
//                break
//                
//            case .Stopped:
//                print("playTimer.Stopped")
//                spinner.stopAnimating()
//                if (Globals.mpPlayer != nil) && (!Globals.playerPaused || !Globals.sermonLoaded)  {
//                    networkUnavailable("The internet connection appears to be offline.")
//                    Globals.sermonLoaded = true
//                    Globals.playerPaused = true
//                    setupPlayPauseButton()
//                }
//
//                //Not sure this is working to pick up network errors only.
//                
////                if (!Globals.playerPaused) && ((Globals.mpPlayer!.currentPlaybackTime >= 0) && (Globals.mpPlayer!.duration >= 0)) {
////                    if (Int(Globals.mpPlayer!.currentPlaybackTime) < Int(Globals.mpPlayer!.duration)) {
////                        print("player stopped when it should be playing")
////                        
////                        //Something happened.  We called this because we wanted the audio to play.
////                        //Can't say this since this is called on viewWillAppear to handle spinner
////                        
////                        //Alert - network unavailable.
////                        networkUnavailable()
////                    }
////                    
////                    updateCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
////                    
////                    Globals.mpPlayer?.stop()  //s/b unnecessary
////                    
////                    spinner.stopAnimating()
////                    spinner.hidden = true
////                    Globals.playerPaused = true
////                    setupPlayPauseButton()
////                    
////                    removePlayObserver()
////                }
//                break
//            }
//        }
//    }
    
    
    func sliderTimer()
    {
        //We shouldn't continue if a sermon is playing in a different series
        //This was a hard bug to find.  It showed up when trying to auto advance to the next sermon in a
        //series but only after having changed series from the one playing and starting a new one playing in 
        //the newly selected series.  The old sliderTimer was still running and causing havoc when I slid the
        //slider to the end of the sermon audio.
        //
        // This bug happened beause the NSTimers (sliderTimer and playTimer) should be in Globals, not tied 
        // to the individual views so we don't lose control of them.  With them now in Globals I'm not sure
        // the if clause below matters, but it doesn't hurt.
        //
//        if (Globals.sermonPlaying?.series != seriesSelected) {
//            removeSliderObserver()
//            removePlayObserver()
//        }
        
        //The conditional below depends upon sliderTimer running even when, in fact especially when, nothing is playing.
        if (sermonSelected == Globals.sermonPlaying) {
            playPauseButton.enabled = Globals.sermonLoaded
            slider.enabled = Globals.sermonLoaded
            
            if (!Globals.sermonLoaded) {
                if (!spinner.isAnimating()) {
                    spinner.hidden = false
                    spinner.startAnimating()
                }
            } else {
                if (Globals.mpPlayer?.playbackState != .SeekingForward) && (Globals.mpPlayer?.playbackState != .SeekingBackward) {
                    setSliderAndTimesToAudio()
                    if spinner.isAnimating() {
                        spinner.stopAnimating()
                        spinner.hidden = true
                    }
                } else {
                    if !spinner.isAnimating() {
                        spinner.hidden = false
                        spinner.startAnimating()
                    }
                }
            }
        }
        
        if (Globals.mpPlayer?.currentPlaybackRate > 0) {
            updateCurrentTimeWhilePlaying()
        }
        
        if (Globals.mpPlayer != nil) {
            switch Globals.mpPlayer!.playbackState {
            case .Interrupted:
                print("sliderTimer.Interrupted")
                break
            
            case .Paused:
                print("sliderTimer.Paused")
//                if (!Globals.playerPaused) {
//                    Globals.mpPlayer?.play()
//                    Globals.playerPaused = true
//                    setupPlayPauseButton()
//                }
                break
            
            case .Playing:
                print("sliderTimer.Playing")
//                if (Globals.playerPaused) {
//                    Globals.mpPlayer?.pause()
//                    Globals.playerPaused = false
//                    setupPlayPauseButton()
//                }
                break
            
            case .SeekingBackward:
                print("sliderTimer.SeekingBackward")
                break
            
            case .SeekingForward:
                print("sliderTimer.SeekingForward")
                break

            case .Stopped:
//                print("sliderTimer.Stopped")
                break
            }
            
            //This interferes with proper setting of the button at time, e.g. when changing sermons
            //        if (Globals.mpPlayer?.currentPlaybackRate == 0) {
            //            Globals.playerPaused = true
            //            setupPlayPauseButton()
            //        }
            
//            print("Duration: \(Globals.mpPlayer!.duration) CurrentPlaybackTime: \(Globals.mpPlayer!.currentPlaybackTime)")
            
            if (Globals.mpPlayer!.currentPlaybackTime > 0) && (Globals.mpPlayer!.duration > 0) &&
                (slider.value > 0.9999) {
                    // The comparison below is Int because I'm concerned Float leaves room for small differences.  We'll see.
//            (Int(Globals.mpPlayer!.currentPlaybackTime) == Int(Globals.mpPlayer!.duration)) {
//                print("sliderTimer currentPlaybackTime == duration")
                if (!Globals.playerPaused) {
                    Globals.mpPlayer?.pause()
                    Globals.playerPaused = true
                    setupPlayPauseButton()
                }
                
                if (Globals.sermonPlaying?.currentTime != Globals.mpPlayer!.duration.description) {
                    Globals.sermonPlaying?.currentTime = Globals.mpPlayer!.duration.description
                }
                
                if (NSUserDefaults.standardUserDefaults().boolForKey(Constants.AUTO_ADVANCE)) {
                    nextSermon()
                }
            }
        }
    }
    
    func nextSermon()
    {
        if (Globals.sermonPlaying!.index < (Globals.sermonPlaying!.series!.show! - 1)) {
            //            print("\(sermonSelected!)")
            sermonSelected = Globals.sermonPlaying?.series?.sermons?[Globals.sermonPlaying!.index + 1]
            //            print("\(sermonSelected!)")
            sermonSelected?.currentTime = Constants.ZERO
            selectSermon(sermonSelected)
            playNewSermon(sermonSelected)
        } else {
            Globals.playerPaused = true
            setupPlayPauseButton()
//            updateCVC()
        }
    }
    
    func priorSermon()
    {
        if (Globals.sermonPlaying!.index > 0) {
            //            print("\(sermonSelected!)")
            sermonSelected = Globals.sermonPlaying?.series?.sermons?[Globals.sermonPlaying!.index - 1]
            //            print("\(sermonSelected!)")
            selectSermon(sermonSelected)
            playNewSermon(sermonSelected)
        } else {
            Globals.playerPaused = true
            setupPlayPauseButton()
        }
    }
    
    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) { // && (self.view.window != nil)
            dismissViewControllerAnimated(true, completion: nil)
            
            let alert = UIAlertController(title: Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func seekingTimer()
    {
        setupPlayingInfoCenter()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        print("remoteControlReceivedWithEvent")
        
        switch event!.subtype {
        case UIEventSubtype.MotionShake:
            print("RemoteControlShake")
            break
            
        case UIEventSubtype.None:
            print("RemoteControlNone")
            break
            
        case UIEventSubtype.RemoteControlStop:
            print("RemoteControlStop")
            Globals.mpPlayer?.stop()
            Globals.playerPaused = true
            break
            
        case UIEventSubtype.RemoteControlPlay:
            print("RemoteControlPlay")
            Globals.mpPlayer?.play()
            Globals.playerPaused = false
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlPause:
            print("RemoteControlPause")
            Globals.mpPlayer?.pause()
            Globals.playerPaused = true
            updateCurrentTimeExact()
            break
            
        case UIEventSubtype.RemoteControlTogglePlayPause:
            print("RemoteControlTogglePlayPause")
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
            break
            
        case UIEventSubtype.RemoteControlPreviousTrack:
            print("RemoteControlPreviousTrack")
            if (Globals.mpPlayer?.currentPlaybackTime == 0) {
                // Would like it to skip to the prior sermon in the series if there is one.
            } else {
                Globals.mpPlayer?.currentPlaybackTime = 0
            }
            break
            
        case UIEventSubtype.RemoteControlNextTrack:
            print("RemoteControlNextTrack")
            Globals.mpPlayer?.currentPlaybackTime = Globals.mpPlayer!.duration
            break
            
            //The lock screen time elapsed/remaining don't track well with seeking
            //But at least this has them moving in the right direction.
            
        case UIEventSubtype.RemoteControlBeginSeekingBackward:
            print("RemoteControlBeginSeekingBackward")
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
            Globals.mpPlayer?.beginSeekingBackward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingBackward:
            print("RemoteControlEndSeekingBackward")
            Globals.mpPlayer?.endSeeking()
            Globals.seekingObserver?.invalidate()
            Globals.seekingObserver = nil
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlBeginSeekingForward:
            print("RemoteControlBeginSeekingForward")
            Globals.mpPlayer?.beginSeekingForward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingForward:
            print("RemoteControlEndSeekingForward")
            Globals.mpPlayer?.endSeeking()
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
        }

        setupPlayPauseButton()
    }

    func mpPlayerLoadStateDidChange(notification:NSNotification)
    {
        let player = notification.object as! MPMoviePlayerController
        
        let loadstate:UInt8 = UInt8(player.loadState.rawValue)
        
        let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
        let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0

//        println("\(loadstate)")
//        print("\(playable)")
//        print("\(playthrough)")
        
        if (playable || playthrough) && !Globals.sermonLoaded && (Globals.sermonPlaying != nil) {
            //            print("\(Globals.sermonPlaying!.currentTime!)")
            //            print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")
            
            // The comparison below is Int because I'm concerned Float leaves room for small differences.  We'll see.
            if Globals.sermonPlaying!.hasCurrentTime() {
                if (Int(Float(Globals.sermonPlaying!.currentTime!)!) == Int(Globals.mpPlayer!.duration)) {
                    Globals.sermonPlaying!.currentTime = Constants.ZERO
                }
            } else {
                Globals.sermonPlaying!.currentTime = Constants.ZERO
            }

            Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)
            
            updateCurrentTimeExact()
            setupPlayingInfoCenter()
            
            spinner.stopAnimating()
            Globals.sermonLoaded = true
            
            Globals.mpPlayer?.play()
            
            playPauseButton.enabled = true
            slider.enabled = true
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        }

        if (Globals.mpPlayer != nil) {
            switch Globals.mpPlayer!.playbackState {
            case .Interrupted:
                print("mpPlayerLoadStateDidChange.Interrupted")
                break
                
            case .Paused:
                print("mpPlayerLoadStateDidChange.Paused")
                break
                
            case .Playing:
                print("mpPlayerLoadStateDidChange.Playing")
                //Why are the following statement required?
                spinner.stopAnimating()
                spinner.hidden = true
                setupPlayingInfoCenter()
                NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
                break
                
            case .SeekingBackward:
                print("mpPlayerLoadStateDidChange.SeekingBackward")
                break
                
            case .SeekingForward:
                print("mpPlayerLoadStateDidChange.SeekingForward")
                break
                
            case .Stopped:
                print("mpPlayerLoadStateDidChange.Stopped")
                //Why are the following statement required?
                if !Globals.playerPaused {
                    Globals.mpPlayer?.play()
                }
                break
            }
        }
    }
    
    func addSliderObserver()
    {
        if (Globals.mpPlayer != nil) {
            if (Globals.sliderObserver != nil) {
                Globals.sliderObserver?.invalidate()
            }
            
            //Slider observer runs every second
            Globals.sliderObserver = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "sliderTimer", userInfo: nil, repeats: true)
        } else {
            // Problem
            print("Globals.player == nil in sliderObserver")
            // Should we setup the player all over again?
        }
    }
    
    private func playNewSermon(sermon:Sermon?)
    {
        updateCurrentTimeExact()
        Globals.mpPlayer?.stop()

        if (sermon != nil) {
            Globals.sermonPlaying = sermon
            Globals.playerPaused = false
            
            Globals.mpPlayer?.stop()
            
//            setupSeriesAndSermonPlayingUserDefaults()
            
            removeSliderObserver()
            
            //This guarantees a fresh start.
            Globals.mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL)
            
            Globals.mpPlayer?.shouldAutoplay = false
            Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
            Globals.mpPlayer?.prepareToPlay()

            // This stops the spinner spinning once the audio starts
            Globals.sermonLoaded = false
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
            
            setupPlayingInfoCenter()
            
            addSliderObserver()
            
            if (view.window != nil) {
                setupSlider()
                setupPlayPauseButton()
                setupActionsButton()
//                updateCVC()
            }
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        if let cell = seriesSermons.cellForRowAtIndexPath(indexPath) as? MyTableViewCell {
//
//        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        sermonSelected = seriesSelected?.sermons?[indexPath.row]
        
        setupSlider() // calls addSliderObserver()
        setupPlayPauseButton()
//        updateCVC()
        //        println("didSelect")
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
