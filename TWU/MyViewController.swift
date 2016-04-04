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
    
    var sliderObserver: NSTimer?

    var seriesSelected:Series?
    
    var sermonSelected:Sermon? {
        didSet {
            seriesSelected?.sermonSelected = sermonSelected

            if (sermonSelected != nil) {
//                print("\(sermonSelected)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_PLAYING_PAUSED_NOTIFICATION, object: nil)
                })
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
            switch Globals.mpPlayerStateTime!.state {
            case .none:
//                print("none")
                break
                
            case .playing:
//                print("playing")
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact(Globals.mpPlayer!.currentPlaybackTime)
                setupPlayPauseButton()
                break
                
            case .paused:
//                print("paused")
                let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
                
                let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
                let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
                
                if (playable || playthrough) {
//                    print("playPause.MPMovieLoadState.Playable or Playthrough OK")
                    Globals.playerPaused = false
                    
                    if (Globals.mpPlayer?.contentURL == sermonSelected?.playingURL) {
                        if sermonSelected!.hasCurrentTime() {
                            //Make the comparision an Int to avoid missing minor differences
                            if (Globals.mpPlayer!.duration >= 0) && (Int(Float(sermonSelected!.currentTime!)!) == Int(Float(Globals.mpPlayer!.duration))) {
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
//                    print("playPause.MPMovieLoadState.Playable or Playthrough NOT OK")
                    playNewSermon(sermonSelected)
                }
                break
                
            case .stopped:
//                print("stopped")
                break
                
            case .seekingForward:
//                print("seekingForward")
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact(Globals.mpPlayer!.currentPlaybackTime)
                setupPlayPauseButton()
                break
                
            case .seekingBackward:
//                print("seekingBackward")
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact(Globals.mpPlayer!.currentPlaybackTime)
                setupPlayPauseButton()
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
            let tap = UITapGestureRecognizer(target: self, action: #selector(MyViewController.flip(_:)))
            seriesArt.addGestureRecognizer(tap)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(MyViewController.flipFromLeft(_:)))
            swipeRight.direction = UISwipeGestureRecognizerDirection.Right
            seriesArt.addGestureRecognizer(swipeRight)
            
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(MyViewController.flipFromRight(_:)))
            swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
            seriesArt.addGestureRecognizer(swipeLeft)
        }
    }
    
    @IBOutlet weak var seriesDescription: UITextView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(MyViewController.flip(_:)))
            seriesDescription.addGestureRecognizer(tap)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(MyViewController.flipFromLeft(_:)))
            swipeRight.direction = UISwipeGestureRecognizerDirection.Right
            seriesDescription.addGestureRecognizer(swipeRight)
            
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(MyViewController.flipFromRight(_:)))
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
        if (Globals.mpPlayer != nil) {
            if (slider.value < 1.0) {
                let length = Float(Globals.mpPlayer!.duration)
                let seekToTime = slider.value * Float(length)
                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(seekToTime)
                Globals.sermonPlaying?.currentTime = seekToTime.description
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
                break
                
            case Constants.Cancel_All_Downloads:
                if (seriesSelected?.sermons != nil) {
                    for sermon in seriesSelected!.sermons! {
                        sermon.audioDownload?.cancelDownload()
                    }
                }
                break
                
            case Constants.Delete_All_Downloads:
                if (seriesSelected?.sermons != nil) {
                    for sermon in seriesSelected!.sermons! {
                        sermon.audioDownload?.deleteDownload()
                    }
                }
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
                            sermonsToDownload += 1
                            break
                        case .downloading:
                            sermonsDownloading += 1
                            break
                        case .downloaded:
                            sermonsDownloaded += 1
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
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyViewController.updateView), name: Constants.UPDATE_VIEW_NOTIFICATION, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyViewController.clearView), name: Constants.CLEAR_VIEW_NOTIFICATION, object: nil)
        }

        if (splitViewController == nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyViewController.sermonUpdateAvailable), name: Constants.SERMON_UPDATE_AVAILABLE_NOTIFICATION, object: nil)
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyViewController.setupPlayPauseButton), name: Constants.SERMON_UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)

        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        
//        tableView.allowsSelection = true

        // Can't do this or selecting a row doesn't work reliably.
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            self.scrollToSermon(self.sermonSelected, select: true, position: UITableViewScrollPosition.Middle)
            
            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                if let view = self.seriesArtAndDescription.subviews[1] as? UITextView {
                    //            view.scrollRectToVisible(CGRectMake(0, 0, 50, 50), animated: false)
                    view.scrollRangeToVisible(NSMakeRange(0, 0))
                }
        }
    }
    
    private func setupActionsButton()
    {
        if (seriesSelected != nil) {
            actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: #selector(MyViewController.actions))
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
    
    private func setupTitle()
    {
        self.navigationItem.title = seriesSelected?.title
    }
    
//    func setupPlayerAtEnd(sermon:Sermon?)
//    {
//        setupPlayer(sermon)
//        
//        if (Globals.mpPlayer != nil) {
//            Globals.mpPlayer?.currentPlaybackTime = Globals.mpPlayer!.duration
//            Globals.mpPlayer?.pause()
//        }
//    }
    
    func sermonUpdateAvailable()
    {
        if navigationController?.visibleViewController == self {
            let alert = UIAlertView(title: "Sermon Update Available", message: "Return to the series view to update.", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    func updateUI()
    {
        if (seriesSelected != nil) {
            logo.hidden = true
            seriesArt.image = seriesSelected?.getArt()
            seriesDescription.text = seriesSelected?.text
        } else {
            logo.hidden = false
            seriesArt.hidden = true
            seriesDescription.hidden = true
        }
        
//        if (sermonSelected != nil) && (Globals.mpPlayer == nil) {
//            setupPlayerAtEnd(sermonSelected)
//        }

        addSliderObserver()
        
        setupActionsButton()
        setupArtAndDescription()
        
        setupTitle()
        setupPlayPauseButton()
        setupSlider()
    }
    
    func scrollToSermon(sermon:Sermon?,select:Bool,position:UITableViewScrollPosition)
    {
        if (sermon != nil) {
            var indexPath = NSIndexPath(forRow: 0, inSection: 0)
            
            if (seriesSelected?.show > 1) {
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

        if (splitViewController == nil) {
            if (UIApplication.sharedApplication().applicationIconBadgeNumber > 0) && ((splitViewController == nil) || (splitViewController!.viewControllers.count == 1)) {
                sermonUpdateAvailable()
            }
        }
        
//        print("Series Selected: \(seriesSelected?.title) Playing: \(Globals.sermonPlaying?.series?.title)")
//        print("Sermon Selected: \(sermonSelected?.series?.title)")
        
        if (sermonSelected != nil) {
            if (sermonSelected == Globals.sermonPlaying) {
                setupSlider()  // calls addSliderObserver()
            }
            
            scrollToSermon(sermonSelected,select:true,position:UITableViewScrollPosition.Middle)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        sliderObserver?.invalidate()

        NSNotificationCenter.defaultCenter().removeObserver(self)
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
            return seriesSelected!.show
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
    
    func sliderTimer()
    {
        if (sermonSelected != nil) && (sermonSelected == Globals.sermonPlaying) {
            let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
            
            if playable {
//                print("sliderTimer.MPMovieLoadState.Playable")
            }
            
            if playthrough {
//                print("sliderTimer.MPMovieLoadState.Playthrough")
            }
            
            playPauseButton.enabled = Globals.sermonLoaded
            slider.enabled = Globals.sermonLoaded
            
            if (!Globals.sermonLoaded) {
                if (!spinner.isAnimating()) {
                    spinner.hidden = false
                    spinner.startAnimating()
                }
            }
            
            switch Globals.mpPlayerStateTime!.state {
            case .none:
//                print("none")
                break
                
            case .playing:
//                print("playing")
                switch Globals.mpPlayer!.playbackState {
                case .SeekingBackward:
//                    print("sliderTimer.SeekingBackward")
                    break
                    
                case .SeekingForward:
//                    print("sliderTimer.SeekingForward")
                    break
                    
                default:
                    setSliderAndTimesToAudio()
                    
                    if !(playable || playthrough) { // Globals.mpPlayer?.currentPlaybackRate == 0
//                        print("sliderTimer.Playthrough or Playing NOT OK")
                        if !spinner.isAnimating() {
                            spinner.hidden = false
                            spinner.startAnimating()
                        }
                    }
                    
                    if (playable || playthrough) {
//                        print("sliderTimer.Playthrough or Playing OK")
                        if spinner.isAnimating() {
                            spinner.stopAnimating()
                            spinner.hidden = true
                        }
                    }
                    break
                }
                break
                
            case .paused:
//                print("paused")
                
                if Globals.sermonLoaded {
                    setSliderAndTimesToAudio()
                    if spinner.isAnimating() {
                        spinner.stopAnimating()
                        spinner.hidden = true
                    }
                }
                break
                
            case .stopped:
//                print("stopped")
                break
                
            case .seekingForward:
//                print("seekingForward")
                if !spinner.isAnimating() {
                    spinner.hidden = false
                    spinner.startAnimating()
                }
                break
                
            case .seekingBackward:
//                print("seekingBackward")
                if !spinner.isAnimating() {
                    spinner.hidden = false
                    spinner.startAnimating()
                }
                break
            }
            
//            if (Globals.mpPlayer != nil) {
//                switch Globals.mpPlayer!.playbackState {
//                case .Interrupted:
//                    print("sliderTimer.Interrupted")
//                    break
//                    
//                case .Paused:
//                    print("sliderTimer.Paused")
//                    break
//                    
//                case .Playing:
//                    print("sliderTimer.Playing")
//                    break
//                    
//                case .SeekingBackward:
//                    print("sliderTimer.SeekingBackward")
//                    break
//                    
//                case .SeekingForward:
//                    print("sliderTimer.SeekingForward")
//                    break
//                    
//                case .Stopped:
//                    print("sliderTimer.Stopped")
//                    break
//                }
//            }
            
            //        print("Duration: \(Globals.mpPlayer!.duration) CurrentPlaybackTime: \(Globals.mpPlayer!.currentPlaybackTime)")
            
            if (Globals.mpPlayer!.duration > 0) && (Globals.mpPlayer!.currentPlaybackTime > 0) &&
                (Int(Float(Globals.mpPlayer!.currentPlaybackTime)) == Int(Float(Globals.mpPlayer!.duration))) { //  (slider.value > 0.9999)
                if (NSUserDefaults.standardUserDefaults().boolForKey(Constants.AUTO_ADVANCE)) {
                    nextSermon()
                }
            }
        }
    }
    
    func nextSermon()
    {
        print(sermonSelected)
        
        if let index = seriesSelected?.sermons?.indexOf(Globals.sermonPlaying!) {
            if (index < (seriesSelected!.sermons!.count - 1)) {
                sermonSelected = seriesSelected?.sermons?[index + 1]

                print(sermonSelected)

                sermonSelected?.currentTime = Constants.ZERO
                
                selectSermon(sermonSelected)
                
                updateUI()
                
                playNewSermon(sermonSelected)
            }
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
    
    func removeSliderObserver() {
        if (sliderObserver != nil) {
            sliderObserver!.invalidate()
            sliderObserver = nil
        }
    }
    
    func addSliderObserver()
    {
        if (Globals.mpPlayer != nil) {
            if (sliderObserver != nil) {
                sliderObserver?.invalidate()
            }
            
            //Slider observer runs every second
            sliderObserver = NSTimer.scheduledTimerWithTimeInterval(Constants.SLIDER_TIMER_INTERVAL, target: self, selector: #selector(MyViewController.sliderTimer), userInfo: nil, repeats: true)
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
            
            removeSliderObserver()
            
            //This guarantees a fresh start.
            setupPlayer(sermon)

            addSliderObserver()
            
            if (view.window != nil) {
                setupSlider()
                setupPlayPauseButton()
                setupActionsButton()
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
        
        updateUI()
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
