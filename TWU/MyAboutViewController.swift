//
//  MyAboutViewController.swift
//  TWU
//
//  Created by Steve Leeke on 8/6/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

class MyAboutViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBAction func pageControlAction(sender: UIPageControl)
    {
        flip(self)
    }
    
    @IBOutlet weak var tpView: UIView!
    
    var frontView:UIView?
    
    @IBOutlet weak var tomPenningtonBio: UITextView! {
        didSet {
            if (splitViewController == nil) {
                let tap = UITapGestureRecognizer(target: self, action: "flip:")
                tomPenningtonBio.addGestureRecognizer(tap)
                
                let swipeRight = UISwipeGestureRecognizer(target: self, action: "flipFromLeft:")
                swipeRight.direction = UISwipeGestureRecognizerDirection.Right
                tomPenningtonBio.addGestureRecognizer(swipeRight)
                
                let swipeLeft = UISwipeGestureRecognizer(target: self, action: "flipFromRight:")
                swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
                tomPenningtonBio.addGestureRecognizer(swipeLeft)
            }
        }
    }
    
    @IBOutlet weak var tomPenningtonImage: UIImageView! {
        didSet {
            if (splitViewController == nil) {
                let tap = UITapGestureRecognizer(target: self, action: "flip:")
                tomPenningtonImage.addGestureRecognizer(tap)
                
                let swipeRight = UISwipeGestureRecognizer(target: self, action: "flipFromLeft:")
                swipeRight.direction = UISwipeGestureRecognizerDirection.Right
                tomPenningtonImage.addGestureRecognizer(swipeRight)
                
                let swipeLeft = UISwipeGestureRecognizer(target: self, action: "flipFromRight:")
                swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
                tomPenningtonImage.addGestureRecognizer(swipeLeft)
            }
        }
    }

    @IBOutlet weak var theWordUnleashedDescription: UITextView!
    
    @IBAction func give(sender: UIButton)
    {
        openWebSite(Constants.TWU_GIVING_URL)
    }
    
    @IBOutlet weak var actionsButton: UIBarButtonItem!
    
    private func setVersion()
    {
        if let dict = NSBundle.mainBundle().infoDictionary {
            if let appVersion = dict["CFBundleShortVersionString"] as? String {
                if let buildNumber = dict["CFBundleVersion"] as? String {
                    versionLabel.text = appVersion + "." + buildNumber
                    versionLabel.sizeToFit()
                }
            }
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
                    updateUserDefaultsCurrentTimeExact()
                }
                Globals.playerPaused = !Globals.playerPaused
            } else {
                
            }
        }
    }

    func flipFromLeft(sender: MyAboutViewController) {
        //        println("tap")
        
        // set a transition style
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
        
        if let view = self.tpView.subviews[0] as? UITextView {
            view.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(self.tpView, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            let frontView = self.tpView.subviews[0]
            let backView = self.tpView.subviews[1]
            
            frontView.hidden = false
            self.tpView.bringSubviewToFront(frontView)
            backView.hidden = true
            
            if frontView == self.tomPenningtonImage {
                self.pageControl.currentPage = 0
            }
            
            if frontView == self.tomPenningtonBio {
                self.pageControl.currentPage = 1
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    func flipFromRight(sender: MyAboutViewController) {
        //        println("tap")
        
        // set a transition style
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
        
        if let view = self.tpView.subviews[0] as? UITextView {
            view.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(self.tpView, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            let frontView = self.tpView.subviews[0]
            let backView = self.tpView.subviews[1]
            
            frontView.hidden = false
            self.tpView.bringSubviewToFront(frontView)
            backView.hidden = true
            
            if frontView == self.tomPenningtonImage {
                self.pageControl.currentPage = 0
            }
            
            if frontView == self.tomPenningtonBio {
                self.pageControl.currentPage = 1
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    func flip(sender: MyAboutViewController) {
        //        println("tap")
        
        // set a transition style
        var transitionOptions:UIViewAnimationOptions!
        
        let frontView = self.tpView.subviews[0]
        let backView = self.tpView.subviews[1]
        
        if frontView == self.tomPenningtonImage {
            transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
        }
        
        if frontView == self.tomPenningtonBio {
            transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
        }
        
        if let view = self.tpView.subviews[0] as? UITextView {
            view.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(self.tpView, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            frontView.hidden = false
            self.tpView.bringSubviewToFront(frontView)
            backView.hidden = true
            
            if frontView == self.tomPenningtonImage {
                self.pageControl.currentPage = 0
            }
            
            if frontView == self.tomPenningtonBio {
                self.pageControl.currentPage = 1
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) { //  && (self.view.window != nil)
            let alert = UIAlertController(title: Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func openWebSite(urlString:String)
    {
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string:urlString)!)) { // Reachability.isConnectedToNetwork() &&
            UIApplication.sharedApplication().openURL(NSURL(string:urlString)!)
        } else {
            networkUnavailable("Unable to open web site: \(urlString)")
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
    
    private func email()
    {
        let bodyString = String()
        
        //        bodyString = bodyString + addressStringHTML()
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([Constants.TWU_EMAIL])
        mailComposeViewController.setSubject(Constants.The_Word_Unleashed)
        //        mailComposeViewController.setMessageBody(bodyString, isHTML: false)
        mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    @IBAction func actions(sender: UIBarButtonItem) {
        //        println("action!")
        
        // Put up an action sheet
        
        let alert = UIAlertController(title: "",
            message: "",
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var action : UIAlertAction
        
        action = UIAlertAction(title: "E-mail TWU", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.email()
        })
        alert.addAction(action)
        
        action = UIAlertAction(title: "TWU website", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.openWebSite(Constants.TWU_WEBSITE)
        })
        alert.addAction(action)
        
        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        //on iPad this is a popover
        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        alert.popoverPresentationController?.barButtonItem = actionsButton
        
        presentViewController(alert, animated: true, completion: nil)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setVersion()
        if (splitViewController == nil) {
            tomPenningtonImage.hidden = false
            tomPenningtonBio.hidden = true
        }
        tomPenningtonBio.scrollRangeToVisible(NSMakeRange(0,0))
        theWordUnleashedDescription.scrollRangeToVisible(NSMakeRange(0,0))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (UIApplication.sharedApplication().applicationIconBadgeNumber > 0) && ((splitViewController == nil) || (splitViewController!.viewControllers.count == 1)) {
            sermonUpdateAvailable()
        }
        
        tomPenningtonBio.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated:false)
        theWordUnleashedDescription.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated:false)
        
//        tomPenningtonBio.scrollRangeToVisible(NSMakeRange(0,0))
//        theWordUnleashedDescription.scrollRangeToVisible(NSMakeRange(0,0))
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        Globals.showingAbout = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        tomPenningtonBio.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated:false)
        theWordUnleashedDescription.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated:false)
//        tomPenningtonBio.scrollRangeToVisible(NSMakeRange(0,0))
//        theWordUnleashedDescription.scrollRangeToVisible(NSMakeRange(0,0))
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
