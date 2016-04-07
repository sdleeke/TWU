//
//  AboutViewController.swift
//  TWU
//
//  Created by Steve Leeke on 8/6/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UIViewController, MFMailComposeViewControllerDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var frontView:UIView?
    
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
        if (splitViewController == nil) {
            globals.motionEnded(motion, event: event)
        }
    }
    
    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) { //  && (self.view.window != nil)
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
                
            case Constants.Email_TWU:
                email()
                break
                
            case Constants.TWU_Website:
                openWebSite(Constants.TWU_WEBSITE)
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    @IBAction func actions(sender: UIBarButtonItem) {
        
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                //                popover.navigationItem.title = "Actions"
                
                popover.navigationController?.navigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                actionMenu.append(Constants.Email_TWU)
                actionMenu.append(Constants.TWU_Website)
                
                popover.strings = actionMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func sermonUpdateAvailable()
    {
        if (navigationController?.visibleViewController == self) {
            let alert = UIAlertView(title: "Sermon Update Available", message: "Return to the series view to update.", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (splitViewController == nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AboutViewController.sermonUpdateAvailable), name: Constants.SERMON_UPDATE_AVAILABLE_NOTIFICATION, object: nil)
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setVersion()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollView.flashScrollIndicators()

        if (UIApplication.sharedApplication().applicationIconBadgeNumber > 0) && ((splitViewController == nil) || (splitViewController!.viewControllers.count == 1)) {
            sermonUpdateAvailable()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        globals.showingAbout = false
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in

            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }
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
