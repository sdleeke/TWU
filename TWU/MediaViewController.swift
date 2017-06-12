//
//  MediaViewController.swift
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

extension MediaViewController : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension MediaViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MediaViewController : MFMessageComposeViewControllerDelegate
{
    // MARK: MFMessageComposeViewControllerDelegate

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MediaViewController : UIPopoverPresentationControllerDelegate
{
    // MARK: UIPopoverPresentationControllerDelegate
    
}

extension MediaViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismiss(animated: true, completion: nil)
        
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
                
            case Constants.Share:
                shareHTML(viewController: self, htmlString: "\(seriesSelected!.title!) by Tom Pennington from The Word Unleashed\n\n\(seriesSelected!.url!.absoluteString)")
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
}

class MediaViewController : UIViewController  {
    var observerActive = false

    var sliding = false

//    private var PlayerContext = 0
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBAction func pageControlAction(_ sender: UIPageControl)
    {
        flip(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
//        guard context == &PlayerContext else {
//            super.observeValue(forKeyPath: keyPath,
//                               of: object,
//                               change: change,
//                               context: nil)
//            return
//        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
//                print(statusNumber.intValue)
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                //                print(player?.currentItem?.duration.value)
                //                print(player?.currentItem?.duration.timescale)
                //                print(player?.currentItem?.duration.seconds)
                
                if sermonSelected != nil {
                    if let length = player?.currentItem?.duration.seconds {
                        let timeNow = Double(sermonSelected!.currentTime!)!
                        let progress = timeNow / length
                        
                        //                    print("timeNow",timeNow)
                        //                    print("progress",progress)
                        //                    print("length",length)
                        
                        slider.value = Float(progress)
                        setTimes(timeNow: timeNow,length: length)
                        
                        elapsed.isHidden = false
                        remaining.isHidden = false
                        slider.isHidden = false
                        slider.isEnabled = false
                    }
                }
                break
                
            case .failed:
                // Player item failed. See error.
                break
                
            case .unknown:
                // Player item is not yet ready.
                break
            }
        }
    }

// A messy way to cache AVPlayers by URL and only change the UI for the one related to the currently selectedSermon when its observeValue callback is called.
// I'm proposing to do it this way because the AVPlayer does carry the URL with it and that will uniquely identify the sermon associated with that AVPlayer.
    
//    var players = [String:AVPlayer]() // index is URL
//    var sermons = [String:Sermon]() // index is URL
    
    var player:AVPlayer?
//    {
//        get {
//            if sermonSelected != nil {
//                return players[sermonSelected!.playingURL!.absoluteString]
//            } else {
//                return nil
//            }
//        }
//        set {
//            players[sermonSelected!.playingURL!.absoluteString] = newValue
//            sermons[sermonSelected!.playingURL!.absoluteString] = sermonSelected
//        }
//    }

    func removePlayerObserver()
    {
        // observerActive and this function would not be needed if we cache as we would assume EVERY AVPlayer in the cache has an observer => must remove them prior to dealloc.
        
        if observerActive {
            player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil) // &PlayerContext
            observerActive = false
        }
    }
    
    func addPlayerObserver()
    {
        player?.currentItem?.addObserver(self,
                                         forKeyPath: #keyPath(AVPlayerItem.status),
                                         options: [.old, .new],
                                         context: nil) // &PlayerContext
        observerActive = true
    }
    
    func playerURL(url: URL?)
    {
        removePlayerObserver()
        
        if url != nil {
            player = AVPlayer(url: url!)
            addPlayerObserver()
//            if player == nil {
//            }
        }
    }
    
    var sliderObserver: Timer?

    var seriesSelected:Series?
//    {
//        didSet {
//            if let seriesSermons = seriesSelected?.sermons {
//                for sermon in seriesSermons {
//                    if let url = sermon.playingURL {
//                        if players[url.absoluteString] == nil {
//                            players[url.absoluteString] = AVPlayer(url: url)
//                            
//                            players[url.absoluteString]?.currentItem?.addObserver(self,
//                                                                                  forKeyPath: #keyPath(AVPlayerItem.status),
//                                                                                  options: [.old, .new],
//                                                                                  context: nil) // &PlayerContext
//                            
//                            sermons[url.absoluteString] = sermon
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    var sermonSelected:Sermon? {
        willSet {
            
        }
        didSet {
//            print(sermonSelected)
            seriesSelected?.sermonSelected = sermonSelected

            if (sermonSelected != nil) && (sermonSelected != oldValue) {
//                print("\(sermonSelected)")
                
                if (sermonSelected != globals.mediaPlayer.playing) {
                    removeSliderObserver()
                    playerURL(url: sermonSelected!.playingURL!)
                } else {
                    removePlayerObserver()
//                    addSliderObserver() // Crashes because it uses UI and this is done before viewWillAppear when the sermonSelected is set in prepareForSegue, but it only happens on an iPhone because the MVC isn't setup already.
                }

                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SERMON_UPDATE_PLAYING_PAUSED), object: nil)
                })
            } else {
//                print("MediaViewController:sermonSelected nil")
            }
        }
    }
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBAction func playPause(_ sender: UIButton) {
        guard (globals.mediaPlayer.state != nil) && (globals.mediaPlayer.playing == sermonSelected) && (globals.mediaPlayer.player != nil) else {
            playNewSermon(sermonSelected)
            return
        }

        switch globals.mediaPlayer.state! {
        case .none:
            print("none")
            break
            
        case .playing:
            print("playing")
            globals.mediaPlayer.pause()
            
            //                setupPlayPauseButton()
            
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            break
            
        case .paused:
            print("paused")
            if globals.mediaPlayer.loaded && (globals.mediaPlayer.url == sermonSelected?.playingURL) {
                playCurrentSermon(sermonSelected)
            } else {
                playNewSermon(sermonSelected)
            }
            break
            
        case .stopped:
            print("stopped")
            break
            
        case .seekingForward:
            print("seekingForward")
            globals.mediaPlayer.pause()
            //                setupPlayPauseButton()
            break
            
        case .seekingBackward:
            print("seekingBackward")
            globals.mediaPlayer.pause()
            //                setupPlayPauseButton()
            break
        }
    }

    override var canBecomeFirstResponder : Bool
    {
        return true
    }

    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            globals.motionEnded(motion, event: event)
        }
    }

    func setupPlayPauseButton()
    {
        guard (sermonSelected != nil) else {
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = true
            return
        }

        if (sermonSelected == globals.mediaPlayer.playing) {
            playPauseButton.isEnabled = globals.mediaPlayer.loaded || globals.mediaPlayer.loadFailed
            
            switch globals.mediaPlayer.state! {
            case .playing:
                //                    print("Pause")
                playPauseButton.setTitle(Constants.FA.PAUSE, for: UIControlState())
                break
                
            case .paused:
                //                    print("Play")
                playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState())
                break
                
            default:
                break
            }
        } else {
            playPauseButton.isEnabled = true
            playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState())
        }
        
        playPauseButton.isHidden = false
    }
    
    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var remaining: UILabel!
    
    @IBOutlet weak var seriesArtAndDescription: UIView!
    
    @IBOutlet weak var seriesArt: UIImageView! {
        willSet {
            
        }
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.flip(_:)))
            seriesArt.addGestureRecognizer(tap)
            
//            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(MediaViewController.flipFromLeft(_:)))
//            swipeRight.direction = UISwipeGestureRecognizerDirection.right
//            seriesArt.addGestureRecognizer(swipeRight)
//            
//            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(MediaViewController.flipFromRight(_:)))
//            swipeLeft.direction = UISwipeGestureRecognizerDirection.left
//            seriesArt.addGestureRecognizer(swipeLeft)
        }
    }
    
    @IBOutlet weak var seriesDescription: UITextView! {
        willSet {
            
        }
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.flip(_:)))
            seriesDescription.addGestureRecognizer(tap)
            
//            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(MediaViewController.flipFromLeft(_:)))
//            swipeRight.direction = UISwipeGestureRecognizerDirection.right
//            seriesDescription.addGestureRecognizer(swipeRight)
//            
//            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(MediaViewController.flipFromRight(_:)))
//            swipeLeft.direction = UISwipeGestureRecognizerDirection.left
//            seriesDescription.addGestureRecognizer(swipeLeft)
            
            seriesDescription.text = seriesSelected?.text
            seriesDescription.alwaysBounceVertical = true
            seriesDescription.isSelectable = false
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var slider: OBSlider!
    
    fileprivate func adjustAudioAfterUserMovedSlider()
    {
        guard (globals.mediaPlayer.player != nil) else {
            return
        }
        
        if (slider.value < 1.0) {
            let length = globals.mediaPlayer.duration!.seconds
            let seekToTime = Double(slider.value) * length
            
            globals.mediaPlayer.seek(to: seekToTime)
            
            globals.mediaPlayer.playing?.currentTime = seekToTime.description
        } else {
            globals.mediaPlayer.pause()
            
            globals.mediaPlayer.seek(to: globals.mediaPlayer.duration!.seconds)
            globals.mediaPlayer.playing?.currentTime = globals.mediaPlayer.duration!.seconds.description
        }
        
        switch globals.mediaPlayer.state! {
        case .playing:
            sliding = globals.reachability.isReachable
            break
            
        default:
            sliding = false
            break
        }
        
        globals.mediaPlayer.playing?.atEnd = slider.value == 1.0
        
        globals.mediaPlayer.startTime = globals.mediaPlayer.playing?.currentTime
        
        setupSpinner()
        setupPlayPauseButton()
        addSliderObserver()
    }
    
    @IBAction func sliderTouchDown(_ sender: UISlider) {
        //        println("sliderTouchDown")
        sliding = true
        removeSliderObserver()
    }
    
    @IBAction func sliderTouchUpOutside(_ sender: UISlider) {
        //        println("sliderTouchUpOutside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderTouchUpInside(_ sender: UISlider) {
        //        println("sliderTouchUpInside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderValueChanging(_ sender: UISlider) {
        setTimeToSlider()
    }
    
    var views : (seriesArt: UIView?, seriesDescription: UIView?)

//    var sliderObserver: NSTimer?
//    var playObserver: NSTimer?

    var actionButton:UIBarButtonItem?
    
    fileprivate func showSendMessageErrorAlert() {
        let sendMessageErrorAlert = UIAlertView(title: "Could Not Send a Message", message: "Your device could not send a text message.  Please check your configuration and try again.", delegate: self, cancelButtonTitle: Constants.Okay)
        sendMessageErrorAlert.show()
    }
    
    fileprivate func message()
    {
        
        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self // Extremely important to set the --messageComposeDelegate-- property, NOT the --delegate-- property
        
        messageComposeViewController.recipients = []
        messageComposeViewController.subject = Constants.Email_Subject
        messageComposeViewController.body = setupBody()
        
        if MFMailComposeViewController.canSendMail() {
            self.present(messageComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    fileprivate func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check your e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    fileprivate func setupBody() -> String {
        var bodyString = String()
        
        bodyString = "I've enjoyed the sermon series \""
        bodyString = bodyString + seriesSelected!.title!
        bodyString = bodyString + "\" by Tom Pennington and thought you would enjoy it as well."
        bodyString = bodyString + "\n\nThis series of sermons is available at "
        bodyString = bodyString + seriesSelected!.url!.absoluteString
        
        return bodyString
    }
    
    fileprivate func setupBodyHTML(_ series:Series?) -> String? {
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
    
    fileprivate func addressStringHTML() -> String
    {
        let addressString:String = "</br>Countryside Bible Church</br>250 Countryside Ct.</br>Southlake, TX 76092</br>(817) 488-5381</br><a href=\"mailto:cbcstaff@countrysidebible.org\">cbcstaff@countrysidebible.org</a></br>www.countrysidebible.org"
        
        return addressString
    }
    
    fileprivate func addressString() -> String
    {
        let addressString:String = "\n\nCountryside Bible Church\n250 Countryside Ct.\nSouthlake, TX 76092\nPhone: (817) 488-5381\nE-mail:cbcstaff@countrysidebible.org\nWeb: www.countrysidebible.org"
        
        return addressString
    }
    
    fileprivate func emailSeries(_ series:Series?)
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
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    fileprivate func openSeriesOnWeb(_ series:Series?)
    {
        if let url = series?.url {
            if UIApplication.shared.canOpenURL(url as URL) {
                UIApplication.shared.openURL(url as URL)
            } else {
                networkUnavailable("Unable to open url: \(url)")
            }
        }
    }
    
    fileprivate func openScripture(_ series:Series?)
    {
        guard (series?.scripture != nil) else {
            return
        }
        
        var urlString = Constants.SCRIPTURE_URL.PREFIX + series!.scripture! + Constants.SCRIPTURE_URL.POSTFIX
        
        urlString = urlString.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.literal, range: nil)
        //        println("\(urlString)")
        
        if let url = URL(string:urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
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
    
    func twitter()
    {
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter){
            var bodyString = String()
            
            bodyString = "Great sermon series: \"\(seriesSelected!.title ?? "TITLE")\" by \(Constants.Tom_Pennington).  " + seriesSelected!.url!.absoluteString
            
            let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twitterSheet.setInitialText(bodyString)
            self.present(twitterSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
//        if Reachability.isConnectedToNetwork() {
//            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter){
//                var bodyString = String()
//                
//                bodyString = "Great sermon series: \"\(globals.seriesSelected!.title)\" by \(Constants.Tom_Pennington).  " + Constants.BASE_WEB_URL + String(globals.seriesSelected!.id)
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
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook){
            var bodyString = String()
            
            bodyString = "Great sermon series: \"\(seriesSelected!.title ?? "TITLE")\" by \(Constants.Tom_Pennington).  " + seriesSelected!.url!.absoluteString
            
            //So the user can paste the initialText into the post dialog/view
            //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
            UIPasteboard.general.string = bodyString
            
            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            facebookSheet.setInitialText(bodyString)
            self.present(facebookSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
//        if Reachability.isConnectedToNetwork() {
//            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
//                var bodyString = String()
//                
//                bodyString = "Great sermon series: \"\(globals.seriesSelected!.title)\" by \(Constants.Tom_Pennington).  " + Constants.BASE_WEB_URL + String(globals.seriesSelected!.id)
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

    func actions()
    {
        //        println("action!")
        
        // Put up an action sheet
        
    if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
        let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            //            popover?.preferredContentSize = CGSizeMake(300, 500)
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = actionButton
            
            //                popover.navigationItem.title = "Show"
            
            popover.navigationController?.isNavigationBarHidden = true
            
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
            
            actionMenu.append(Constants.Share)
            
            popover.strings = actionMenu
            
            popover.showIndex = false //(globals.grouping == .series)
            popover.showSectionHeaders = false
            
            present(navigationController, animated: true, completion: nil)
        }
    }

    func updateView()
    {
        guard Thread.isMainThread else {
            return
        }
        
        seriesSelected = globals.seriesSelected
//        print(seriesSelected?.sermonSelected)
        sermonSelected = seriesSelected?.sermonSelected
        
//        sermonSelected = globals.sermonSelected
        
        //        print(seriesSelected)
        //        print(sermonSelected)
        
        tableView.reloadData()

        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToSermon(self.sermonSelected, select: true, position: UITableViewScrollPosition.none)
            })
        })

        updateUI()
    }
    
    func clearView()
    {
        guard Thread.isMainThread else {
            return
        }
        
        seriesSelected = nil
        sermonSelected = nil
        
        tableView.reloadData()
        
        updateUI()
    }
    
    override func viewDidLoad()
    {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        
//        tableView.allowsSelection = true

        // Can't do this or selecting a row doesn't work reliably.
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
//        if (self.view.window == nil) {
//            return
//        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.scrollToSermon(self.sermonSelected, select: true, position: UITableViewScrollPosition.none)
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            if let view = self.seriesArtAndDescription.subviews[1] as? UITextView {
                view.scrollRangeToVisible(NSMakeRange(0, 0))
            }

            if self.navigationController?.visibleViewController == self {
                self.navigationController?.isToolbarHidden = true
                
                if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
                    let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
                    let count = self.splitViewController?.viewControllers.count {
                    if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
                        if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
                            navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                        } else {
                            navigationController.topViewController?.navigationItem.leftBarButtonItem = nil
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func setupActionsButton()
    {
        if (seriesSelected != nil) {
            actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.actions))
            actionButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.FONT_SIZE)!], for: UIControlState())
            
//            actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(MediaViewController.actions))
            
            self.navigationItem.rightBarButtonItem = actionButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
            actionButton = nil
        }
    }
    
    fileprivate func setupArtAndDescription()
    {
        guard Thread.isMainThread else {
            return
        }
        
        if (seriesSelected != nil) {
            seriesArtAndDescription.isHidden = false
            
            logo.isHidden = true
            pageControl.isHidden = false
            
//            print(seriesSelected?.text)
            
            if let text = seriesSelected?.text?.replacingOccurrences(of: " ???", with: ",").replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: "—", with: "&mdash;").replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n\n", with: "\n").replacingOccurrences(of: "\n", with: "<br><br>").replacingOccurrences(of: "’", with: "&rsquo;").replacingOccurrences(of: "“", with: "&ldquo;").replacingOccurrences(of: "”", with: "&rdquo;").replacingOccurrences(of: "?۪s", with: "'s").replacingOccurrences(of: "…", with: "...") {
                if let attributedString = try? NSMutableAttributedString(data: text.data(using: String.Encoding.utf8, allowLossyConversion: false)!,
                                                                         options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
                                                                         documentAttributes: nil) {
                
                    attributedString.addAttributes([NSFontAttributeName:UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)],
                                                   range: NSMakeRange(0, attributedString.length))

                    seriesDescription.attributedText = attributedString
                }
            }

            if let series = self.seriesSelected {
                if let image = series.loadArt() {
                    seriesArt.image = image
                } else {
                    DispatchQueue.global(qos: .background).async { () -> Void in
                        if let image = series.fetchArt() {
                            if self.seriesSelected == series {
                                DispatchQueue.main.async {
                                    self.seriesArt.image = image
                                }
                            }
                        }
                    }
                }
            }

            seriesArt.isHidden = pageControl.currentPage == 1
            seriesDescription.isHidden = pageControl.currentPage == 0
        } else {
            //iPad only
            logo.isHidden = false
            
            seriesArt.isHidden = true
            seriesDescription.isHidden = true

            seriesArtAndDescription.isHidden = true
            pageControl.isHidden = true
        }
    }
    
    fileprivate func setupTitle()
    {
        guard Thread.isMainThread else {
            return
        }
        
        self.navigationItem.title = seriesSelected?.title
    }
    
    func setupSpinner()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard (sermonSelected != nil) && (sermonSelected == globals.mediaPlayer.playing) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        if !globals.mediaPlayer.loaded && !globals.mediaPlayer.loadFailed {
            if !spinner.isAnimating {
                spinner.isHidden = false
                spinner.startAnimating()
            }
        } else {
            if globals.mediaPlayer.isPaused {
                if spinner.isAnimating {
                    spinner.isHidden = true
                    spinner.stopAnimating()
                }
            }
            
            if globals.mediaPlayer.isPlaying {
                if (globals.mediaPlayer.currentTime!.seconds > Double(globals.mediaPlayer.playing!.currentTime!)!) {
                    spinner.isHidden = true
                    spinner.stopAnimating()
                } else {
                    spinner.isHidden = false
                    spinner.startAnimating()
                }
            }
        }
    }

    func updateUI()
    {
        //These are being added here for the case when this view is opened and the sermon selected is playing already
        if self.navigationController?.visibleViewController == self {
            self.navigationController?.isToolbarHidden = true
            
            if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
                let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
                let count = self.splitViewController?.viewControllers.count {
                if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
                    if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
                        navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                    } else {
                        navigationController.topViewController?.navigationItem.leftBarButtonItem = nil
                    }
                }
            }
        }
        
        addSliderObserver()
        
        setupActionsButton()
        setupArtAndDescription()
        
        setupTitle()
        setupPlayPauseButton()
        setupSpinner()
        setupSlider()
    }

    func scrollToSermon(_ sermon:Sermon?,select:Bool,position:UITableViewScrollPosition)
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard (sermon != nil) else {
            return
        }
        
        var indexPath = IndexPath(row: 0, section: 0)
        
        if (seriesSelected?.show > 1) {
            if let sermonIndex = seriesSelected?.sermons?.index(of: sermon!) {
//                    print("\(sermonIndex)")
                indexPath = IndexPath(row: sermonIndex, section: 0)
            }
        }
        
        //            print("\(tableView.bounds)")
        
        if (select) {
//                print(indexPath)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: position)
        }
        
        //            print("Row: \(indexPath.row) Section: \(indexPath.section)")

        tableView.scrollToRow(at: indexPath, at: position, animated: false)

//        if (position == UITableViewScrollPosition.top) {
//            //                var point = CGPointZero //tableView.bounds.origin
//            //                point.y += tableView.rowHeight * CGFloat(indexPath.row)
//            //                tableView.setContentOffset(point, animated: true)
//            tableView.scrollToRow(at: indexPath, at: position, animated: false)
//        } else {
//            tableView.scrollToRow(at: indexPath, at: position, animated: false)
//        }
    }

    func showPlaying()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard (globals.mediaPlayer.playing != nil) else {
            return
        }
        
        guard (sermonSelected?.series?.sermons?.index(of: globals.mediaPlayer.playing!) != nil) else {
            return
        }
        
        sermonSelected = globals.mediaPlayer.playing
        
        tableView.reloadData()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToSermon(self.sermonSelected, select: true, position: UITableViewScrollPosition.none)
            })
        }
        
        updateUI()
    }
    
    func deviceOrientationDidChange()
    {
        if navigationController?.visibleViewController == self {
            navigationController?.isToolbarHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.showPlaying), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        
        pageControl.isEnabled = true
        
        views = (seriesArt: self.seriesArt, seriesDescription: self.seriesDescription)
        
        if (seriesSelected == nil) { //  && (globals.seriesSelected != nil)
            // Should only happen on an iPad on initial startup, i.e. when this view initially loads, not because of a segue.
            seriesSelected = globals.seriesSelected
        }
        
        sermonSelected = seriesSelected?.sermonSelected

        if (sermonSelected == nil) && (seriesSelected != nil) && (seriesSelected == globals.mediaPlayer.playing?.series) {
            sermonSelected = globals.mediaPlayer.playing
        }

        updateUI()
        
//        println("\(globals.mediaPlayer.currentTime)")
        
    }
    
    func selectSermon(_ sermon:Sermon?)
    {
        guard (sermon != nil) else {
            return
        }
        
        guard (seriesSelected != nil) else {
            return
        }
        
        guard (seriesSelected == sermon?.series) else {
            return
        }
        
        setupPlayPauseButton()
        
        //            print("\(seriesSelected!.title)")

        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToSermon(sermon, select: true, position: UITableViewScrollPosition.none)
            })
        })
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

//        print("Series Selected: \(seriesSelected?.title) Playing: \(globals.mediaPlayer.playing?.series?.title)")
//        print("Sermon Selected: \(sermonSelected?.series?.title)")
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToSermon(self.sermonSelected, select: true, position: UITableViewScrollPosition.none)
            })
        })
        
        if globals.isLoading && (navigationController?.visibleViewController == self) && (splitViewController?.viewControllers.count == 1) {
            if let navigationController = splitViewController?.viewControllers[0] as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        removeSliderObserver()
        removePlayerObserver()
        
//        for player in players.values {
//            player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
//        }
        
        NotificationCenter.default.removeObserver(self)
        
        sliderObserver?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    func flipFromLeft(_ sender: MediaViewController)
//    {
//        //        println("tap")
//        
//        // set a transition style
//        let transitionOptions = UIViewAnimationOptions.transitionFlipFromLeft
//        
//        if let view = self.seriesArtAndDescription.subviews[0] as? UITextView {
//            view.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
//            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
//        }
//        
//        UIView.transition(with: self.seriesArtAndDescription, duration: Constants.INTERVAL.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
//            //            println("\(self.seriesArtAndDescription.subviews.count)")
//            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
//            let frontView = self.seriesArtAndDescription.subviews[0]
//            let backView = self.seriesArtAndDescription.subviews[1]
//            
//            frontView.isHidden = false
//            self.seriesArtAndDescription.bringSubview(toFront: frontView)
//            backView.isHidden = true
//            
//            if frontView == self.seriesArt {
//                self.pageControl.currentPage = 0
//            }
//            
//            if frontView == self.seriesDescription {
//                self.pageControl.currentPage = 1
//            }
//            
//            }, completion: { finished in
//                
//        })
//        
//    }
    
//    func flipFromRight(_ sender: MediaViewController)
//    {
//        //        println("tap")
//        
//        // set a transition style
//        let transitionOptions = UIViewAnimationOptions.transitionFlipFromRight
//        
//        if let view = self.seriesArtAndDescription.subviews[0] as? UITextView {
//            view.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
//            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
//        }
//        
//        UIView.transition(with: self.seriesArtAndDescription, duration: Constants.INTERVAL.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
//            //            println("\(self.seriesArtAndDescription.subviews.count)")
//            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
//            let frontView = self.seriesArtAndDescription.subviews[0]
//            let backView = self.seriesArtAndDescription.subviews[1]
//            
//            frontView.isHidden = false
//            self.seriesArtAndDescription.bringSubview(toFront: frontView)
//            backView.isHidden = true
//            
//            if frontView == self.seriesArt {
//                self.pageControl.currentPage = 0
//            }
//            
//            if frontView == self.seriesDescription {
//                self.pageControl.currentPage = 1
//            }
//            
//            }, completion: { finished in
//                
//        })
//        
//    }
    
    func flip(_ sender: MediaViewController)
    {
        //        println("tap")
        
        // set a transition style
//        var transitionOptions:UIViewAnimationOptions!
        
        let frontView = self.seriesArtAndDescription.subviews[0]
        let backView = self.seriesArtAndDescription.subviews[1]
        
//        if frontView == self.seriesArt {
//            transitionOptions = UIViewAnimationOptions.transitionFlipFromRight
//        }
//        
//        if frontView == self.seriesDescription {
//            transitionOptions = UIViewAnimationOptions.transitionFlipFromLeft
//        }

        if let view = self.seriesArtAndDescription.subviews[0] as? UITextView {
            view.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }

        frontView.isHidden = false
        self.seriesArtAndDescription.bringSubview(toFront: frontView)
        backView.isHidden = true

        if frontView == self.seriesArt {
            self.pageControl.currentPage = 0
        }
        
        if frontView == self.seriesDescription {
            self.pageControl.currentPage = 1
        }

//        UIView.transition(with: self.seriesArtAndDescription, duration: Constants.INTERVAL.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
//            //            println("\(self.seriesArtAndDescription.subviews.count)")
//            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
//            frontView.isHidden = false
//            self.seriesArtAndDescription.bringSubview(toFront: frontView)
//            backView.isHidden = true
//            
//            if frontView == self.seriesArt {
//                self.pageControl.currentPage = 0
//            }
//            
//            if frontView == self.seriesDescription {
//                self.pageControl.currentPage = 1
//            }
//
//            }, completion: { finished in
//                
//        })
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
//        if let avpc = destination as? UIViewController? {
//            if let identifier = segue.identifier {
//                switch identifier {
//                case "Show Sermon":
//                    if let myCell = sender as? MediaTableViewCell {
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

    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int
    {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
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
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.SERMON_CELL, for: indexPath) as! MediaTableViewCell
    
        // Configure the cell...
        cell.row = (indexPath as NSIndexPath).row
        cell.sermon = seriesSelected?.sermons?[(indexPath as NSIndexPath).row]
        cell.vc = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldSelectRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    fileprivate func addEndObserver() {
        if (globals.mediaPlayer.player != nil) && (globals.mediaPlayer.playing != nil) {

        }
    }
    
    fileprivate func setTimes(timeNow:Double, length:Double)
    {
        let elapsedHours = Int(timeNow / (60*60))
        let elapsedMins = Int((timeNow - (Double(elapsedHours) * 60*60)) / 60)
        let elapsedSec = Int(timeNow.truncatingRemainder(dividingBy: 60))

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
        let remainingMins = Int((timeRemaining - (Double(remainingHours) * 60*60)) / 60)
        let remainingSec = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
        var remaining:String
        
        if (remainingHours > 0) {
            remaining = "\(String(format: "%d",remainingHours)):"
        } else {
            remaining = Constants.EMPTY_STRING
        }
        
        remaining = remaining + "\(String(format: "%02d",remainingMins)):\(String(format: "%02d",remainingSec))"
        
        self.remaining.text = remaining
    }
    
    
    fileprivate func setSliderAndTimesToAudio()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard let length = globals.mediaPlayer.duration?.seconds else {
            return
        }
        
        guard length > 0 else {
            return
        }
        
        guard let currentTime = globals.mediaPlayer.playing?.currentTime else {
            return
        }
        
        guard let playingCurrentTime = Double(currentTime) else {
            return
        }
        
        guard let playerCurrentTime = globals.mediaPlayer.currentTime?.seconds else {
            return
        }
        
        guard (globals.mediaPlayer.state != nil) else {
            return
        }
        
        var progress = -1.0
        
        //            print("currentTime",selectedSermon?.currentTime)
        //            print("timeNow",timeNow)
        //            print("progress",progress)
        //            print("length",length)
        
        if (length > 0) {
            switch globals.mediaPlayer.state! {
            case .playing:
                if (playingCurrentTime >= 0) && (playerCurrentTime <= globals.mediaPlayer.duration!.seconds) {
                    progress = playerCurrentTime / length
                    
                    //                        print("playing")
                    //                        print("timeNow",timeNow)
                    //                        print("progress",progress)
                    //                        print("length",length)
                    
                    if sliding && (Int(progress*100) == Int(playingCurrentTime/length*100)) {
                        print("DONE SLIDING")
                        sliding = false
                    }
                    
                    if !sliding && globals.mediaPlayer.loaded {
                        if playerCurrentTime == 0 {
                            progress = playingCurrentTime / length
                            slider.value = Float(progress)
                            setTimes(timeNow: playingCurrentTime,length: length)
                        } else {
                            slider.value = Float(progress)
                            setTimes(timeNow: playerCurrentTime,length: length)
                        }
                    }
                    
                    elapsed.isHidden = false
                    remaining.isHidden = false
                    slider.isHidden = false
                    slider.isEnabled = true
                }
                break
                
            case .paused:
                //                    if sermonSelected?.currentTime != playerCurrentTime.description {
                progress = playingCurrentTime / length
                
                //                        print("paused")
                //                        print("timeNow",timeNow)
                //                        print("progress",progress)
                //                        print("length",length)
                
                slider.value = Float(progress)
                setTimes(timeNow: playingCurrentTime,length: length)
                
                elapsed.isHidden = false
                remaining.isHidden = false
                slider.isHidden = false
                slider.isEnabled = true
                //                    }
                break
                
            case .stopped:
                //                    if sermonSelected?.currentTime != playerCurrentTime.description {
                progress = playingCurrentTime / length
                
                //                        print("stopped")
                //                        print("timeNow",timeNow)
                //                        print("progress",progress)
                //                        print("length",length)
                
                slider.value = Float(progress)
                setTimes(timeNow: playingCurrentTime,length: length)
                
                elapsed.isHidden = false
                remaining.isHidden = false
                slider.isHidden = false
                slider.isEnabled = true
                //                    }
                break
                
            default:
                break
            }
        }
    }
    
    fileprivate func setTimeToSlider()
    {
        guard (globals.mediaPlayer.duration != nil) else {
            return
        }
        
        let length = Float(globals.mediaPlayer.duration!.seconds)
        
        let timeNow = self.slider.value * length
        
        setTimes(timeNow: Double(timeNow),length: Double(length))
    }
    
    fileprivate func setupSlider()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard (sermonSelected != nil) else {
            elapsed.isHidden = true
            remaining.isHidden = true
            slider.isHidden = true
            return
        }
        
        if (globals.mediaPlayer.playing != nil) && (globals.mediaPlayer.playing == sermonSelected) {
            if !globals.mediaPlayer.loadFailed {
                setSliderAndTimesToAudio()
            } else {
                elapsed.isHidden = true
                remaining.isHidden = true
                slider.isHidden = true
            }
        } else {
            //            print(player?.currentItem?.status.rawValue)
            if (player?.currentItem?.status == .readyToPlay) {
                if let length = player?.currentItem?.duration.seconds {
                    let timeNow = Double(sermonSelected!.currentTime!)!
                    let progress = timeNow / length
                    
                    //                        print("timeNow",timeNow)
                    //                        print("progress",progress)
                    //                        print("length",length)
                    
                    slider.value = Float(progress)
                    setTimes(timeNow: timeNow,length: length)
                    
                    elapsed.isHidden = false
                    remaining.isHidden = false
                    slider.isHidden = false
                    slider.isEnabled = false
                } else {
                    elapsed.isHidden = true
                    remaining.isHidden = true
                    slider.isHidden = true
                }
            } else {
                elapsed.isHidden = true
                remaining.isHidden = true
                slider.isHidden = true
            }
        }
    }
    
    func sliderTimer()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard (sermonSelected != nil) else {
            return
        }
        
        guard (sermonSelected == globals.mediaPlayer.playing) else {
            return
        }
        
        guard (globals.mediaPlayer.state != nil) else {
            return
        }
        
        guard (globals.mediaPlayer.startTime != nil) else {
            return
        }
        
        guard (globals.mediaPlayer.currentTime != nil) else {
            return
        }
        
        slider.isEnabled = globals.mediaPlayer.loaded
        setupPlayPauseButton()
        
        if (!globals.mediaPlayer.loaded) {
            if (!spinner.isAnimating) {
                spinner.isHidden = false
                spinner.startAnimating()
            }
        }
        
        switch globals.mediaPlayer.state! {
        case .none:
            print("none")
            break
            
        case .playing:
            print("playing")
            setSliderAndTimesToAudio()
            
            if (!globals.mediaPlayer.loaded) {
                if (!spinner.isAnimating) {
                    spinner.isHidden = false
                    spinner.startAnimating()
                }
            } else {
                if (globals.mediaPlayer.rate > 0) && (globals.mediaPlayer.currentTime!.seconds > Double((globals.mediaPlayer.startTime!))!) {
                    if spinner.isAnimating {
                        spinner.isHidden = true
                        spinner.stopAnimating()
                    }
                } else {
                    if !spinner.isAnimating {
                        spinner.isHidden = false
                        spinner.startAnimating()
                    }
                }
            }
            break
            
        case .paused:
            print("paused")
            
            if globals.mediaPlayer.loaded {
                setSliderAndTimesToAudio()
            }
            
            if globals.mediaPlayer.loaded || globals.mediaPlayer.loadFailed {
                if spinner.isAnimating {
                    spinner.stopAnimating()
                    spinner.isHidden = true
                }
            }
            break
            
        case .stopped:
            print("stopped")
            break
            
        case .seekingForward:
            print("seekingForward")
            if !spinner.isAnimating {
                spinner.isHidden = false
                spinner.startAnimating()
            }
            break
            
        case .seekingBackward:
            print("seekingBackward")
            if !spinner.isAnimating {
                spinner.isHidden = false
                spinner.startAnimating()
            }
            break
        }
    }
    
//    fileprivate func networkUnavailable(_ message:String?)
//    {
//        if (UIApplication.shared.applicationState == UIApplicationState.active) { // && (self.view.window != nil)
//            dismiss(animated: true, completion: nil)
//            
//            let alert = UIAlertController(title: Constants.Network_Error,
//                message: message,
//                preferredStyle: UIAlertControllerStyle.alert)
//            
//            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
//                
//            })
//            alert.addAction(action)
//            
//            present(alert, animated: true, completion: nil)
//        }
//    }
    
    func removeSliderObserver() {
        if globals.mediaPlayer.sliderTimerReturn != nil {
            globals.mediaPlayer.player?.removeTimeObserver(globals.mediaPlayer.sliderTimerReturn!)
            globals.mediaPlayer.sliderTimerReturn = nil
        }
    }
    
    func addSliderObserver()
    {
        removeSliderObserver()
        
        globals.mediaPlayer.sliderTimerReturn = globals.mediaPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (CMTime) in
            self?.sliderTimer()
            })
    }
    
    func playCurrentSermon(_ sermon:Sermon?)
    {
        var seekToTime:CMTime?
        
        if sermonSelected!.hasCurrentTime() {
            if sermon!.atEnd {
                NSLog("playPause globals.mediaPlayer.currentTime and globals.player.playing!.currentTime reset to 0!")
                globals.mediaPlayer.playing!.currentTime = Constants.ZERO
                seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
                sermon?.atEnd = false
            } else {
                seekToTime = CMTimeMakeWithSeconds(Double(sermon!.currentTime!)!,Constants.CMTime_Resolution)
            }
        } else {
            NSLog("playPause selectedMediaItem has NO currentTime!")
            sermon?.currentTime = Constants.ZERO
            seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
        }
        
        if seekToTime != nil {
            let loadedTimeRanges = (globals.mediaPlayer.player?.currentItem?.loadedTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime!)
            })
            
            let seekableTimeRanges = (globals.mediaPlayer.player?.currentItem?.seekableTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime!)
            })
            
            if (loadedTimeRanges != nil) || (seekableTimeRanges != nil) {
                globals.mediaPlayer.seek(to: seekToTime?.seconds)
                
                globals.mediaPlayer.play()
                
                setupPlayPauseButton()
            } else {
                playNewSermon(sermon)
            }
        }
    }
    
    fileprivate func reloadCurrentSermon(_ sermon:Sermon?) {
        //This guarantees a fresh start.
        globals.mediaPlayer.playOnLoad = true
        globals.reloadPlayer(sermon)
        addSliderObserver()
        setupPlayPauseButton()
    }
    
    fileprivate func playNewSermon(_ sermon:Sermon?)
    {
        globals.mediaPlayer.pauseIfPlaying()

        guard (sermon != nil) else {
            return
        }

        if (!spinner.isAnimating) {
            spinner.isHidden = false
            spinner.startAnimating()
        }
        
        globals.mediaPlayer.playing = sermon
        
        removeSliderObserver()
        
        //This guarantees a fresh start.
        globals.mediaPlayer.playOnLoad = true
        globals.setupPlayer(sermon)
        
        addSliderObserver()
        
        if (view.window != nil) {
            setupSlider()
            setupPlayPauseButton()
            setupActionsButton()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAtIndexPath indexPath: IndexPath) {
//        if let cell = seriesSermons.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
//
//        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        sermonSelected = seriesSelected?.sermons?[(indexPath as NSIndexPath).row]
        
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
