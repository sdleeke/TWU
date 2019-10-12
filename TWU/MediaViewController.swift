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

//import Crashlytics

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

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MediaViewController : MFMessageComposeViewControllerDelegate
{
    // MARK: MFMessageComposeViewControllerDelegate

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MediaViewController : UIPopoverPresentationControllerDelegate
{
    // MARK: UIPopoverPresentationControllerDelegate
    
}

extension MediaViewController : UIActivityItemSource
{
    func share()
    {
//        let html = "\(title) by Tom Pennington from The Word Unleashed\n\n\(url.absoluteString)"
        guard let fullText = seriesSelected?.fullText else {
            return
        }

        let print = UIMarkupTextPrintFormatter(markupText: fullText.replacingOccurrences(of: "\n", with: "<br/>"))
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        
        let activityViewController = UIActivityViewController(activityItems:[self,print,fullText,seriesSelected?.coverArt?.image] , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
        
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        // present the view controller
        present(activityViewController, animated: true)
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        switch activityType {
        case UIActivity.ActivityType.mail:
            break
            
        case UIActivity.ActivityType.print:
            break
            
        default:
            break
        }

        return self.seriesSelected?.fullText
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        guard let title = self.seriesSelected?.title else {
            return "By Tom Pennington from The Word Unleashed"
        }

        let text = "\(title) by Tom Pennington from The Word Unleashed"

        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        if activityType == UIActivity.ActivityType.mail {
            return "public.text"
        } else if activityType == UIActivity.ActivityType.print {
            return "public.text"
        }
        
        return "public.plain-text"
    }
}

extension MediaViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose)
    { // , sermon:Sermon?
        dismiss(animated: true, completion: {
            switch purpose {
            case .selectingAction:
                switch strings[index] {
                case Constants.Open_Scripture:
                    self.openScripture(self.seriesSelected)
                    break
                    
                case Constants.Open_Series:
                    self.openSeriesOnWeb(self.seriesSelected)
                    break
                    
                case Constants.Open_Sermon:
                    self.openSermonOnCBC(self.sermonSelected)
                    break
                    
                case Constants.Download_All:
                    if let sermons = self.seriesSelected?.sermons {
                        for sermon in sermons {
                            sermon.audioDownload?.download(background: true)
                        }
                    }
                    break
                    
                case Constants.Cancel_All_Downloads:
                    if let sermons = self.seriesSelected?.sermons {
                        for sermon in sermons {
                            sermon.audioDownload?.cancel()
                        }
                    }
                    break
                    
                case Constants.Delete_All_Downloads:
                    if let sermons = self.seriesSelected?.sermons {
                        for sermon in sermons {
                            sermon.audioDownload?.delete()
                        }
                    }
                    break
                    
                case Constants.Share:
                    self.share()
                    break
                    
                default:
                    break
                }
                break
                
            default:
                break
            }
        })
    }
}

class ControlView : UIView
{
    deinit {
        debug(self)
    }
    
    var sliding = false
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if !sliding {
            for view in subviews {
                if view.frame.contains(point) && view.isUserInteractionEnabled {
                    return true
                }
            }
        }

        return false
    }
}

extension MediaViewController : UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.SERMON_CELL, for: indexPath) as? MediaTableViewCell ?? MediaTableViewCell()
        
        // Configure the cell...
        cell.sermon = seriesSelected?.sermons?[(indexPath as NSIndexPath).row]
        
        return cell
    }
}

extension MediaViewController : UITableViewDataSource
{
    func numberOfSections(in: UITableView) -> Int
    {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if let seriesSelected = seriesSelected {
            return seriesSelected.sermons?.count ?? -1 // seriesSelected.show
        } else {
            return 0
        }
    }
}

class MediaViewController : UIViewController
{
    deinit {
        observer?.invalidate()
        debug(self)
    }
    
//    var observerActive = false
//    var observedItem:AVPlayerItem?

    var observer: NSKeyValueObservation?
    
    private var PlayerContext = 0
    
    @IBOutlet weak var seriesArtSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var controlView: ControlView!

    @IBOutlet weak var pageControl: UIPageControl!
    {
        didSet {
            if seriesSelected?.text == nil {
                pageControl.isEnabled = false
                pageControl.isHidden = true
            }
        }
    }
    @IBAction func pageControlAction(_ sender: UIPageControl)
    {
        flip(self)
    }
    
//    override func observeValue(forKeyPath keyPath: String?,
//                               of object: Any?,
//                               change: [NSKeyValueChangeKey : Any]?,
//                               context: UnsafeMutableRawPointer?) {
//        // Only handle observations for the playerItemContext
////        guard context == &PlayerContext else {
////            super.observeValue(forKeyPath: keyPath,
////                               of: object,
////                               change: change,
////                               context: nil)
////            return
////        }
//
//        if keyPath == #keyPath(AVPlayerItem.status) {
//            guard (context == &PlayerContext) else {
//                super.observeValue(forKeyPath: keyPath,
//                                   of: object,
//                                   change: change,
//                                   context: context)
//                return
//            }
//
//            setupSliderAndTimes()
//        }
//    }

    var player:AVPlayer?

//    func removePlayerObserver()
//    {
//        // observerActive and this function would not be needed if we cache as we would assume EVERY AVPlayer in the cache has an observer => must remove them prior to dealloc.
//
//        if observerActive {
//            if observedItem != player?.currentItem {
//                print("observedItem != player?.currentItem")
//            }
//            if observedItem != nil {
//                print("MVC removeObserver: ",player?.currentItem?.observationInfo as Any)
//
//                observedItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &PlayerContext)
//                observedItem = nil
//                observerActive = false
//            } else {
//                print("observedItem == nil!")
//            }
//        }
//    }
    
//    func addPlayerObserver()
//    {
//        player?.currentItem?.addObserver(self,
//                                         forKeyPath: #keyPath(AVPlayerItem.status),
//                                         options: [.old, .new],
//                                         context: &PlayerContext)
//        observerActive = true
//        observedItem = player?.currentItem
//    }
    
    func playerURL(url: URL?)
    {
//        removePlayerObserver()
        
        guard let url = url else {
            return
        }
        
        observer?.invalidate()

        player = AVPlayer(url: url)
        
        observer = player?.currentItem?.observe(\.status, options: [.new]) { [weak self] (currentItem, change) in
            self?.observer?.invalidate()
            
            //            let status: AVPlayerItem.Status
            //
            //            guard change.newValue != nil else {
            //                return
            //            }
            //
            //            status = change.newValue!
            
            switch currentItem.status {
            case .readyToPlay:
                // Player item is ready to play.
                break
                
            case .failed:
                // Player item failed. See error.
                break
                
            case .unknown:
                // Player item is not yet ready.
                break
                
            @unknown default:
                break
            }
            
            self?.setupSliderAndTimes()
        }
        
//        addPlayerObserver()
    }
    
    var sliderTimer: Timer?

    var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = UUID().uuidString
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    var seriesSelected:Series?
    {
        didSet {
            if seriesSelected?.text == nil {
                pageControl?.isEnabled = false
                pageControl?.isHidden = true
            }
            
            operationQueue.cancelAllOperations()
            
            updateUI()
        }
    }
    var sermonSelected:Sermon?
    {
        willSet {
            
        }
        didSet {
            guard let sermonSelected = sermonSelected else { // sermonSelected != oldValue
                return
            }
            
            seriesSelected?.sermonSelected = sermonSelected
            
            if (sermonSelected != Globals.shared.mediaPlayer.playing) {
                removeSliderTimer()
                if let playingURL = sermonSelected.playingURL {
                    playerURL(url: playingURL)
                }
            } else {
//                removePlayerObserver()
                observer?.invalidate()
            }
            
            Thread.onMain { [weak self] in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAYING_PAUSED), object: nil)
            }
        }
    }
    
    @IBOutlet weak var layoutAspectRatio: NSLayoutConstraint!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBAction func playPause(_ sender: UIButton)
    {
        guard let state = Globals.shared.mediaPlayer.state, Globals.shared.mediaPlayer.playing == sermonSelected, Globals.shared.mediaPlayer.player != nil else {
            playNewSermon(sermonSelected)
            return
        }

        switch state {
        case .none:
            print("none")
            break
            
        case .playing:
            print("playing")
            Globals.shared.mediaPlayer.pause()
            
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            break
            
        case .paused:
            print("paused")
            if Globals.shared.mediaPlayer.loaded && (Globals.shared.mediaPlayer.url == sermonSelected?.playingURL) {
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
            Globals.shared.mediaPlayer.pause()
            break
            
        case .seekingBackward:
            print("seekingBackward")
            Globals.shared.mediaPlayer.pause()
            break
        }
    }

    override var canBecomeFirstResponder : Bool
    {
        return true
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
    {
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            Globals.shared.motionEnded(motion, event: event)
        }
    }

    @objc func setupPlayPauseButton()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard sermonSelected != nil else {
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = true
            return
        }

        if (sermonSelected == Globals.shared.mediaPlayer.playing) {
            playPauseButton.isEnabled = Globals.shared.mediaPlayer.loaded || Globals.shared.mediaPlayer.loadFailed
            
            if let state = Globals.shared.mediaPlayer.state {
                switch state {
                case .playing:
                    playPauseButton.setTitle(Constants.FA.PAUSE, for: UIControl.State())
                    break
                    
                case .paused:
                    playPauseButton.setTitle(Constants.FA.PLAY, for: UIControl.State())
                    break
                    
                default:
                    break
                }
            }
        } else {
            playPauseButton.isEnabled = true
            playPauseButton.setTitle(Constants.FA.PLAY, for: UIControl.State())
        }
        
        playPauseButton.isHidden = false
    }
    
    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var remaining: UILabel!
    
    @IBOutlet weak var seriesArtAndDescription: UIView!
    
    @IBOutlet weak var seriesArt: UIImageView!
    {
        willSet {
            
        }
        didSet {
            guard seriesArt != nil else {
                return
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(flip(_:)))
            seriesArt.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet weak var seriesDescription: UITextView!
    {
        willSet {
            
        }
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(flip(_:)))
            seriesDescription.addGestureRecognizer(tap)
            
            seriesDescription.text = seriesSelected?.text
            seriesDescription.alwaysBounceVertical = true
            seriesDescription.isSelectable = false
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var slider: OBSlider!
    
    fileprivate func adjustAudioAfterUserMovedSlider()
    {
        guard (Globals.shared.mediaPlayer.player != nil) else {
            return
        }
        
        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }
        
        guard let length = Globals.shared.mediaPlayer.duration?.seconds else {
            return
        }
        
        if slider.value < 0 {
            Globals.shared.mediaPlayer.pause()
            
            Globals.shared.mediaPlayer.seek(to: 0)
            
            Globals.shared.mediaPlayer.playing?.currentTime = 0.description
        } else
            
        if slider.value >= 1.0 {
            Globals.shared.mediaPlayer.pause()
            
            Globals.shared.mediaPlayer.seek(to: length)
            
            Globals.shared.mediaPlayer.playing?.currentTime = length.description
        } else
                
        if slider.value >= 0, slider.value < 1.0 {
            let seekToTime = Double(slider.value) * length
            
            Globals.shared.mediaPlayer.seek(to: seekToTime)
            
            Globals.shared.mediaPlayer.playing?.currentTime = seekToTime.description
        }
        
        switch state {
        case .playing:
            controlView.sliding = Globals.shared.reachability.isReachable // ?? false
            break
            
        default:
            controlView.sliding = false
            break
        }
        
        Globals.shared.mediaPlayer.playing?.atEnd = slider.value == 1.0
        
        Globals.shared.mediaPlayer.startTime = Globals.shared.mediaPlayer.playing?.currentTime
        
        setupSpinner()
        setupPlayPauseButton()
        addSliderTimer()
    }
    
    @IBAction func sliderTouchDown(_ sender: UISlider)
    {
        controlView.sliding = true
        removeSliderTimer()
    }
    
    @IBAction func sliderTouchUpOutside(_ sender: UISlider)
    {
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderTouchUpInside(_ sender: UISlider)
    {
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderValueChanging(_ sender: UISlider)
    {
        setTimesToSlider()
    }
    
    var views : (seriesArt: UIView?, seriesDescription: UIView?)

    var actionButton:UIBarButtonItem?
    
    fileprivate func showSendMessageErrorAlert()
    {
        Alerts.shared.alert(title: "Could Not Send a Message", message: "Your device could not send a text message.  Please check your configuration and try again.")
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
    
    fileprivate func showSendMailErrorAlert()
    {
        Alerts.shared.alert(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check your e-mail configuration and try again.")
    }
    
    fileprivate func setupBody() -> String
    {
        guard let title = seriesSelected?.title else {
            return "ERROR"
        }
        
        var bodyString = "I've enjoyed the sermon series \""
        
        bodyString = bodyString + title

        bodyString = bodyString + "\" by Tom Pennington and thought you would enjoy it as well."
        
        if let url = seriesSelected?.url {
            bodyString = bodyString + "\n\nThis series of sermons is available at "
            bodyString = bodyString + url.absoluteString
        }
        
        return bodyString
    }
    
    fileprivate func setupBodyHTML(_ series:Series?) -> String?
    {
        guard let title = series?.title else {
            return nil
        }
        
        var bodyString = "I've enjoyed the sermon series "
    
        if let url = series?.url {
            bodyString = bodyString + "<a href=\"" + url.absoluteString + "\">" + title + "</a>"
        } else {
            bodyString = bodyString + title
        }

        bodyString = bodyString + " by " + "Tom Pennington"
        bodyString = bodyString + " from <a href=\"http://www.thewordunleashed.org\">" + "The Word Unleashed" + "</a>"
        bodyString = bodyString + " and thought you would enjoy it as well."
        bodyString = bodyString + "</br>"
        
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
        guard let bodyString = setupBodyHTML(series) else {
            return
        }
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.Email_Subject)
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
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(scheme: url.absoluteString) {
                    self.alert(title: "Network Error", message: "Unable to open url: \(url)")
                }
            }
        }
    }
    
    func openSermonOnWeb(_ sermon:Sermon?)
    {
        if let url = sermon?.url {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(scheme: url.absoluteString) {
                    self.alert(title: "Network Error", message: "Unable to open url: \(url)")
                }
            }
        }
    }
    
    fileprivate func openSermonOnCBC(_ sermon:Sermon?)
    {
        guard let url = sermon?.cbcURL else {
            openSermonOnWeb(sermon)
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(scheme: url.absoluteString) {
                self.alert(title: "Network Error", message: "Unable to open url: \(url)")
            }
        } else {
            openSermonOnWeb(sermon)
        }
    }
    
    fileprivate func openScripture(_ series:Series?)
    {
        guard let scripture = series?.scripture else {
            return
        }
        
        var urlString = Constants.SCRIPTURE_URL.PREFIX + scripture + Constants.SCRIPTURE_URL.POSTFIX
        
        urlString = urlString.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.literal, range: nil)
        
        if let url = URL(string:urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(scheme: url.absoluteString) {
                    self.alert(title: "Network Error", message: "Unable to open url: \(url)")
                }
            }
        }
    }
    
//    func twitter()
//    {
//        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter){
//            var bodyString = String()
//
//            bodyString = "Great sermon series: \"\(seriesSelected?.title ?? "TITLE")\" by \(Constants.Tom_Pennington).  "
//
//            if let url = seriesSelected?.url {
//                bodyString = bodyString + url.absoluteString
//            }
//
//            let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
//            twitterSheet.setInitialText(bodyString)
//            self.present(twitterSheet, animated: true, completion: nil)
//        } else {
//            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertController.Style.alert)
//            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertAction.Style.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        }
//    }
    
//    func facebook()
//    {
//        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook){
//            var bodyString = String()
//
//            if let title = seriesSelected?.title, let url = seriesSelected?.url {
//                bodyString = "Great sermon series: \"\(title)\" by \(Constants.Tom_Pennington).  " + url.absoluteString
//            }
//
//            //So the user can paste the initialText into the post dialog/view
//            //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
//            UIPasteboard.general.string = bodyString
//
//            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
//            facebookSheet.setInitialText(bodyString)
//            self.present(facebookSheet, animated: true, completion: nil)
//        } else {
//            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertController.Style.alert)
//            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertAction.Style.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        }
//    }

    @objc func actions()
    {
        guard let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController else {
            return
        }
        
        guard let popover = navigationController.viewControllers[0] as? PopoverTableViewController else {
            return
        }
        
        navigationController.modalPresentationStyle = .popover

        navigationController.popoverPresentationController?.permittedArrowDirections = .up
        navigationController.popoverPresentationController?.delegate = self
        
        navigationController.popoverPresentationController?.barButtonItem = actionButton
        
        popover.navigationController?.isNavigationBarHidden = true
        
        popover.delegate = self
        popover.purpose = .selectingAction
        
        var actionMenu = [String]()
        
        if let isEmpty = seriesSelected?.scripture?.isEmpty, !isEmpty, seriesSelected?.scripture != Constants.Selected_Scriptures {
            actionMenu.append(Constants.Open_Scripture)
        }

        actionMenu.append(Constants.Open_Series)
        
        if sermonSelected != nil {
            actionMenu.append(Constants.Open_Sermon)
        }
        
        if let sermons = seriesSelected?.sermons {
            var sermonsToDownload = 0
            var sermonsDownloading = 0
            var sermonsDownloaded = 0
            
            for sermon in sermons {
                if let state = sermon.audioDownload?.state {
                    switch state {
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
        
        popover.showIndex = false
        popover.showSectionHeaders = false
        
        present(navigationController, animated: true, completion: nil)
    }

    @objc func updateView()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        seriesSelected = Globals.shared.series.selected
        sermonSelected = seriesSelected?.sermonSelected
        
        tableView.reloadData()

        // Without this background/main dispatching there isn't time to scroll correctly after a reload.
        // For UI
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMain { [weak self] in
                self?.scrollToSermon(self?.sermonSelected, select: true, position: UITableView.ScrollPosition.none)
            }
        })

        updateUI()
    }
    
    @objc func clearView()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
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
        
        // Can't do this or selecting a row doesn't work reliably.
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard isViewLoaded else {
            return
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.scrollToSermon(self.sermonSelected, select: true, position: UITableView.ScrollPosition.none)
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            if let view = self.seriesArtAndDescription.subviews[1] as? UITextView {
                view.scrollRangeToVisible(NSMakeRange(0, 0))
            }

            if self.navigationController?.visibleViewController == self {
                self.navigationController?.isToolbarHidden = true
            }
            
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
    
    fileprivate func setupActionsButton()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard (seriesSelected != nil) else {
            self.navigationItem.rightBarButtonItem = nil
            actionButton = nil
            return
        }
        
        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actions))
        
        if let font = UIFont(name: Constants.FA.name, size: Constants.FA.FONT_SIZE) {
            actionButton?.setTitleTextAttributes([NSAttributedString.Key.font : font])
        }

        self.navigationItem.rightBarButtonItem = actionButton
    }
    
    func setupPageControl()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        if (seriesSelected?.text == nil) || (seriesArt.image == nil) {
            pageControl.isEnabled = false
            pageControl.isHidden = true
        } else {
            pageControl.isEnabled = true
            pageControl.isHidden = false
        }
    }
    
    func setImage(_ image:UIImage?)
    {
        guard let image = image else {
            return
        }
        
        Thread.onMain { [weak self] in
            let ratio = image.size.width / image.size.height
            
            self?.layoutAspectRatio = self?.layoutAspectRatio.setMultiplier(multiplier: ratio)

            self?.seriesArt.image = image
            
            self?.spinner.isHidden = true
            self?.spinner.stopAnimating()
        }
    }
    
    fileprivate func setupArtAndDescription()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard let seriesSelected = seriesSelected else {
            //iPad only
            logo.isHidden = false
            
            seriesArt.isHidden = true
            seriesDescription.isHidden = true
            
            seriesArtAndDescription.isHidden = true
            pageControl.isHidden = true
            
            return
        }
        
        seriesArtAndDescription.isHidden = false
        
        logo.isHidden = true
        pageControl.isHidden = (seriesSelected.text == nil) || (seriesArt.image == nil)

        // Attrbuted
        var seriesString : String? // NSMutableAttributedString
        
        if let text = seriesSelected.text?.replacingOccurrences(of: " ???", with: ",").replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: "—", with: "&mdash;").replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n\n", with: "\n").replacingOccurrences(of: "\n\n", with: "\n").replacingOccurrences(of: "\n", with: "<br><br>").replacingOccurrences(of: "’", with: "&rsquo;").replacingOccurrences(of: "“", with: "&ldquo;").replacingOccurrences(of: "”", with: "&rdquo;").replacingOccurrences(of: "?۪s", with: "'s").replacingOccurrences(of: "…", with: "...") {
            seriesString = text.html2String
        }

//        if let text = seriesSelected.text?.replacingOccurrences(of: " ???", with: ",").replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: "—", with: "&mdash;").replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n\n", with: "\n").replacingOccurrences(of: "\n\n", with: "\n").replacingOccurrences(of: "\n", with: "<br><br>").replacingOccurrences(of: "’", with: "&rsquo;").replacingOccurrences(of: "“", with: "&ldquo;").replacingOccurrences(of: "”", with: "&rdquo;").replacingOccurrences(of: "?۪s", with: "'s").replacingOccurrences(of: "…", with: "...") {
//            if  let data = text.data(using: String.Encoding.utf16, allowLossyConversion: false),
//                let attributedString = try? NSMutableAttributedString(data: data,
//                                                                      // DocumentAttributeKey.documentType
//                                                                      options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html],
//                                                                      documentAttributes: nil) {
//                attributedString.addAttributes([NSAttributedString.Key.font:UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)],
//                                               range: NSMakeRange(0, attributedString.length))
//
//                seriesAttrbutedString = attributedString
//            }
//        }

        // Attributed
        var sermonStrings = [String:String]() // [String:NSAttributedString]() // Mutable
        
        if let sermons = seriesSelected.sermons {
            for sermon in sermons {
                if let text = sermon.text?.replacingOccurrences(of: " ???", with: ",").replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: "—", with: "&mdash;").replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n\n", with: "\n").replacingOccurrences(of: "\n\n", with: "\n").replacingOccurrences(of: "\n", with: "<br><br>").replacingOccurrences(of: "’", with: "&rsquo;").replacingOccurrences(of: "“", with: "&ldquo;").replacingOccurrences(of: "”", with: "&rdquo;").replacingOccurrences(of: "?۪s", with: "'s").replacingOccurrences(of: "…", with: "...") {
                    if let partNumber = sermon.partNumber {
                        sermonStrings[partNumber] = text.html2String
                    }

//                    if  let data = text.data(using: String.Encoding.utf16, allowLossyConversion: false),
//                        let attributedString = try? NSMutableAttributedString(data: data,
//                                                                              // DocumentAttributeKey.documentType
//                            options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html],
//                            documentAttributes: nil) {
//                        attributedString.addAttributes([NSAttributedString.Key.font:UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)],
//                                                       range: NSMakeRange(0, attributedString.length))
//
//                        if let partNumber = sermon.partNumber {
//                            sermonAttributedStrings[partNumber] = attributedString
//                        }
//                    }
//                    if  let data = text.data(using: String.Encoding.utf16, allowLossyConversion: false),
//                        let attributedString = try? NSMutableAttributedString(data: data,
//                                                                              // DocumentAttributeKey.documentType
//                            options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html],
//                            documentAttributes: nil) {
//                        attributedString.addAttributes([NSAttributedString.Key.font:UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)],
//                                                       range: NSMakeRange(0, attributedString.length))
//
//                        if let partNumber = sermon.partNumber {
//                            sermonAttributedStrings[partNumber] = attributedString
//                        }
//                    }
                }
            }
        }

        // Attributed
        if let seriesString = seriesString {
            if sermonStrings.count > 0 {
                var description = seriesString
                
                for sermonStringKey in sermonStrings.keys.sorted(by: { (first,second) -> Bool in
                    return Int(first) < Int(second)
                }) {
                    if let sermonString = sermonStrings[sermonStringKey] {
                        description.append("\n")
                        description.append("\n")
                        description.append("Part \(sermonStringKey) of \(sermonStrings.keys.count)")
                        description.append("\n")
                        description.append(sermonString)
                    }
                }
                
//                let description = NSMutableAttributedString(attributedString: seriesAttrbutedString)
//
//                for sermonAttributedStringKey in sermonAttributedStrings.keys.sorted(by: { (first,second) -> Bool in
//                    return Int(first) < Int(second)
//                }) {
//                    if let sermonAttributedString = sermonAttributedStrings[sermonAttributedStringKey] {
//                        description.append(NSMutableAttributedString(string: "\n"))
//                        description.append(NSMutableAttributedString(string: "\n"))
//                        description.append(NSAttributedString(string: "Part \(sermonAttributedStringKey) of \(sermonAttributedStrings.keys.count)", attributes:Constants.Fonts.Attributes.bold))
//                        description.append(NSMutableAttributedString(string: "\n"))
//                        description.append(sermonAttributedString)
//                    }
//                }

//                for sermonAttributedStringKey in sermonAttributedStrings.keys.sorted(by: { (first,second) -> Bool in
//                    return Int(first) < Int(second)
//                }) {
//                    if let sermonAttributedString = sermonAttributedStrings[sermonAttributedStringKey] {
//                        description.append(NSMutableAttributedString(string: "\n"))
//                        description.append(NSMutableAttributedString(string: "\n"))
//                        description.append(NSAttributedString(string: "Part \(sermonAttributedStringKey) of \(sermonAttributedStrings.keys.count)", attributes:Constants.Fonts.Attributes.bold))
//                        description.append(NSMutableAttributedString(string: "\n"))
//                        description.append(sermonAttributedString)
//                    }
//                }
                
//                if #available(iOS 13.0, *) {
//                    // Need to be able to set the default system font color so dark mode will work.
////                    description.addAttributes([NSAttributedString.Key.foregroundColor:UIColor.white],
////                                                   range: NSMakeRange(0, description.length))
//                    description.addAttributes([NSAttributedString.Key.backgroundColor:UIColor.systemBackground],
//                                                   range: NSMakeRange(0, description.length))
//                } else {
//                    // Fallback on earlier versions
//                }
                
                seriesDescription.text = description.replacingOccurrences(of: "\n\n\n", with: "\n\n").replacingOccurrences(of: "\n\n\n", with: "\n\n")
                
//                seriesDescription.attributedText = description
            } else {
                seriesDescription.text = seriesString
//                seriesDescription.attributedText = seriesAttrbutedString
            }
        } else {
            if let name = seriesSelected.name {
                seriesDescription.attributedText = NSAttributedString(string: "Description for \(name) not found.", attributes:Constants.Fonts.Attributes.bold)
            } else {
                seriesDescription.attributedText = NSAttributedString(string: "Description not found.", attributes:Constants.Fonts.Attributes.bold)
            }
        }

//        if let image = seriesSelected.coverArt?.cache {
//            Thread.onMain { [weak self] in
//                if self.seriesSelected == seriesSelected {
//                    self.seriesArt.image = image
//                    self.setupPageControl()
//                }
//            }
//        } else {
            seriesArtSpinner.isHidden = false
            seriesArtSpinner.startAnimating()

            operationQueue.addOperation {
                seriesSelected.coverArt?.load(success:{ [weak self] (image:UIImage) in
                    Thread.onMain { [weak self] in
                        if self?.seriesSelected == seriesSelected {
                            self?.seriesArtSpinner.stopAnimating()
                            self?.seriesArtSpinner.isHidden = true
                            self?.setImage(image)
//                            self?.seriesArt.image = image
                            self?.setupPageControl()
                        }
                    }
                }, failure: { [weak self] in
                    Thread.onMain { [weak self] in
                        if self?.seriesSelected == seriesSelected {
                            self?.seriesArtSpinner.stopAnimating()
                            self?.seriesArtSpinner.isHidden = true
                            // .replacingOccurrences(of: "square", with: "").replacingOccurrences(of: "_Md", with: "_md")
                            self?.setImage(seriesSelected.coverArt?.url?.absoluteString.replacingOccurrences(of: "-square", with: "_square").url?.image ?? UIImage(named: "twu_logo_circle_r"))
//                            self?.seriesArt.image = UIImage(named: "twu_logo_circle_r")
                            self?.setupPageControl()
                        }
                    }
                })
            }
//        }

        seriesArt.isHidden = pageControl.currentPage == 1
        seriesDescription.isHidden = pageControl.currentPage == 0
    }
    
    fileprivate func setupTitle()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        self.navigationItem.title = seriesSelected?.title
    }
    
    func setupSpinner()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard (sermonSelected != nil) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        guard (sermonSelected == Globals.shared.mediaPlayer.playing) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        if !Globals.shared.mediaPlayer.loaded && !Globals.shared.mediaPlayer.loadFailed {
            if !spinner.isAnimating {
                spinner.isHidden = false
                spinner.startAnimating()
            }
        } else {
            if Globals.shared.mediaPlayer.isPlaying {
                if  !controlView.sliding,
                    let currentTime = Globals.shared.mediaPlayer.currentTime?.seconds,!currentTime.isNaN,!currentTime.isInfinite,
                    let playingCurrentTime = Globals.shared.mediaPlayer.playing?.currentTime, let playing = Double(playingCurrentTime),!playing.isNaN,!playing.isInfinite,
                    currentTime > playing {
                    spinner.isHidden = true
                    spinner.stopAnimating()
                } else {
                    spinner.isHidden = false
                    spinner.startAnimating()
                }
            }

            if Globals.shared.mediaPlayer.isPaused {
                if spinner.isAnimating {
                    spinner.isHidden = true
                    spinner.stopAnimating()
                }
            }
        }
    }

    @objc func updateUI()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        //These are being added here for the case when this view is opened and the sermon selected is playing already
        if self.navigationController?.visibleViewController == self {
            self.navigationController?.isToolbarHidden = true
        }
        
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
        
        addSliderTimer()
        
        setupActionsButton()
        setupArtAndDescription()
        
        setupTitle()
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()
    }

    func scrollToSermon(_ sermon:Sermon?,select:Bool,position:UITableView.ScrollPosition)
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard let sermon = sermon else {
            return
        }
        
        var indexPath = IndexPath(row: 0, section: 0)
        
        if (seriesSelected?.sermons?.count > 1) {
            if let sermonIndex = seriesSelected?.sermons?.firstIndex(of: sermon) {
                indexPath = IndexPath(row: sermonIndex, section: 0)
            }
        }
        
        if (select) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: position)
        }
        
        tableView.scrollToRow(at: indexPath, at: position, animated: false)
    }

    @objc func showPlaying()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard let playing = Globals.shared.mediaPlayer.playing else {
            removeSliderTimer()
            
            if let url = sermonSelected?.playingURL {
                playerURL(url: url)
            }

            updateUI()
            return
        }
        
        guard (sermonSelected?.series?.sermons?.firstIndex(of: playing) != nil) else {
            return
        }
        
        sermonSelected = playing
        
        // Without this background/main dispatching there isn't time to scroll correctly after a reload.
        // For UI
        DispatchQueue.global(qos: .background).async {
            Thread.onMain { [weak self] in
                self?.scrollToSermon(self?.sermonSelected, select: true, position: UITableView.ScrollPosition.none)
            }
        }
        
        updateUI()
    }
    
    @objc func readyToPlay()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard Globals.shared.mediaPlayer.loaded else {
            return
        }
        
        guard (sermonSelected != nil) else {
            return
        }
        
        guard (sermonSelected == Globals.shared.mediaPlayer.playing) else {
            return
        }
        
        if Globals.shared.mediaPlayer.playOnLoad {
            if let atEnd = Globals.shared.mediaPlayer.playing?.atEnd, atEnd {
                Globals.shared.mediaPlayer.seek(to: 0)
                Globals.shared.mediaPlayer.playing?.atEnd = false
            }
            Globals.shared.mediaPlayer.playOnLoad = false
            
            // Purely for the delay?
            // For UI
            DispatchQueue.global(qos: .background).async(execute: {
                Thread.onMain { [weak self] in
                    Globals.shared.mediaPlayer.play()
                }
            })
        }
        
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()
    }
    
    @objc func doneSeeking()
    {
        controlView?.sliding = false
        print("DONE SEEKING")
    }
    
    @objc func deviceOrientationDidChange()
    {
        if navigationController?.visibleViewController == self {
            navigationController?.isToolbarHidden = true
        }
    }
    
    @objc func failedToLoad()
    {
        guard (sermonSelected != nil) else {
            return
        }
        
        if (sermonSelected == Globals.shared.mediaPlayer.playing) {
            updateUI()
        }
    }
    
    @objc func failedToPlay()
    {
        guard (sermonSelected != nil) else {
            return
        }
        
        if (sermonSelected == Globals.shared.mediaPlayer.playing) {
            updateUI()
        }
    }
    
    @objc func reachableTransition()
    {
        // This just triggers the didSet as if we had just selected it all over again.
        // Which sets up the AVPlayer to show length and position for mediaItems that aren't loaded in the media Player.
        if let sermonSelected = sermonSelected {
            self.sermonSelected = sermonSelected
        }
        
        updateUI()
    }

    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(doneSeeking), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showPlaying), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(failedToLoad), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_LOAD), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(readyToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        addNotifications()
        
        views = (seriesArt: self.seriesArt, seriesDescription: self.seriesDescription)
        
        if (seriesSelected == nil) {
            // Should only happen on an iPad on initial startup, i.e. when this view initially loads, not because of a segue.
            seriesSelected = Globals.shared.series.selected
        }
        
        sermonSelected = seriesSelected?.sermonSelected

        if (sermonSelected == nil) && (seriesSelected != nil) && (seriesSelected == Globals.shared.mediaPlayer.playing?.series) {
            sermonSelected = Globals.shared.mediaPlayer.playing
        }

        updateUI()
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
        
        // Without this background/main dispatching there isn't time to scroll correctly after a reload.
        // For UI
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMain { [weak self] in
                self?.scrollToSermon(sermon, select: true, position: UITableView.ScrollPosition.none)
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        // Without this background/main dispatching there isn't time to scroll correctly after a reload.
        // For UI
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMain { [weak self] in
                self?.scrollToSermon(self?.sermonSelected, select: true, position: UITableView.ScrollPosition.none)
            }
        })
        
        if Globals.shared.isLoading && (navigationController?.visibleViewController == self) && (splitViewController?.viewControllers.count == 1) {
            if let navigationController = splitViewController?.viewControllers[0] as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
        }
        
//        Crashlytics.sharedInstance().crash()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        removeSliderTimer()
//        removePlayerObserver()
        observer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
        
        sliderTimer?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func flip(_ sender: MediaViewController)
    {
        guard seriesSelected?.text != nil else {
            return
        }
        
        guard seriesArt.image != nil else {
            return
        }
        
        let frontView = self.seriesArtAndDescription.subviews[0]
        let backView = self.seriesArtAndDescription.subviews[1]
        
        if let view = self.seriesArtAndDescription.subviews[0] as? UITextView {
            view.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        }

        frontView.isHidden = false
        self.seriesArtAndDescription.bringSubviewToFront(frontView)
        backView.isHidden = true

        if frontView == self.seriesArt {
            self.pageControl.currentPage = 0
        }
        
        if frontView == self.seriesDescription {
            self.pageControl.currentPage = 1
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = destination as? UINavigationController, let visibleViewController = navCon.visibleViewController {
            destination = visibleViewController
        }
    }
    
    fileprivate func addEndObserver()
    {
        if (Globals.shared.mediaPlayer.player != nil) && (Globals.shared.mediaPlayer.playing != nil) {

        }
    }
    
    fileprivate func setTimes(timeNow:Double, length:Double)
    {
        guard Thread.isMainThread else {
            Globals.shared.userAlert(title: "Not Main Thread", message: "MediaViewController:setTimes")
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard !timeNow.isNaN,!timeNow.isInfinite else {
            return
        }
        
        guard !length.isNaN,!length.isInfinite else {
            return
        }

//        let elapsedHours = max(Int(timeNow / (60*60)),0)
//        let elapsedMins = max(Int((timeNow - (Double(elapsedHours) * 60*60)) / 60),0)
//        let elapsedSec = max(Int(timeNow.truncatingRemainder(dividingBy: 60)),0)
//
//        var elapsed:String
//        
//        if (elapsedHours > 0) {
//            elapsed = "\(String(format: "%d",elapsedHours)):"
//        } else {
//            elapsed = Constants.EMPTY_STRING
//        }
//        
//        elapsed = elapsed + "\(String(format: "%02d",elapsedMins)):\(String(format: "%02d",elapsedSec))"
        
        self.elapsed.text = timeNow.secondsToHMS
        
        let timeRemaining = max(length - timeNow,0)
        
//        let remainingHours = max(Int(timeRemaining / (60*60)),0)
//        let remainingMins = max(Int((timeRemaining - (Double(remainingHours) * 60*60)) / 60),0)
//        let remainingSec = max(Int(timeRemaining.truncatingRemainder(dividingBy: 60)),0)
//
//        var remaining:String
//
//        if (remainingHours > 0) {
//            remaining = "\(String(format: "%d",remainingHours)):"
//        } else {
//            remaining = Constants.EMPTY_STRING
//        }
//
//        remaining = remaining + "\(String(format: "%02d",remainingMins)):\(String(format: "%02d",remainingSec))"
        
        self.remaining.text = timeRemaining.secondsToHMS
    }
    
    
    fileprivate func setSliderAndTimesToAudio()
    {
        guard Thread.isMainThread else {
            return
        }

        guard isViewLoaded else {
            return
        }
        
        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }
        
        guard let length = Globals.shared.mediaPlayer.duration?.seconds else {
            return
        }
        
        guard length > 0 else {
            return
        }

        guard let playerCurrentTime = Globals.shared.mediaPlayer.currentTime?.seconds, playerCurrentTime >= 0, playerCurrentTime <= length else {
            return
        }
        
        guard let currentTime = Globals.shared.mediaPlayer.playing?.currentTime, let playingCurrentTime = Double(currentTime), !playingCurrentTime.isNaN, !playingCurrentTime.isInfinite, playingCurrentTime >= 0, Int(playingCurrentTime) <= Int(length) else {
            return
        }

        var progress = -1.0
        
        switch state {
        case .playing:
            progress = playerCurrentTime / length
            
            if !controlView.sliding {
                if Globals.shared.mediaPlayer.loaded {
                    if playerCurrentTime == 0 {
                        progress = playingCurrentTime / length
                        slider.value = Float(progress)
                        setTimes(timeNow: playingCurrentTime,length: length)
                    } else {
                        slider.value = Float(progress)
                        setTimes(timeNow: playerCurrentTime,length: length)
                    }
                } else {
                    print("not loaded")
                }
            } else {

            }
            
            elapsed.isHidden = false
            remaining.isHidden = false
            slider.isHidden = false
            slider.isEnabled = true
            break
            
        case .paused:
            progress = playingCurrentTime / length

            if !controlView.sliding {
                slider.value = Float(progress)
            } else {

            }

            setTimes(timeNow: playingCurrentTime,length: length)
            
            elapsed.isHidden = false
            remaining.isHidden = false
            slider.isHidden = false
            slider.isEnabled = true
            break
            
        case .stopped:
            progress = playingCurrentTime / length

            if !controlView.sliding {
                slider.value = Float(progress)
            } else {

            }

            setTimes(timeNow: playingCurrentTime,length: length)
            
            elapsed.isHidden = false
            remaining.isHidden = false
            slider.isHidden = false
            slider.isEnabled = true
            break
            
        default:
            elapsed.isHidden = true
            remaining.isHidden = true
            slider.isHidden = true
            slider.isEnabled = false
            break
        }
    }
    
    fileprivate func setTimesToSlider()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard let length = Globals.shared.mediaPlayer.duration?.seconds else {
            return
        }
        
        guard !self.slider.value.isNaN,!self.slider.value.isInfinite else {
            return
        }
        
        guard self.slider.value >= 0, self.slider.value <= 1.0 else {
            return
        }
        
        let timeNow = self.slider.value * Float(length)
        
        setTimes(timeNow: Double(timeNow),length: Double(length))
    }
    
    fileprivate func setupSliderAndTimes()
    {
        guard Thread.isMainThread else {
            Globals.shared.userAlert(title: "Not Main Thread", message: "MediaViewController:setupSliderAndTimes")
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard (sermonSelected != nil) else {
            elapsed.isHidden = true
            remaining.isHidden = true
            slider.isHidden = true
            return
        }
        
        if (Globals.shared.mediaPlayer.state != .stopped) && (Globals.shared.mediaPlayer.playing == sermonSelected) {
            if !Globals.shared.mediaPlayer.loadFailed {
                setSliderAndTimesToAudio()
            } else {
                elapsed.isHidden = true
                remaining.isHidden = true
                slider.isHidden = true
            }
        } else {
            if (player?.currentItem?.status == .readyToPlay) {
                if  let length = player?.currentItem?.duration.seconds, !length.isNaN, !length.isInfinite,
                    let currentTime = sermonSelected?.currentTime,
                    let timeNow = Double(currentTime), !timeNow.isNaN, !timeNow.isInfinite {
                    let progress = timeNow / length
                    
                    if !controlView.sliding {
                        slider.value = Float(progress)
                    } else {

                    }
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
    
    @objc func updateSlider()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard isViewLoaded else {
            return
        }
        
        guard (sermonSelected != nil) else {
            return
        }
        
        guard (sermonSelected == Globals.shared.mediaPlayer.playing) else {
            return
        }
        
        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }
        
        guard (Globals.shared.mediaPlayer.startTime != nil) else {
            return
        }
        
        guard (Globals.shared.mediaPlayer.currentTime != nil) else {
            return
        }
        
        slider.isEnabled = Globals.shared.mediaPlayer.loaded
        setupPlayPauseButton()
        setupSpinner()
        
        func showState(_ state:String)
        {
            //            print("State: ", state)
        }
        
        switch state {
        case .none:
            showState("none")
            break
            
        case .playing:
            showState("playing")
            
            setupSpinner()

            if Globals.shared.mediaPlayer.loaded {
                setSliderAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .paused:
            showState("paused")
            
            setupSpinner()
            
            if Globals.shared.mediaPlayer.loaded {
                setSliderAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .stopped:
            showState("stopped")
            break
            
        case .seekingForward:
            showState("seekingForward")
            break
            
        case .seekingBackward:
            showState("seekingBackward")
            break
        }
    }
    
    func removeSliderTimer()
    {
        sliderTimer?.invalidate()
        sliderTimer = nil
        
//        if let sliderTimerReturn = Globals.shared.mediaPlayer.sliderTimerReturn {
//            Globals.shared.mediaPlayer.player?.removeTimeObserver(sliderTimerReturn)
//            Globals.shared.mediaPlayer.sliderTimerReturn = nil
//        }
    }
    
    func addSliderTimer()
    {
        removeSliderTimer()
        
        Thread.onMain { [weak self] in
            self?.sliderTimer = Timer.scheduledTimer(timeInterval: Constants.INTERVALS.TIMERS.SLIDER, target: self, selector: #selector(self?.updateSlider), userInfo: nil, repeats: true)
        }
    }
    
    func playCurrentSermon(_ sermon:Sermon?)
    {
        guard let sermon = sermon else {
            return
        }
        
        var seekToTime:CMTime?
        
        if let hasCurrentTime = sermonSelected?.hasCurrentTime, hasCurrentTime {
            if sermon.atEnd {
                NSLog("playPause Globals.shared.mediaPlayer.currentTime and Globals.shared.player.playing!.currentTime reset to 0!")
                Globals.shared.mediaPlayer.playing?.currentTime = Constants.ZERO
                seekToTime = CMTimeMakeWithSeconds(0,preferredTimescale: Constants.CMTime_Resolution)
                sermon.atEnd = false
            } else {
                if let currentTime = sermon.currentTime, let seconds = Double(currentTime), !seconds.isNaN, !seconds.isInfinite {
                    seekToTime = CMTimeMakeWithSeconds(seconds,preferredTimescale: Constants.CMTime_Resolution)
                }
            }
        } else {
            NSLog("playPause selectedMediaItem has NO currentTime!")
            sermon.currentTime = Constants.ZERO
            seekToTime = CMTimeMakeWithSeconds(0,preferredTimescale: Constants.CMTime_Resolution)
        }
        
        if let seekToTime = seekToTime {
            let loadedTimeRanges = (Globals.shared.mediaPlayer.player?.currentItem?.loadedTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime)
            })
            
            let seekableTimeRanges = (Globals.shared.mediaPlayer.player?.currentItem?.seekableTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime)
            })
            
            if (loadedTimeRanges != nil) || (seekableTimeRanges != nil) {
                Globals.shared.mediaPlayer.seek(to: seekToTime.seconds)
                
                Globals.shared.mediaPlayer.play()
                
                setupPlayPauseButton()
            } else {
                playNewSermon(sermon)
            }
        }
    }
    
    fileprivate func reloadCurrentSermon(_ sermon:Sermon?)
    {
        //This guarantees a fresh start.
        Globals.shared.mediaPlayer.playOnLoad = true
        Globals.shared.mediaPlayer.reload(sermon?.url)
        addSliderTimer()
        setupPlayPauseButton()
    }
    
    fileprivate func playNewSermon(_ sermon:Sermon?)
    {
        Globals.shared.mediaPlayer.pauseIfPlaying()

        guard let sermon = sermon else {
            return
        }

        guard Globals.shared.reachability.isReachable || (sermon.audioDownload?.isDownloaded == true) else { // let reachability = Globals.shared.reachability, 
            self.alert(title: "Audio Not Available", message: "Please check your network connection and try again.")
            return
        }
        
        if !spinner.isAnimating {
            spinner.isHidden = false
            spinner.startAnimating()
        }
        
        Globals.shared.mediaPlayer.playing = sermon
        
        removeSliderTimer()
        
        //This guarantees a fresh start.
        Globals.shared.mediaPlayer.playOnLoad = true
        Globals.shared.mediaPlayer.setup(sermon)
        
        addSliderTimer()
        
        if (view.window != nil) {
            setupSliderAndTimes()
            setupPlayPauseButton()
            setupActionsButton()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
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
